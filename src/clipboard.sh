#!/bin/bash

set -e

scriptdir=$(cd $(dirname $0); pwd -P)

. $scriptdir/shlibs/clipboard.sh

vConfFile=$scriptdir/clipboard.conf

printUsage() {
    echo "Usage: $(basename $0) [OPTIONS] <grep-pattern>"
    echo
    echo "OPTIONS:"
    echo "   -f, --file <path>    file to copy from"
}

if [ -z "$1" ]; then
    printUsage
    exit 1
fi

if [ "$1" == "-c" -o "$1" == "--clear" ]; then
    clearClipboard
    echo "Cleared clipboard!"
    exit 0
fi

if [ "$1" == "--file"  -o "$1" == "-f" ]; then
    vFile=$2
    shift 2;
else
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
fi

if [ ! -f "$vFile" ]; then
    echo "ERROR: The '$vFile' file to grep in does not exist"
    exit 1
fi

if [ -z "$1" ]; then
    echo "ERROR: You need to specify a pattern."
    echo
    printUsage
    exit 1
fi

if [ $# -gt 1 ]; then
    echo "ERROR: You need to specify EXACTLY ONE pattern."
    echo
    printUsage
    exit 1
fi

echo "Copying from '$vFile'..."

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
