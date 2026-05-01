#!/usr/bin/env python3
"""
near-mpc-epoch-history

Print the on-chain reshare/refresh history of a NEAR MPC contract: every
finalized epoch, when it went live, and how its participant set and threshold
differ from the previous epoch ("REFRESH" if no change, "MEMBERSHIP CHANGE"
otherwise).

Source of truth: NearBlocks transaction index for `vote_new_parameters`
(proposals) and `vote_reshared` (completions). Pre-contract-migration epochs
(e.g. those created by `new_single_ecdsa_key_from_legacy` or by
`propose_update`) won't appear here -- they don't go through these methods.

Rate limits (NearBlocks free + key tiers as of 2026):
    6 calls/minute, 333/day, 10k/month.
An API key only lifts the daily/monthly quota, not the per-minute burst.
The default 12s pacing keeps a single run under the 6/min limit; a full
mainnet run takes ~4 minutes and uses ~20 of your daily 333 calls.

Examples:
    ./near-mpc-epoch-history.py
    ./near-mpc-epoch-history.py --contract v1.signer-prod.testnet \\
        --api https://api-testnet.nearblocks.io/v1
    NEARBLOCKS_API_KEY=xxx ./near-mpc-epoch-history.py --quiet
"""

import argparse
import datetime
import json
import os
import sys
import time
import urllib.error
import urllib.request


# ---------------------------------------------------------------------------
# verbose / quiet logging
# ---------------------------------------------------------------------------

QUIET = False


def log(msg):
    """Progress message -> stderr unless --quiet."""
    if not QUIET:
        sys.stderr.write(f"  ... {msg}\n")
        sys.stderr.flush()


def warn(msg):
    """Always-shown warning -> stderr."""
    sys.stderr.write(f"  !!! {msg}\n")
    sys.stderr.flush()


# ---------------------------------------------------------------------------
# NearBlocks client
# ---------------------------------------------------------------------------


def fetch_method(api, contract, method, *,
                 pages, api_key, pace_s, max_epochs, epoch_extractor):
    """
    Fetch txns calling `method` on `contract` from NearBlocks, newest-first.

    Stops early once we've observed `max_epochs` distinct epoch IDs
    (extracted via `epoch_extractor`), so we don't pull all of history just
    to find the latest few epochs.
    """
    log(f"fetching {method} from NearBlocks (max {pages} pages of 25, paced at {pace_s}s) ...")
    txns = []
    seen_epochs = set()
    auth_msg = "with API key" if api_key else "anonymous (free tier)"
    log(f"  auth: {auth_msg}")

    for page in range(1, pages + 1):
        if page > 1:
            log(f"  sleeping {pace_s:.1f}s to respect rate limit ...")
            time.sleep(pace_s)

        url = (f"{api}/account/{contract}/txns"
               f"?method={method}&per_page=25&page={page}&order=desc")
        headers = {"User-Agent": "near-mpc-epoch-history/1"}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"

        log(f"  GET page {page} ...")
        d = _get_with_retry(url, headers, label=f"{method} page {page}")
        if d is None:
            warn(f"  giving up on {method} after page {page}; output may be partial")
            break

        batch = d.get("txns") or []
        log(f"  page {page}: {len(batch)} tx returned (cumulative {len(txns) + len(batch)})")
        if not batch:
            break
        txns.extend(batch)

        new_epochs = {epoch_extractor(t) for t in batch} - {None} - seen_epochs
        if new_epochs:
            log(f"  page {page}: discovered new epoch(s) {sorted(new_epochs)}")
        seen_epochs |= new_epochs

        if len(seen_epochs) > max_epochs:
            log(f"  reached max-epochs cap ({max_epochs}); stopping pagination")
            break
        if len(batch) < 25:
            log(f"  page {page} not full -> reached end of {method} history")
            break

    log(f"done with {method}: {len(txns)} txns, "
        f"{len(seen_epochs)} epoch(s) seen ({sorted(seen_epochs)})")
    return txns


def _get_with_retry(url, headers, *, label, max_attempts=6):
    """GET url, retry on 429 with exponential backoff (or Retry-After)."""
    for attempt in range(max_attempts):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=15) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < max_attempts - 1:
                ra = e.headers.get("Retry-After") if e.headers else None
                wait = int(ra) if (ra and ra.isdigit()) else min(2 ** attempt, 30)
                log(f"  {label}: rate-limited (429), waiting {wait}s "
                    f"(attempt {attempt + 1}/{max_attempts})")
                time.sleep(wait)
                continue
            warn(f"{label}: HTTP {e.code}")
            return None
        except Exception as e:
            warn(f"{label}: {e}")
            return None


# ---------------------------------------------------------------------------
# epoch extraction
# ---------------------------------------------------------------------------


def args_for_method(txn, method):
    """Pull the JSON args of the first action calling `method`."""
    actions = txn.get("actions") or []
    raw = next((a.get("args") for a in actions if a.get("method") == method), None)
    if not raw:
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def epoch_of_proposal(txn):
    o = args_for_method(txn, "vote_new_parameters")
    return o.get("prospective_epoch_id") if o else None


def epoch_of_finalization(txn):
    o = args_for_method(txn, "vote_reshared")
    return (o or {}).get("key_event_id", {}).get("epoch_id")


# ---------------------------------------------------------------------------
# analysis
# ---------------------------------------------------------------------------


def analyze(proposals, finals):
    """
    Return:
        winners: epoch -> {thr, accts (sorted list), voters, prop_ts, fin_ts}
    """
    log("grouping vote_new_parameters proposals by (epoch, threshold, participants) ...")
    groups = {}  # (epoch, thr, accts-tuple) -> list[(ts_ns, tx_hash, voter)]
    for t in proposals:
        o = args_for_method(t, "vote_new_parameters")
        if not o:
            continue
        try:
            epoch = o["prospective_epoch_id"]
            prop  = o["proposal"]
            accts = tuple(sorted(p[0] for p in prop["participants"]["participants"]))
            thr   = prop["threshold"]
        except (KeyError, TypeError):
            continue
        sig = (epoch, thr, accts)
        groups.setdefault(sig, []).append((
            int(t["block_timestamp"]),
            t["transaction_hash"],
            t.get("predecessor_account_id", "?"),
        ))
    log(f"  found {len(groups)} distinct (epoch, threshold, participants) candidate(s)")

    log("scanning vote_reshared events for finalization timestamps ...")
    finalized_ts = {}  # epoch -> latest ts_ns observed
    for t in finals:
        e = epoch_of_finalization(t)
        if e is None:
            continue
        ts = int(t["block_timestamp"])
        finalized_ts[e] = max(finalized_ts.get(e, 0), ts)
    log(f"  observed finalization for epoch(s): {sorted(finalized_ts.keys())}")

    log("picking the winning candidate per epoch (most distinct voters) ...")
    winners = {}
    for (epoch, thr, accts), votes in groups.items():
        voters = {v[2] for v in votes}
        cur = winners.get(epoch)
        if cur is None or len(voters) > cur["voters"]:
            winners[epoch] = dict(
                thr=thr,
                accts=list(accts),
                voters=len(voters),
                prop_ts=max(v[0] for v in votes),
                fin_ts=finalized_ts.get(epoch),
            )
    log(f"  winners selected for epoch(s): {sorted(winners.keys())}")
    return winners


# ---------------------------------------------------------------------------
# rendering
# ---------------------------------------------------------------------------


def render(contract, winners):
    if not winners:
        warn(f"No vote_new_parameters proposals found for {contract!r}. "
             f"Try --pages or check the contract account.")
        return 2

    now = datetime.datetime.now(datetime.UTC)
    def fmt(ts_ns):
        return datetime.datetime.fromtimestamp(ts_ns / 1e9, datetime.UTC)

    print(f"contract: {contract}")
    print(f"epochs visible: {len(winners)}  "
          f"(winning vote_new_parameters proposals)\n")

    prev = None  # (set-of-accts, threshold)
    for epoch in sorted(winners):
        w = winners[epoch]
        cur_set = set(w["accts"])

        if w["fin_ts"]:
            when, when_lbl = fmt(w["fin_ts"]), "finalized"
        else:
            when, when_lbl = fmt(w["prop_ts"]), "proposed*"
        age = (now - when).days

        if prev is None:
            kind  = "INITIAL"
            delta = "earliest visible epoch -- no baseline to diff against"
        else:
            added   = sorted(cur_set - prev[0])
            removed = sorted(prev[0] - cur_set)
            thr_chg = w["thr"] != prev[1]
            if not added and not removed and not thr_chg:
                kind  = "REFRESH"
                delta = "no membership or threshold change (pure key refresh)"
            else:
                kind = "MEMBERSHIP CHANGE"
                parts = []
                if added:   parts.append("+ " + ", ".join(added))
                if removed: parts.append("- " + ", ".join(removed))
                if thr_chg: parts.append(f"threshold {prev[1]} -> {w['thr']}")
                delta = "; ".join(parts)

        print(f"epoch {epoch:>2}   {kind:<18}   "
              f"{when_lbl} {when:%Y-%m-%d %H:%M UTC}   ({age}d ago)")
        print(f"             threshold={w['thr']}   n={len(cur_set)}   "
              f"distinct_voters_observed={w['voters']}")
        print(f"             delta: {delta}")
        print(f"             participants: {sorted(cur_set)}")
        print()
        prev = (cur_set, w["thr"])

    if any(w["fin_ts"] is None for w in winners.values()):
        print("* finalization timestamp from vote_reshared was not fetched "
              "for some epochs")
        print("  (NearBlocks rate-limited or paged-out). Re-run with a higher")
        print("  --pages or NEARBLOCKS_API_KEY for exact finalization times.")
    return 0


# ---------------------------------------------------------------------------
# entry point
# ---------------------------------------------------------------------------


def parse_args(argv):
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--contract", default=os.environ.get("CONTRACT", "v1.signer"),
                   help="NEAR account hosting the MPC contract (default: v1.signer)")
    p.add_argument("--api", default=os.environ.get("API", "https://api.nearblocks.io/v1"),
                   help="NearBlocks API base URL")
    p.add_argument("--pages", type=int, default=int(os.environ.get("PAGES", "15")),
                   help="Max pages (25 tx each) per method (default: 15)")
    p.add_argument("--max-epochs", type=int,
                   default=int(os.environ.get("MAX_EPOCHS", "25")),
                   help="Stop paginating once this many distinct epochs are seen "
                        "(default: 25)")
    p.add_argument("--api-key", default=os.environ.get("NEARBLOCKS_API_KEY", ""),
                   help="NearBlocks API key (or set NEARBLOCKS_API_KEY env var)")
    p.add_argument("--pace-s", type=float, default=float(os.environ.get("PACE_S", "12.0")),
                   help="Seconds between requests; default 12.0 stays under "
                        "NearBlocks' 6/min cap with margin for jitter")
    p.add_argument("-q", "--quiet", action="store_true",
                   help="Suppress progress messages")
    return p.parse_args(argv)


def main(argv=None):
    global QUIET
    args = parse_args(argv)
    QUIET = args.quiet

    log(f"contract: {args.contract}")
    log(f"api endpoint: {args.api}")
    log(f"pacing: {args.pace_s}s between requests "
        f"(NearBlocks free/standard tier is 6 req/min)")
    if not args.api_key:
        log("no API key -- using free anonymous tier (333 calls/day shared)")

    proposals = fetch_method(
        args.api, args.contract, "vote_new_parameters",
        pages=args.pages, api_key=args.api_key.strip(),
        pace_s=args.pace_s, max_epochs=args.max_epochs,
        epoch_extractor=epoch_of_proposal,
    )
    finals = fetch_method(
        args.api, args.contract, "vote_reshared",
        pages=args.pages, api_key=args.api_key.strip(),
        pace_s=args.pace_s, max_epochs=args.max_epochs,
        epoch_extractor=epoch_of_finalization,
    )

    winners = analyze(proposals, finals)
    return render(args.contract, winners)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.stderr.write("\ninterrupted\n")
        sys.exit(130)
