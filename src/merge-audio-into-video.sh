#!/bin/bash

set -e

if [ $# -lt 3 ]; then
    echo "Usage: $0 <audio-file> <audio-start-time-hh:mm:ss[.milisecs] <video-file> <dest-file>"
    exit 1
fi

audiofile=$1
audiostart=$2
videofile=$3
destfile=$4

audioshorter=`mktemp`.mp3
audioextracted=`mktemp`.mp3
audiomerged=`mktemp`.mp3

# Extract audio from video
ffmpeg -i "$videofile" "$audioextracted"

# Cut the provided audio file as specified

ffmpeg -i "$audiofile" -acodec copy -ss "$audiostart" "$audioshorter"

# Merge the two audio files
ffmpeg -i "$audioextracted" -i "$audioshorter" -filter_complex amerge -c:a libmp3lame -q:a 4 "$audiomerged"

# Replace the video's sound with the merged audio
ffmpeg -i "$videofile" -i "$audiomerged" -map 0:v -map 1:a -c copy -y "$destfile"
