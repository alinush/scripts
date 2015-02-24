set -e

which pdftk || { echo "ERROR: Please install pdftk"; exit 1; }
which qpdf || { echo "ERROR: Please install qpdf"; exit 1; }

pdftk_strip_metadata() {
   pdftk $1 dump_data | \
   sed -e 's/\(InfoValue:\)\s.*/\1\ /g' | \
   pdftk $1 update_info - output clean-$1 
}

qpdf_strip_metadata() {
    qpdf --empty --pages $1 1-z -- $2
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <pdf-file>"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "ERROR: '$1' is not a file"
    exit 1
fi 

vOutFile="$1.stripped.pdf"

echo "Writing stripped file to '$vOutFile' ..."
qpdf_strip_metadata "$1" "$vOutFile"

echo "New metadata (after stripping):"
echo "------"

pdftk "$vOutFile" dump_data
