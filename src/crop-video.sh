#!/bin/bash

if [ $# -lt 5 ]; then
    echo "Usage: `basename $0` <input-file> -w <start-time-hh:mm:ss[.milisecs]> <end-time-hh:mm:ss[.milisecs]> <output-file>"
    echo "       `basename $0` <input-file> -l <start-time-hh:mm:ss[.milisecs]> <duration-in-secs[.milisecs]> <output-file>"
    exit 1
fi

infile=$1
flag=

if [ "$2" == "-l" ]; then
    flag="-t"
elif [ "$2" == "-w" ]; then
    flag="-to"
else
    echo "ERROR: First argument must be either -l or -w (see --help), not '$1'"
    exit 1
fi

start_time=$3
end_time=$4
outfile=$5
cmd=avconv

if ! which $cmd &>/dev/null; then
    cmd=ffmpeg
fi

if ! which $cmd &>/dev/null; then
    echo "ERROR: Neither avconv nor ffmpeg are installed. Please install them and retry..."
    exit 1
fi

# Can pass in -codec copy but that tends to freeze the first couple of seconds in the output, which is annoying.
echo "Executing: $cmd -i '$infile' -ss '$start_time' $flag '$end_time' '$outfile'"
$cmd -i "$infile" -ss "$start_time" $flag "$end_time" "$outfile"
