#!/bin/bash

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [-r] [directory]"
    exit
fi

recursive=0
if [ "$1" = "-r" ]; then
    recursive=1
    shift
fi

vDir=${1:-`pwd`}
vDir=$(cd "$vDir"; pwd -P)

find_cmd=
if [ $recursive -eq 0 ]; then
    echo "Listing extensions in this directory only: $vDir"
    find_cmd="find $vDir -type f -maxdepth 1"
else
    echo "Listing extensions in this directory and its subdirs: $vDir"
    find_cmd="find $vDir -type f"
fi
echo

exts=`$find_cmd | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort -u`

max_size=0
for e in $exts; do
    size=${#e}
    if [ $size -gt $max_size ]; then
        max_size=$size
    fi
done
max_size=$(($max_size + 1))

for e in $exts; do
    c=`$find_cmd -name "*.$e" | wc -l`
    c=`echo $c`

    printf "%-${max_size}s -> $c file" ".$e"
    if [ $c -gt 1 ]; then
        echo "(s)"
    else
        echo
    fi
done
