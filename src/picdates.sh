which jhead || { echo "ERROR: You need to have 'jhead' installed"; exit 1; }

OIFS="$IFS"
IFS=$'\n'
for file in `find -type f | grep -v Thumbs.db`; do
    ispic=0
    nodate=0

    jhead $file 2>&1 >/dev/null && ispic=1
    date=`jhead "$file" | grep "Date/Time" | cut -d':' -f 2-`
    [ -z "$date" ] && { nodate=1 ; date="*Date not set"; }

    if [ $ispic -eq 0 ]; then
        continue
    fi

    echo "$date - $file"
done | sort -r | uniq
IFS="$OIFS"
