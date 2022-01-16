OS_IMPORTED=1
OS_FLAVOR="Unknown"

if [ "$(uname -s)" = "Darwin" ]; then
    OS="OSX"
elif [ "$(uname -s)" = "Linux" ]; then
    OS="Linux"

    if [ -f /etc/issue ]; then
        if grep Fedora /etc/issue >/dev/null; then
    	    OS_FLAVOR="Fedora"
        elif grep Ubuntu /etc/issue >/dev/null; then
            OS_FLAVOR="Ubuntu"
        fi
    fi
fi

if which gsed &>/dev/null; then
    sed_cmd=gsed
elif which sed &>/dev/null; then
    sed_cmd=sed
else
    echo "Neither 'sed' nor 'gsed' was found. Exiting..."
    exit 1
fi

#echo "OS: $OS"
#echo "OS Flavor: $OS_FLAVOR"
