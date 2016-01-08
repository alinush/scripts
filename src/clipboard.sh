#!/bin/bash

set -e

#scriptdir=$(readlink -f $(dirname $0))
scriptdir=$(cd $(dirname $0); pwd -P)

vConfFile=$scriptdir/clipboard.conf

function clearClipboard {
    if which xclip >/dev/null; then
        echo -n | xclip -sel clip
    elif which pbcopy >/dev/null; then
        echo -n | pbcopy
    else
        echo "ERROR: Neither xclip nor pbcopy are available."
        exit 1
    fi
}

function setClipboard {
    if which xclip >/dev/null; then
        echo -n "$1" | xclip -sel clip
    elif which pbcopy >/dev/null; then
        echo -n "$1" | pbcopy
    else
        echo "ERROR: Neither xclip nor pbcopy are available."
        exit 1
    fi
}

if [ -z "$1" ]; then
    echo "Usage: $(basename $0) <grep-pattern>"
    exit 1
fi

if [ "$1" == "-c" -o "$1" == "--clear" ]; then
    clearClipboard
    echo "Cleared clipboard!"
    exit 0
fi

if [ ! -f "$vConfFile" ]; then
    echo "ERROR: No config file at '$vConfFile'"
    exit 1
fi

# NOTE: Differences in output between Ubuntu and OS X. Must use
# second echo to clear off whitespace
vNumLines=`wc -l $vConfFile`
vNumLines=`echo $vNumLines | cut -f 1 -d' '`
#echo "vNumLines: $vNumLines"

if [ $vNumLines -ne 1 ]; then
    echo "ERROR: '$vConfFile' can only have one line"
    exit 1
fi

vFile=`cat $vConfFile`
vFile=`echo $vFile`

if [ ! -f "$vFile" ]; then
    echo "ERROR: The '$vFile' file to grep in does not exist"
    exit 1
fi

echo "Copying from $vFile..."

vResult=`grep "^$1" "$vFile" || :`
# NOTE: Differences in output between Ubuntu and OS X. Must use
# second echo to clear off whitespace
vNumLines=`echo "$vResult" | wc -l`
vNumLines=`echo $vNumLines | cut -f 1 -d' '`
vResult=`echo "$vResult" | head -n 1`

if [ -z "$vResult" ]; then
    echo "ERROR: Nothing found for key '$1'"
    exit 1
fi

vKey=`echo $vResult | cut -f 1 -d':'`
vValue=`echo $vResult | cut -f 2 -d':'`
vKey=`echo $vKey`
vValue=`echo $vValue`

if [ -z "$vKey" ]; then
    echo "ERROR: Could not find key '$1' on matched line(s): "
    echo "$vResult"
    exit 1
fi

if [ -z "$vValue" ]; then
    echo "ERROR: Could not any value for key '$1' on matched line(s): "
    echo "'$vResult'"
    exit 1
fi

if [ $vNumLines -ne 1 ]; then
    echo "WARNING: Multiple matches! Only using the first one for '$vKey'"
fi

setClipboard "$vValue"
echo "Copied value for '$vKey' key!"
