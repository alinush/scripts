#!/bin/bash

if [ "$1" == "-h" -o "$1" == "--help" ]; then
    echo "Usage: `basename $0` [dir1 dir2 dir3 ...]"
    echo
    echo "If no directories are specified, the current working directory will be used."
    echo
    exit
fi

[ $# -eq 0 ] && set -- "."

which jhead >/dev/null || { echo "ERROR: You need to have 'jhead' installed"; exit 1; }

OIFS="$IFS"
IFS=$'\n'

while [ $# -gt 0 ]; do
    dir="$1"
    for file in `find "$dir" -type f | grep -v Thumbs.db`; do
        ispic=0
        nodate=0

        jhead "$file" >/dev/null 2>/dev/null && ispic=1
        date=`jhead "$file" | grep "Date/Time" | cut -d':' -f 2-`
        [ -z "$date" ] && { nodate=1 ; date="*Date not set"; }

        if [ $ispic -eq 0 ]; then
            continue
        fi

        echo "$date - $file"
    done | sort -r | uniq
    shift
done
IFS="$OIFS"
