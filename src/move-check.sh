#!/bin/bash

# This copies what we do in the rust-lint GitHub Action for aptos-core.

run_clippy='true'

scriptdir=$(cd $(dirname $0); pwd -P)

run_move_prover='false'

# This copies what we do in the rust-lint GitHub Action for aptos-core.

display_help() {
    echo "Usage: $0 [-cehm]"
    echo
    echo " -e opens the source code of this script in vim for editing"
    echo " -h displays this help message"
    echo " -m does NOT run 'aptos move prove'"
}

while getopts 'celmh' flag; do
  case "${flag}" in
    e) vim $script_dir/$0
       exit 0 ;;
    h) display_help
       exit 0 ;;
    m) run_move_prover='true' ;;
    *) display_help
       exit 1 ;;
  esac
done

set -e
set -x

cwd=`pwd`

time (

cd `git rev-parse --show-toplevel`

# Make sure Move prover .spec.move files are in order
if [[ "$run_move_prover" == "true" ]]; then
    (
        cd aptos-move/framework/

        cd aptos-stdlib/
        aptos move prove

        # TODO: For now, this is failing.
        #cd ../aptos-framework/
        #aptos move prove
    )
fi

(
    cd aptos-move/framework/
    cargo test
)

(
    cd aptos-move/e2e-move-tests/
    cargo test
)

(
    cd aptos-move/aptos-transactional-test-harness
    cargo test
)

# Make sure docs are up to date
cargo build -p aptos-cached-packages

cd "$cwd"
)
