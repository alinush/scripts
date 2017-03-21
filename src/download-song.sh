if [ $# -lt 1 ]; then
    echo "Usage: $0 <youtube-url>"
    exit 1
fi 

# --embed-thumbnail
youtube-dl -x "$1" --audio-format best --audio-quality 0 -o "%(title)s.%(ext)s"
