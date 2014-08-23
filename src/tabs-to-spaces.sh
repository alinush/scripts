if [ $# -eq 0 ]; then
    echo "Converts all leading tabs to 4 spaces in all the files from the specified directory (recursively)"
    echo 
    echo "Usage: $0 <directory>"
    exit 0
fi

if [ ! -d "$1" ]; then
    echo "ERROR: '$1' is not a directory."
    exit 1
fi

vTargetDir=`readlink -f $1`

#find $vTargetDir -type f -exec sed -i 's/\t/    /g' {} \;
#find $vTargetDir -type f ! -name Makefile -exec sh -c 'tFile=`mktemp`; expand --initial --tabs=4 {} >$tFile && mv $tFile {};' \;
find $vTargetDir -type f ! -name Makefile -exec sed -ri ':a;s/^( *)\t/\1    /;ta' {} \;
