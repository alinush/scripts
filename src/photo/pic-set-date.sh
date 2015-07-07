#!/bin/bash

which jhead >/dev/null || { echo "ERROR: You need to have 'jhead' installed"; exit 1; }
which exiftool >/dev/null || { echo "ERROR: You need to have 'exiftool' installed"; exit 1; }

if [ $# -ne 2 ]; then
    echo "Replaces all EXIF dates in picture files that match the"
    echo "specified pattern with the specified date"
    echo
    echo "Usage: `basename $0` <pattern> <ts-in-yyyy:mm:dd-hh:mm:ss>"
    echo
    exit 1
fi

pattern=${1:-"2002"}
newdate=${2:-"2003:07:28-00:00:00"}

if ! echo "$newdate" | grep "^[0-9]\{4\}:[0-9]\{2\}:[0-9]\{2\}-[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}$"; then
    echo "ERROR: Date must be in YYYY:MM:DD-hh:mm:ss format"
    echo
    echo "Example: 2003:07:28-13:47:59 (that's 1:37pm and 59s)"
    echo
    exit 1
fi

OIFS="$IFS"
IFS=$'\n'
for file in `find -type f | grep -v Thumbs.db`; do
    ispic=0
    nodate=0

    jhead $file 2>&1 >/dev/null && ispic=1
    date=`jhead "$file" 2>/dev/null | grep "Date/Time" | cut -d':' -f 2-`
    [ -z "$date" ] && nodate=1
    matched=`echo $date | grep "$pattern"`

    if [ $ispic -eq 0 ]; then
        continue
    fi

    if [ -n "$matched" -o $nodate -eq 1 ]; then
        echo "Replacing '$date' date with '$newdate' in file $file"
        #jhead -ts"$newdate" "$file" -- does not work when EXIF field is missing
        exiftool -overwrite_original -DateTimeOriginal="$newdate" "$file"
    else
        echo "Date '$date' did not match '$pattern' pattern in file $file"
    fi
done
IFS="$OIFS"
