if [ $# -lt 1 ]; then
    echo "Usage: $0 <youtube-url> [audio-format]"
    exit 1
fi 

audio_format=${2:-'m4a'}

# --embed-thumbnail
youtube-dl -x "$1" --audio-format "$audio_format" --audio-quality 0 -o "%(title)s.%(ext)s"
