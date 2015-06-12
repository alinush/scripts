# use 'uniq -w 64' to print duplicates by matching on the first 64
# characters only
#
# use 'uniq -D' to print ALL duplicate lines

if [ "$1" == "-h" -o "$1" == "--help" ]; then
    echo "Usage: `basename $0` [OPTIONS]"
    echo
    echo "OPTIONS:"
    echo "   -D, --all-repeated[=delimit-method]    prints all duplicate lines (see 'man uniq')"
    echo
    exit
fi

find . -type f -print0 | xargs -0 sha256sum | sort | uniq $@ -d --check-chars=64
