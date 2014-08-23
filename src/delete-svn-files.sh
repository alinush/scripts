status="?"

#
# Should return the inode of the actual file a symlink points to even
# if you have multiple layers: symlink1 -> symlink2 -> actual_file
#
get_inode()
{
    stat -L --printf "%i\n" $1
}

script_inode=`get_inode $0`

files="`svn status | grep "^$status" | cut -d' ' -f8`"

echo "Delete all files with status \"$status\" ?"

files_filtered=
for f in $files; do
    if [ ! -L $f -a `get_inode $f` != $script_inode ]; then
        files_filtered="$files_filtered $f"
        echo " * $f"
    fi
done

read -p "Delete all files above? (y/N): " ANS

if [ "$ANS" = "y" ]; then
    rm -f $files_filtered
fi
