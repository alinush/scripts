#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path-to-video> [speed]"
    echo ""
    echo "  speed: Playback speed multiplier (default: 1)."
    echo "         2 = twice as fast, 0.5 = half speed, etc."
    exit 1
fi

input="$1"
speed="${2:-1}"

if [[ ! -f "$input" ]]; then
    echo "Error: file not found: $input"
    exit 1
fi

dir="$(dirname "$input")"
basename="$(basename "$input")"
basename="${basename%.*}"
output="${dir}/${basename}.gif"

pts_factor=$(echo "scale=4; 1 / $speed" | bc)

echo "Converting at ${speed}x speed..."

ffmpeg -y -i "$input" -vf "setpts=${pts_factor}*PTS,scale=-1:-1:flags=lanczos" -loop 0 "$output"

echo "Created: $output"
