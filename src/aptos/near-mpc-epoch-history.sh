#!/usr/bin/env bash
# mpc-epoch-history.sh
#
# Prints the on-chain reshare/refresh history of a NEAR MPC contract:
# every finalized epoch, when it went live, and how its participant set
# and threshold differ from the previous epoch ("REFRESH" if no change,
# "MEMBERSHIP CHANGE" otherwise).
#
# Source of truth: NearBlocks transaction index for `vote_new_parameters`
# (proposals) and `vote_reshared` (completions). Pre-contract-migration
# epochs (e.g. those created by `new_single_ecdsa_key_from_legacy` or by
# `propose_update`) won't appear here — they don't go through these
# methods. Only `vote_reshared`-finalized epochs are listed.
#
# Usage:
#   ./mpc-epoch-history.sh                       # mainnet v1.signer
#   CONTRACT=v1.signer-prod.testnet ./mpc-epoch-history.sh
#   API=https://api-testnet.nearblocks.io/v1 CONTRACT=… ./mpc-epoch-history.sh
#   PAGES=10 ./mpc-epoch-history.sh              # fetch more history (25/page)
#   NEARBLOCKS_API_KEY=… ./mpc-epoch-history.sh  # use a paid key (no rate limit)
#
# Rate limits (NearBlocks free tier as of 2026):
#   6 calls/minute, 333/day, 10k/month.
# This script paces requests at ~11s apart by default to stay under 6/min.
# Each method-fetch needs ~8-12 pages to cover the full mainnet history,
# so a full run takes ~4 minutes and uses ~20 of your daily 333 calls.
# Provide NEARBLOCKS_API_KEY to skip the pacing.
#
# Requires: curl, python3 (no jq needed).

set -euo pipefail

CONTRACT="${CONTRACT:-v1.signer}"
API="${API:-https://api.nearblocks.io/v1}"
PAGES="${PAGES:-15}"

for cmd in curl python3; do
  command -v "$cmd" >/dev/null || { echo "missing required tool: $cmd" >&2; exit 1; }
done

CONTRACT="$CONTRACT" API="$API" PAGES="$PAGES" \
  NEARBLOCKS_API_KEY="${NEARBLOCKS_API_KEY:-}" python3 <<'PY'
import os, sys, json, urllib.request, urllib.error, datetime

contract = os.environ["CONTRACT"]
api      = os.environ["API"].rstrip("/")
pages    = int(os.environ["PAGES"])
api_key  = os.environ.get("NEARBLOCKS_API_KEY", "").strip()
# NearBlocks rate-limits at 6 req/min (one every 10s) on both anon and keyed
# requests; an API key just lifts the daily/monthly quota, not the per-minute
# burst. Pace at 12s to leave headroom for clock jitter / network latency.
# Override via PACE_S env var (e.g. 0.5 if you have a higher-tier key).
PACE_S   = float(os.environ.get("PACE_S", "12.0"))

def fetch(method, stop_when_seen=None):
    """
    Fetch txns calling `method` on `contract` from NearBlocks, newest-first.
    `stop_when_seen(txn) -> bool` is called for each txn; pagination stops as
    soon as it returns True for a txn (so we don't have to download all of
    history just to find the latest few epochs).
    """
    import time
    txns = []
    for page in range(1, pages + 1):
        # Pace requests *before* each call (incl. the first to be safe across
        # back-to-back fetch() invocations).
        if txns or page > 1:
            time.sleep(PACE_S)
        url = f"{api}/account/{contract}/txns?method={method}&per_page=25&page={page}&order=desc"
        headers = {"User-Agent": "mpc-epoch-history/1"}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"
        d = None
        for attempt in range(6):
            try:
                req = urllib.request.Request(url, headers=headers)
                with urllib.request.urlopen(req, timeout=15) as r:
                    d = json.load(r)
                break
            except urllib.error.HTTPError as e:
                if e.code == 429 and attempt < 5:
                    # Honor server-side Retry-After if present, else exp-backoff.
                    ra = e.headers.get("Retry-After") if e.headers else None
                    wait = int(ra) if (ra and ra.isdigit()) else min(2 ** attempt, 30)
                    sys.stderr.write(f"info: {method} page {page} rate-limited, waiting {wait}s\n")
                    time.sleep(wait)
                    continue
                sys.stderr.write(f"warn: {method} page {page}: HTTP {e.code}\n")
                break
            except Exception as e:
                sys.stderr.write(f"warn: {method} page {page}: {e}\n")
                break
        if d is None:
            break
        batch = d.get("txns") or []
        if not batch:
            break
        txns.extend(batch)
        if stop_when_seen is not None and any(stop_when_seen(t) for t in batch):
            break
        if len(batch) < 25:
            break
    return txns

# Hard cap: stop paginating once we've seen this many distinct epochs.
# 25 covers the entire current history of v1.signer (epochs 3..6) with margin.
MAX_EPOCHS = int(os.environ.get("MAX_EPOCHS", "25"))

def epoch_of(txn, method):
    args = next((a["args"] for a in (txn.get("actions") or [])
                 if a.get("method") == method), None)
    if not args:
        return None
    try:
        o = json.loads(args)
    except json.JSONDecodeError:
        return None
    if method == "vote_new_parameters":
        return o.get("prospective_epoch_id")
    if method == "vote_reshared":
        return o.get("key_event_id", {}).get("epoch_id")
    return None

# Pagination stop predicate: each method tracks epochs it has seen and stops
# once the count exceeds MAX_EPOCHS. (We accumulate via a closure.)
def make_stop(method):
    seen = set()
    def f(txn):
        e = epoch_of(txn, method)
        if e is not None:
            seen.add(e)
        return len(seen) > MAX_EPOCHS
    return f

proposals = fetch("vote_new_parameters", stop_when_seen=make_stop("vote_new_parameters"))
finals    = fetch("vote_reshared",       stop_when_seen=make_stop("vote_reshared"))

# Group proposals by (epoch, threshold, sorted-participants).
# Each group is a "candidate set"; the one a threshold of voters agreed on
# is what the contract actually transitioned to (we cross-check that against
# vote_reshared events to identify the winner).
groups = {}  # (epoch, thr, tuple(accts)) -> list[(ts_ns, tx_hash, voter)]
for t in proposals:
    args = next((a["args"] for a in (t.get("actions") or [])
                 if a.get("method") == "vote_new_parameters"), None)
    if not args:
        continue
    try:
        o = json.loads(args)
        epoch = o["prospective_epoch_id"]
        prop  = o["proposal"]
        accts = tuple(sorted(p[0] for p in prop["participants"]["participants"]))
        thr   = prop["threshold"]
    except (KeyError, TypeError, json.JSONDecodeError):
        continue
    sig = (epoch, thr, accts)
    groups.setdefault(sig, []).append((
        int(t["block_timestamp"]),
        t["transaction_hash"],
        t.get("predecessor_account_id", "?"),
    ))

# Identify finalized epochs and their finalization time (latest vote_reshared
# across all domains belonging to that epoch). vote_reshared has many votes
# per epoch (n_participants * n_domains * n_attempts), so this dataset is
# large and may be partial under rate limits.
finalized_ts = {}  # epoch -> latest ts_ns
for t in finals:
    args = next((a["args"] for a in (t.get("actions") or [])
                 if a.get("method") == "vote_reshared"), None)
    if not args:
        continue
    try:
        e = json.loads(args)["key_event_id"]["epoch_id"]
    except (KeyError, TypeError, json.JSONDecodeError):
        continue
    ts = int(t["block_timestamp"])
    finalized_ts[e] = max(finalized_ts.get(e, 0), ts)

# For each *winning* proposal per epoch, pick the candidate set with the most
# distinct voters — that's the one that crossed threshold and won. We use
# vote_new_parameters (a small, complete dataset) to drive epoch identification
# rather than vote_reshared (which is much larger and often gets rate-limited).
winners = {}  # epoch -> {"thr","accts","voters","prop_ts","fin_ts"}
for (epoch, thr, accts), votes in groups.items():
    voters = {v[2] for v in votes}
    cur = winners.get(epoch)
    if cur is None or len(voters) > cur["voters"]:
        winners[epoch] = dict(
            thr=thr,
            accts=list(accts),
            voters=len(voters),
            prop_ts=max(v[0] for v in votes),
            fin_ts=finalized_ts.get(epoch),  # may be None if rate-limited
        )

if not winners:
    sys.stderr.write(
        f"No vote_new_parameters proposals found via NearBlocks for contract "
        f"{contract!r}. Try increasing PAGES (currently {pages}).\n"
    )
    sys.exit(2)

now = datetime.datetime.now(datetime.UTC)
def fmt(ts_ns):
    return datetime.datetime.fromtimestamp(ts_ns / 1e9, datetime.UTC)

print(f"contract: {contract}")
print(f"epochs visible: {len(winners)}  (winning vote_new_parameters proposals)\n")

prev = None  # (set, threshold)
for epoch in sorted(winners):
    w = winners[epoch]
    cur_set = set(w["accts"])

    # Prefer the actual finalization timestamp; fall back to the latest
    # proposal vote (which is when threshold was first crossed -- typically
    # the actual finalization happens within minutes to hours).
    if w["fin_ts"]:
        when    = fmt(w["fin_ts"])
        when_lbl = "finalized"
    else:
        when    = fmt(w["prop_ts"])
        when_lbl = "proposed*"  # finalized data missing (likely rate-limited)
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

    print(f"epoch {epoch:>2}   {kind:<18}   {when_lbl} {when:%Y-%m-%d %H:%M UTC}   ({age}d ago)")
    print(f"             threshold={w['thr']}   n={len(cur_set)}   distinct_voters_observed={w['voters']}")
    print(f"             delta: {delta}")
    print(f"             participants: {sorted(cur_set)}")
    print()

    prev = (cur_set, w["thr"])

if any(w["fin_ts"] is None for w in winners.values()):
    print("* finalization timestamp from vote_reshared was not fetched for some")
    print("  epochs (NearBlocks rate-limited).  Re-run later or with NEARBLOCKS_API_KEY")
    print("  set as a `apiKey` query param to get exact finalization times.")
PY
