#!/usr/bin/env bash
set -euo pipefail

# ─── Text formatting — edit these ────────────────────────────────────────────
TEXT_COLOR="white"
# Either a font name (run `magick -list font` to see what ImageMagick knows about)
# or a path to a .ttf/.ttc/.otf file. On macOS, ImageMagick often ships with no
# configured fonts, so a file path is the most reliable option.
TEXT_FONT="/System/Library/Fonts/Supplemental/Arial Bold Italic.ttf"
TEXT_POINTSIZE=26
# Outline drawn around each glyph. Set TEXT_OUTLINE_WIDTH=0 to disable.
TEXT_OUTLINE_COLOR="black"
TEXT_OUTLINE_WIDTH=3
TEXT_GRAVITY="None"
# Gravity controls which point of the canvas is the origin for --text-x/--text-y offsets.
#
#   NorthWest | North  | NorthEast
#   ----------+--------+----------
#   West      | Center | East
#   ----------+--------+----------
#   SouthWest | South  | SouthEast
#
# "None"  → origin is the top-left corner of the frame; +x+y are plain pixel coordinates.
#            This is the most predictable setting and what you want in most cases.
# "South" → origin is the bottom-center of the frame; offsets are measured from there.
# etc.
# Only change this if you need to pin the text to a specific edge/corner of the frame
# (e.g. "always 20px from the bottom"), in which case pick the matching gravity and
# adjust --text-x/--text-y accordingly.
# ─────────────────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <input.gif> <output.gif>

Draws a horizontal red line and a text label onto every frame of a GIF.

Required options:
  --line-x   <int>    X coordinate of the line's left endpoint
  --line-y   <int>    Y coordinate of the line (horizontal line)
  --thickness <int>   Stroke width in pixels
  --length   <int>    Line length in pixels (extends rightward from line-x)
  --text-x   <int>    X coordinate of the text anchor (top-left)
  --text-y   <int>    Y coordinate of the text anchor (top-left)
  --text     <str>    Text string to render

Other:
  -h, --help          Print this help and exit

Example:
  $(basename "$0") \\
    --line-x 50 --line-y 100 --thickness 4 --length 200 \\
    --text-x 50 --text-y 80 --text "Hello, world!" \\
    in.gif out.gif
EOF
}

# ─── Argument parsing ─────────────────────────────────────────────────────────

if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

LINE_X=""
LINE_Y=""
THICKNESS=""
LENGTH=""
TEXT_X=""
TEXT_Y=""
TEXT_STR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --line-x)    LINE_X="$2";    shift 2 ;;
    --line-y)    LINE_Y="$2";    shift 2 ;;
    --thickness) THICKNESS="$2"; shift 2 ;;
    --length)    LENGTH="$2";    shift 2 ;;
    --text-x)    TEXT_X="$2";    shift 2 ;;
    --text-y)    TEXT_Y="$2";    shift 2 ;;
    --text)      TEXT_STR="$2";  shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    -*)          echo "Unknown option: $1" >&2; usage; exit 1 ;;
    *)           break ;;  # positional args
  esac
done

INPUT="${1:-}"
OUTPUT="${2:-}"

# ─── Validation ───────────────────────────────────────────────────────────────

die() { echo "Error: $*" >&2; exit 1; }

is_int() { [[ "$1" =~ ^[0-9]+$ ]]; }

[[ -n "$INPUT"     ]] || die "No input file specified."
[[ -n "$OUTPUT"    ]] || die "No output file specified."
[[ -f "$INPUT"     ]] || die "Input file not found: $INPUT"

[[ -n "$LINE_X"    ]] || die "--line-x is required."
[[ -n "$LINE_Y"    ]] || die "--line-y is required."
[[ -n "$THICKNESS" ]] || die "--thickness is required."
[[ -n "$LENGTH"    ]] || die "--length is required."
[[ -n "$TEXT_X"    ]] || die "--text-x is required."
[[ -n "$TEXT_Y"    ]] || die "--text-y is required."
[[ -n "$TEXT_STR"  ]] || die "--text is required."

is_int "$LINE_X"    || die "--line-x must be a non-negative integer."
is_int "$LINE_Y"    || die "--line-y must be a non-negative integer."
is_int "$THICKNESS" || die "--thickness must be a non-negative integer."
is_int "$LENGTH"    || die "--length must be a non-negative integer."
is_int "$TEXT_X"    || die "--text-x must be a non-negative integer."
is_int "$TEXT_Y"    || die "--text-y must be a non-negative integer."

if command -v magick &>/dev/null; then
  IM=(magick)
elif command -v convert &>/dev/null; then
  IM=(convert)
else
  die "ImageMagick not found in PATH ('magick' or 'convert')."
fi

# ─── Derived geometry ─────────────────────────────────────────────────────────

LINE_X2=$(( LINE_X + LENGTH ))
LINE_Y2=$LINE_Y   # horizontal line

# ─── Annotate ─────────────────────────────────────────────────────────────────
#
# Color can be specified as:
#   Named color   : "red", "blue", "lime", "white", "black", "cyan", "magenta", "yellow", ...
#                   Full list: https://imagemagick.org/script/color.php
#   Hex RGB       : "#FF0000"  (6-digit),  "#F00"  (3-digit shorthand)
#   Hex RGBA      : "#FF000080"  (last two hex digits = alpha, 00=transparent, FF=opaque)
#   rgb()         : "rgb(255,0,0)"
#   rgba()        : "rgba(255,0,0,0.5)"   (alpha in [0,1])
#   hsl()         : "hsl(0,100%,50%)"
#   "none"        : fully transparent (useful for -fill when you only want the stroke)

echo "Annotating '${INPUT}' → '${OUTPUT}' ..."

"${IM[@]}" "$INPUT" \
  -coalesce \
  -strokewidth "$THICKNESS" \
  -stroke "red" \
  -fill   "none" \
  -draw   "line ${LINE_X},${LINE_Y} ${LINE_X2},${LINE_Y2}" \
  -font        "$TEXT_FONT" \
  -pointsize   "$TEXT_POINTSIZE" \
  -gravity     "$TEXT_GRAVITY" \
  -stroke      "$TEXT_OUTLINE_COLOR" \
  -strokewidth "$(( TEXT_OUTLINE_WIDTH * 2 ))" \
  -fill        "$TEXT_OUTLINE_COLOR" \
  -annotate    "+${TEXT_X}+${TEXT_Y}" "$TEXT_STR" \
  -stroke      "none" \
  -strokewidth 0 \
  -fill        "$TEXT_COLOR" \
  -annotate    "+${TEXT_X}+${TEXT_Y}" "$TEXT_STR" \
  -layers optimize \
  "$OUTPUT"

echo "Done."
