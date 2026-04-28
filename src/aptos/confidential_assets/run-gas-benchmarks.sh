#!/bin/bash

out_file=`mktemp -t confidential-asset-gas-benches`

cd $HOME/repos/aptos-core/aptos-move/e2e-move-tests && cargo test --features move-harness-with-test-only -- bench_gas --nocapture 2>&1 | tee -a $out_file
