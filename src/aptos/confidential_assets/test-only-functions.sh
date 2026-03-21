#!/bin/bash
# Lists all #[test_only] functions and #[test] functions remaining in sources/confidential_asset/.
# Excludes .spec.move files, friend declarations, and use statements.

SCRIPT_DIR="."

echo "=== #[test_only] functions ==="
grep -rn '#\[test_only\]' "$SCRIPT_DIR" --include='*.move' -A4 \
    | grep -v '\.spec\.' \
    | grep 'fun ' \
    | awk -F " fun " '{print $2}' \
    | cut -f1 -d'('

echo ""
echo "=== #[test] functions ==="
grep -rn '#\[test\]$' "$SCRIPT_DIR" --include='*.move' -A4 \
    | grep -v '\.spec\.' \
    | grep 'fun ' \
    | awk -F " fun " '{print $2}' \
    | cut -f1 -d'('

echo ""
echo "=== #[test_only] structs ==="
grep -rn '#\[test_only\]' "$SCRIPT_DIR" --include='*.move' -A1 \
    | grep -v '\.spec\.' \
    | grep 'struct' \
    | awk -F " struct " '{print $2}' \
    | cut -f1 -d' '

echo ""
echo "=== #[test_only] consts ==="
grep -rn '#\[test_only\]' "$SCRIPT_DIR" --include='*.move' -A1 \
    | grep -v '\.spec\.' \
    | grep 'const' \
    | awk -F " const " '{print $2}' \
    | cut -f1 -d':'
