#!/bin/bash

set -e
#set -x

scriptdir=$(cd $(dirname $0); pwd -P)

. $scriptdir/shlibs/os.sh

youtube_conf=$scriptdir/youtube.conf
download_dir=`$sed_cmd "1q;d" "$youtube_conf"`

if [ ! -f "$youtube_conf" ]; then
    echo "ERROR: Please create configuration file with download directory path in '$youtube_conf'"
    exit 1
fi

if [ $# -lt 4 ]; then
    echo "Downloads and cuts a YouTube video"
    echo " - The cut video is stored in: $download_dir/"
    echo " - The uncut video is stored in: $download_dir/uncut/"
    echo
    echo "To change these directories, edit the '$youtube_conf' config file."
    echo
    echo "Usage: `basename $0` <youtube-url> <start-time-hh:mm:ss[.milisecs]> <end-time-hh:mm:ss[.milisecs]> <video-name> [extra-ffmpeg-args]"
    echo
    exit 1
fi

url=$1
crop_video_flag="-w"
start_time=$2
end_time=$3
video_name=$4
accidental_extension=$([[ "$video_name" = *.* ]] && echo "${video_name##*.}" || echo '')
video_name=${video_name%%.*}
echo "Output video name (w/o extension): $video_name"

if [ -n "$accidental_extension" ]; then
    echo "ERROR: Do not give an extension. Just give the video name. (You gave '$accidental_extension' as an extension.)"
    exit 1
fi

all_args="$@"
shift 4
extra_ffmpeg_args=$@

logfile=`$sed_cmd "2q;d" "$youtube_conf"`

if [ ! -f "$logfile" ]; then
    touch $logfile
fi

# Other youtube-dl flags of interest:
# --format FORMAT (see man page for format selection)
# --list-formats / -F
# --merge-output-format FORMAT
# --recode-video FORMAT

echo "Getting YouTube video info..."
filename_fmt="%(channel)s--%(title)s--%(id)s.%(ext)s"
desc=`yt-dlp --print title --print channel --print filename -o $filename_fmt "$url"`
title=`echo "$desc" | head -n 1`
channel=`echo "$desc" | head -n 2 | tail -n 1`
filename=`echo "$desc" | tail -n 1`
video_extension="${filename##*.}"
echo "YouTube video extension: $video_extension"
echo "YouTube video filename:  $filename"
echo "YouTube video title:     $title"

date=`date +"%Y %B %A %d %I:%M %p %Z"`
echo "[$date] Ran '`basename $0` $all_args'" >>"$logfile"
echo "[$date] Downloading '$title' from $url and cutting it as '$video_name' with flags '$crop_video_flag $start_time $end_time' ..." >>"$logfile"

if [ -z "$video_extension" ]; then
    echo "ERROR: Expected a video extension in the filename '$filename'"
    exit 1
fi

# Download YouTube video and store it in the download directory
mkdir -p "$download_dir/uncut"
(
    cd "$download_dir/uncut"
    yt-dlp --continue -o $filename_fmt "$url"
)

# The uncut video is stored here
path=$download_dir/uncut/$filename

if [ ! -f "$path" ]; then
    echo "WARNING: Could not find video file at expected path '$path'."
    echo "This probably because yt-dlp changed the file's extension to 'mkv.' Trying 'mkv' extension."
    path="${path%$video_extension}mkv" 

    if [ ! -f "$path" ]; then
        echo "WARNING: Could not find video file at secondary path either '$path'."
        echo "This probably because yt-dlp changed the file's extension to 'webm' Trying 'webm' extension."
        path="${path%$video_extension}webm" 
    
        if [ ! -f "$path" ]; then
            exit 1
        fi
    fi
fi

#echo
#echo "Replacing / characters in title if any..."
#title="${title//\//-}"

# The cut video will be stored here
cut_video_path=$download_dir/$video_name.mp4

$scriptdir/crop-video.sh "$path" $crop_video_flag "$start_time" "$end_time" "$cut_video_path" $extra_ffmpeg_args
