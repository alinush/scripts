#!/usr/bin/env bash
set -euo pipefail

# Strip doc/ and head.mrb changes from the last K commits via rebase.
# WARNING: This rewrites history. Will require --force push afterward.

K=19

BASE=$(git rev-parse HEAD~$K)

# Mark all K commits as 'edit' in a non-interactive rebase
GIT_SEQUENCE_EDITOR="sed -i '' 's/^pick /edit /'" git rebase -i "$BASE"

while true; do
    # Get files changed in this commit that match doc/ or head.mrb patterns
    CHANGED_DOCS=$(git diff-tree --no-commit-id -r --name-only HEAD \
        | grep -E 'aptos-move/framework/.*/doc/|head\.mrb' || true)

    if [ -n "$CHANGED_DOCS" ]; then
        echo "Stripping doc/head.mrb changes from $(git rev-parse --short HEAD): $(git log -1 --format='%s')"
        while IFS= read -r f; do
            if git cat-file -e HEAD~1:"$f" 2>/dev/null; then
                # File existed in parent — restore parent version
                git checkout HEAD~1 -- "$f"
            else
                # File was added in this commit — remove it
                git rm -f "$f"
            fi
        done <<< "$CHANGED_DOCS"
        git commit --amend --no-edit
    fi

    # Continue the rebase; handle conflicts if our changes caused them
    if ! git rebase --continue 2>&1; then
        # Check if rebase is still in progress (conflict) vs finished
        if [ -d "$(git rev-parse --git-dir)/rebase-merge" ] || [ -d "$(git rev-parse --git-dir)/rebase-apply" ]; then
            # Conflict — resolve doc files by accepting the current (rewritten) version
            CONFLICT_DOCS=$(git diff --name-only --diff-filter=U \
                | grep -E 'aptos-move/framework/.*/doc/|head\.mrb' || true)
            if [ -n "$CONFLICT_DOCS" ]; then
                echo "Resolving doc conflicts..."
                while IFS= read -r f; do
                    git checkout --theirs -- "$f"
                    git add "$f"
                done <<< "$CONFLICT_DOCS"
                # If all conflicts are resolved, continue
                REMAINING=$(git diff --name-only --diff-filter=U || true)
                if [ -z "$REMAINING" ]; then
                    git rebase --continue 2>&1 || true
                    continue
                fi
            fi
            echo "ERROR: Non-doc merge conflict. Resolve manually, then run: git rebase --continue"
            exit 1
        else
            # Rebase finished
            break
        fi
    fi
done

echo ""
echo "Done! Verifying no doc/head.mrb changes remain..."
echo ""

# Verification (use here-string to avoid subshell variable loss)
FAIL=0
while read -r hash; do
    docs=$(git diff-tree --no-commit-id -r --name-only "$hash" \
        | grep -E 'aptos-move/framework/.*/doc/|head\.mrb' || true)
    if [ -n "$docs" ]; then
        echo "FAIL: $hash still has doc changes: $docs"
        FAIL=1
    fi
done < <(git log --format="%h" -$K)

if [ "$FAIL" -eq 0 ]; then
    echo "All clean — no doc/head.mrb changes in the last $K commits."
else
    echo "Some commits still have doc changes (see above)."
    exit 1
fi

echo "Note: Diff the two branches to make sure no accidental changes were made!"
echo "  git diff <backup-branch> <rebased-branch> -- . ':!aptos-move/framework/*/doc/' ':!**/head.mrb'"
