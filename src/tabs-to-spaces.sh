if [ $# -eq 0 ]; then
    echo "Converts all leading tabs to 4 spaces in all the files from the specified file or directory (recursively)"
    echo 
    echo "Usage: $0 <directory-or-file>"
    exit 0
fi

cmd=gsed

! which $cmd &>/dev/null && cmd=sed

if [ -d "$1" ]; then
    vTargetDir=`readlink -f $1`

    #find $vTargetDir -type f -exec sed -i 's/\t/    /g' {} \;
    #find $vTargetDir -type f ! -name Makefile -exec sh -c 'tFile=`mktemp`; expand --initial --tabs=4 {} >$tFile && mv $tFile {};' \;
    find $vTargetDir -type f ! -name Makefile -exec $cmd -ri ':a;s/^( *)\t/\1    /;ta' {} \;
else
    $cmd -ri ':a;s/^( *)\t/\1    /;ta' "$1"
fi

