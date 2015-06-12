#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Must give at least one input file."
    exit 1
fi

list=
while [ $# -gt 1 ]; do
    shotwell "$1";
    list=`echo "$1";echo "$list";`
    shift;
done

shotwell "$1"

read -p "Are you sure you want to delete the following file(s)?
$list

Please enter 'y' or 'n': " ANS

set -e

if [ "$ANS" == "y" ]; then
    while read file; do
        dir=`dirname "$file"`
        dest="$HOME/deleted/$dir"
        mkdir -p "$dest"
        echo "Moved file '$file' to '$dest' dir"
        mv "$file" "$dest/"
    done <<< "$list"
else
    echo "NOT deleted."
fi
