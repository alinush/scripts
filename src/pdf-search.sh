#!/bin/sh

vDir="."
vPattern=$1

if [ -z "$vPattern" ]; then
    echo "Usage: $0 <pattern>"
    exit 1
fi

echo "Searching in $vDir for '$vPattern' pattern..."
echo
echo "find $vDir -name '*.pdf' -exec sh -c 'pdftotext \"{}\" - | grep --with-filename --label=\"{}\" --color \"$vPattern\"' \;"
echo

# NOTE: I can't get this to work. For some reason grep matches everything...
#find $vDir -name "*.pdf" -exec sh -c 'pdftotext -q "{}" - 2>&1 | grep --with-filename --label="{}" --color -I "$vPattern"' \;

find $vDir -name '*.pdf' | while read f; do 
    echo "Looking at '$f' ..."
    pdftotext -q "$f" - | grep -H --label="$f" -i --color "$vPattern"
done

