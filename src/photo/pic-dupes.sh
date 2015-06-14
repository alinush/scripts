set -e

destfile="exec.sh"
scriptdir=$(readlink -f $(dirname $0))

if [ $# -lt 1 ]; then
    echo "Usage: `basename $0` <dir>"
    exit 1
fi

echo "" >"$destfile"
echo "Generating commands in '$destfile'..."
echo

rm -f /tmp/gen.sh
# Silly findimagedupes doesn't work with paths that have spaces in them
ln -sf "$scriptdir/shlibs/generate.sh" /tmp/gen.sh
chmod +x /tmp/gen.sh
findimagedupes -R --threshold="97%" -p=/tmp/gen.sh $1

echo
echo "Executing commands in '$destfile'..."
chmod +x "$destfile"
sh "$destfile"

echo
echo "Done! Please be sure to delete the generated script:"
echo " rm $destfile"
echo
