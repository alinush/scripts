#!/bin/bash

if [ $# -lt 5 ]; then
    echo "Usage: `basename $0` <input-file> -w <start-time-hh:mm:ss[.milisecs]> <end-time-hh:mm:ss[.milisecs]> <output-file> [extra-ffmpeg-args]"
    echo "       `basename $0` <input-file> -l <start-time-hh:mm:ss[.milisecs]> <duration-in-secs[.milisecs]>  <output-file> [extra-ffmpeg-args]"
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

shift 5
extra_ffmpeg_args=$@

if ! which $cmd &>/dev/null; then
    cmd=ffmpeg
fi

if ! which $cmd &>/dev/null; then
    echo "ERROR: Neither avconv nor ffmpeg are installed. Please install them and retry..."
    exit 1
fi

# -strict -2 is to enable experimental codecs like 'vorbis' (and apparently must be added right before $outputfile)
# (see https://stackoverflow.com/questions/32931685/the-encoder-aac-is-experimental-but-experimental-codecs-are-not-enabled)
# Can pass in -codec copy but that tends to freeze the first couple of seconds in the output, which is annoying.
echo "Executing: $cmd $extra_ffmpeg_args -i '$infile' -ss '$start_time' $flag '$end_time' -strict -2 '$outfile'"
$cmd $extra_ffmpeg_args -i "$infile" -ss "$start_time" $flag "$end_time" -strict -2 "$outfile"
