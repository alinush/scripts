#!/bin/bash

# This copies what we do in the rust-lint GitHub Action for aptos-core.

set -e
set -x

runclippy='true'

while getopts 'cl' flag; do
  case "${flag}" in
    c) runclippy='false' ;;
    *) echo 'Invalid flag'
       exit 1 ;;
  esac
done


cwd=`pwd`

cd `git rev-parse --show-toplevel`

if [[ "$runclippy" == "true" ]]; then
    cargo xclippy
fi;

cargo fmt

cargo sort --grouped --workspace

cd "$cwd"
