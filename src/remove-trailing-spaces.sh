#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: `basename $0` <file1> [<file2> ...]"
    exit 1
fi

cmd=gsed

! which $cmd &>/dev/null && cmd=sed

$cmd -i 's/[ \t]*$//' $@ 

