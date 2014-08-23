# Set yourself as a sudoers
me=`whoami`
file=/etc/sudoers.d/$me
    
echo
echo "Setting yourself ($me) as a sudoer..."
echo

if [ ! -f $file ]; then
    sudo touch $file
    sudo chmod 0440 $file
    sudo sh -c "echo \"$me	ALL=(ALL)	NOPASSWD: ALL\" >$file"
    sudo chmod 0440 $file
else
    echo "There already exists a sudoers file in $file"
fi
