#!/bin/bash

# This copies what we do in the rust-lint GitHub Action for aptos-core.

run_clippy='true'
run_cargo_sort='true'

scriptdir=$(cd $(dirname $0); pwd -P)

# This copies what we do in the rust-lint GitHub Action for aptos-core.

display_help() {
    echo "Usage: $0 [-ceh]"
    echo
    echo " -c does NOT run 'cargo xclippy'"
    echo " -e opens the source code of this script in vim for editing"
    echo " -h displays this help message"
}

while getopts 'cehs' flag; do
  case "${flag}" in
    c) run_clippy='false' ;;
    e) vim $script_dir/$0
       exit 0 ;;
    h) display_help
       exit 0 ;;
    s) run_cargo_sort='false' ;;
    *) display_help
       exit 1 ;;
  esac
done

set -e
set -x

cwd=`pwd`

time (

cd `git rev-parse --show-toplevel`

# Format (cheap)
cargo +nightly fmt

# Cargo.toml sorting (I think)
if [[ "$run_cargo_sort" == "true" ]]; then
    cargo sort --grouped --workspace
fi

# Clippy (expensive)
if [[ "$run_clippy" == "true" ]]; then
    cargo xclippy
fi;

cd "$cwd"
)
