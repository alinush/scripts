which jhead || { echo "ERROR: You need to have 'jhead' installed"; exit 1; }

OIFS="$IFS"
IFS=$'\n'
for file in `find -type f | grep -v Thumbs.db`; do
    date=`jhead "$file" | grep "Date/Time"`
    echo "$date - $file"
done | sort -r | uniq
IFS="$OIFS"
