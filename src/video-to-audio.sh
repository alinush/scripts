#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: `basename $0` <input-file> <output-file>"
    exit 1
fi

infile=$1
outfile=$2
cmd=avconv

if ! which $cmd &>/dev/null; then
    cmd=ffmpeg
fi

if ! which $cmd &>/dev/null; then
    echo "ERROR: Neither avconv nor ffmpeg are installed. Please install them and retry..."
    exit 1
fi

$cmd -i "$infile" -vn "$outfile"
