#!/bin/sh
set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <source-pdf> <dest-png/jpg-image-file>"
    exit 0
fi

if [ ! -f "$1" ]; then
    echo "ERROR: Source PDF file '$1' does not exist"
    exit 1
fi

if [ -f "$2" ]; then
    echo "ERROR: Destination image file '$1' already exists"
    exit 1
fi

convert -density 300 "$1" -quality 100 "$2"
