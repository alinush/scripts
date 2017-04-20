#!/bin/bash

if [ $# -lt 4 ]; then
    echo "Usage: `basename $0` <input-file> <start-time-hh:mm:ss[.milisecs]> <duration-in-secs[.milisecs]> <output-file>"
    exit 1
fi

cmd=avconv

if ! which $cmd &>/dev/null; then
    cmd=ffmpeg
fi

if ! which $cmd &>/dev/null; then
    echo "ERROR: Neither avconv nor ffmpeg are installed. Please install them and retry..."
    exit 1
fi

# Can pass in -codec copy but that tends to freeze the first couple of seconds in the output, which is annoying.
$cmd -i "$1" -ss "$2" -t "$3" "$4"
