#!/bin/bash
scriptdir=$(readlink -f $(dirname $0))

list=
while [ $# -gt 0 ]; do
    list="$list\"$1\" "
    shift;
done

echo "pic-decide.sh $list" >>exec.sh
