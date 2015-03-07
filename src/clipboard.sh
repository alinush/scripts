scriptdir=$(readlink -f $(dirname $0))

vConfFile=$scriptdir/clipboard.conf

if [ -z "$1" ]; then
    echo "Usage: $(basename $0) <grep-pattern>"
    exit 1
fi

if [ ! -f "$vConfFile" ]; then
    echo "ERROR: No config file at '$vConfFile'"
    exit 1
fi

vNumLines=`wc -l $vConfFile | cut -f 1 -d' '` 

if [ $vNumLines != 1 ]; then
    echo "ERROR: '$vConfFile' can only have one line"
    exit 1
fi

vFile=`cat $vConfFile`
vFile=`echo $vFile`

if [ ! -f "$vFile" ]; then
    echo "ERROR: The '$vFile' file to grep in does not exist"
    exit 1 
fi

echo "Copying from $vFile..."

vResult=`grep "^$1" "$vFile"`
vNumLines=`echo "$vResult" | wc -l | cut -f 1 -d' '`
vResult=`echo $vResult | head -n 1`

if [ -z "$vResult" ]; then
    echo "ERROR: Nothing found for key '$1'"
    exit 1
fi

vKey=`echo $vResult | cut -f 1 -d':'`
vValue=`echo $vResult | cut -f 2 -d':'`
vKey=`echo $vKey`
vValue=`echo $vValue`

if [ -z "$vKey" ]; then
    echo "ERROR: Could not find key '$1' on matched line(s): "
    echo "$vResult"
    exit 1
fi

if [ -z "$vValue" ]; then
    echo "ERROR: Could not any value for key '$1' on matched line(s): "
    echo "'$vResult'"
    exit 1
fi

if [ $vNumLines != 1 ]; then
    echo "WARNING: Multiple matches! Only using the first one for '$vKey'"
fi

echo -n "$vValue" | xclip -sel clip
echo "Copied value for '$vKey' key!"
