[ -f "all.pdf" ] && { echo "ERROR: Destination file 'all.pdf' already exists. Will not overwrite, so please move it."; exit 1; }

echo "Merging documents together: $@"

gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=all.pdf $@
