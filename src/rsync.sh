#!/bin/bash

if [ $# -lt 2 ]; then 
    echo "Usage: $0 <source-location> <dest-location>"
    echo
    echo "Copies over SSH from source to dest."
    echo
    echo "Example:"
    echo " $ rsync.sh user@host:~/file /local/dir"
    exit 1
fi

src=$1
dest=$2

rsync -r -h --partial --progress --rsh=ssh $src $dest
