#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Replaces all EXIF dates in picture files that match the"
    echo "specified pattern with the specified date"
    echo
    echo "Usage: `basename $0` <pattern> <ts-in-yyyy:mm:dd-hh:mm:ss>"
    echo
    exit 1
fi

pattern=${1:-"2002"}
newdate=${2:-"2003:07:28-00:00-00"}

OIFS="$IFS"
IFS=$'\n'
for file in `find -type f | grep -v Thumbs.db`; do
    date=`jhead "$file" | grep "Date/Time" | cut -d':' -f 2-`
    matched=`echo $date | grep "$pattern"`
    if [ -n "$matched" ]; then
        echo "Replacing '$date' date with '$newdate' in file $file"
        jhead -ts"$newdate" "$file"
    else
        echo "Date '$date' did not match '$pattern' pattern in file $file"
    fi
done
IFS="$OIFS"
