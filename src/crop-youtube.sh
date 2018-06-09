#!/bin/bash

set -e

scriptdir=$(cd $(dirname $0); pwd -P)

if [ $# -lt 5 ]; then
    echo "Downloads and cuts a YouTube video. All videos are stored in a preconfigured directory (see youtube.conf)."
    echo
    echo "Usage: `basename $0` <youtube-url> -w <start-time-hh:mm:ss[.milisecs]> <end-time-hh:mm:ss[.milisecs]> <video-name> [extra-ffmpeg-args]"
    echo "       `basename $0` <youtube-url> -l <start-time-hh:mm:ss[.milisecs]> <duration-in-secs[.milisecs]>  <video-name> [extra-ffmpeg-args]"
    echo
    exit 1
fi

url=$1
crop_video_flag=$2
start_time=$3
end_time=$4
video_name=$5
shift 5
extra_ffmpeg_args=$@

if [ ! -f "$scriptdir/youtube.conf" ]; then
    echo "ERROR: Please create 'youtube.conf' configuration file with download directory path in '$scriptdir'"
    exit 1
fi

download_dir=`cat "$scriptdir/youtube.conf"`

# Other flags of interest:
# --format FORMAT (see man page for format selection)
# --list-formats / -F
# --merge-output-format FORMAT
# --recode-video FORMAT

echo "Getting YouTube video info..."
id_and_file=`youtube-dl --id --get-filename --get-title "$url"`
filename=`echo "$id_and_file" | tail -n 1`
title=`echo "$id_and_file" | head -n 1`
video_extension="${filename##*.}"
id=${filename%.*}
echo "YouTube video    ID: $id"
echo "YouTube video title: $title"

# Download YouTube video and store it in a by-id/ directory
mkdir -p "$download_dir/by-id"
(
    cd "$download_dir/by-id"
    youtube-dl --continue --id --no-call-home "$url"
)

# The uncut video is stored here
path=$download_dir/by-id/$filename

# Create symlink named with video's title
(
    cd "$download_dir"
    ln -sf "$path" "$title"
)

# The cut video will be stored here
cut_video_path=$download_dir/$video_name.mp4

$scriptdir/crop-video.sh "$path" $crop_video_flag "$start_time" "$end_time" "$cut_video_path" $extra_ffmpeg_args
