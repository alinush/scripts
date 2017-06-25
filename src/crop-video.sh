#!/bin/bash

if [ $# -lt 4 ]; then
    echo "Usage: `basename $0` -w <input-file> <start-time-hh:mm:ss[.milisecs]> <end-time-hh:mm:ss[.milisecs]> <output-file>"
    echo "       `basename $0` -l <input-file> <start-time-hh:mm:ss[.milisecs]> <duration-in-secs[.milisecs]> <output-file>"
    exit 1
fi

flag=

if [ "$1" == "-l" ]; then
    flag="-t"
elif [ "$1" == "-w" ]; then
    flag="-to"
else
    echo "ERROR: First argument must be either -l or -w (see --help), not '$1'"
    exit 1
fi

shift

cmd=avconv

if ! which $cmd &>/dev/null; then
    cmd=ffmpeg
fi

if ! which $cmd &>/dev/null; then
    echo "ERROR: Neither avconv nor ffmpeg are installed. Please install them and retry..."
    exit 1
fi

# Can pass in -codec copy but that tends to freeze the first couple of seconds in the output, which is annoying.
echo "Executing: $cmd -i '$1' -ss '$2' $flag '$3' '$4'"
$cmd -i "$1" -ss "$2" $flag "$3" "$4"
