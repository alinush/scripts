#!/bin/bash

set -e

scriptdir=$(readlink -f $(dirname $0))

if [ "$1" == "-h" -o "$1" == "--help" ]; then
    echo "Usage: $0 <file-to-watch> <destination-directory>"
    exit 0
fi

. $scriptdir/shlibs/crypto.sh >&2

# We log messages with: logger --tag 'watch-encrypt.sh' "some message"
which logger &>/dev/null || { echo "ERROR: Need to have 'logger' command installed"; exit 1; }

vInFile=${1:-lol.txt}
vDestDir=${2:-/tmp}

vInFile=`readlink -f $vInFile`

if [ ! -f "$vInFile" -a ! -d "$vInFile" ]; then
    echo "ERROR: Cannot watch '$vInFile'. Are you sure it is a directory or a file?"
    exit 1
fi

read -s -p "Please enter password to use to encrypt '$vInFile' when it changes: " password; echo
#echo "Password: '$password'"

echo "Watching '$vInFile' for changes, backing up in $vDestDir..."
while true; do
    tEvents=`inotifywait -e create -e move_self -e delete_self -e close_write -e attrib -e modify --format %e "$vInFile" 2>&1 | tail -n +3`
    tRet=$?  # this does return the code for inotifywait (even though it is executed inside `` quotes

    echo "Something happened with $vInFile..."
    echo " * inotifywait returned: $tRet"
    if [ $tRet -eq 0 ]; then
        echo " * inotifywait events: $tEvents"

        # FIXME: we are not checking if $vInFile was initially
        # a directory, could lead to bugs.
        if [ -f "$vInFile" -o -d "$vInFile" ]; then
            echo " * '$vInFile' exists after event..."
            sleep 1     # we use second granularity for naming 
            tTimestamp=`date +%Y-%m-%d-%H-%M-%S`
            tDestFile="$vDestDir/`basename $vInFile`-$tTimestamp.enc"
            # Encrypt file and store in $vDestDir/$vInFile-$tTimestamp.enc
            if [ -d "$vInFile" ]; then
                echo " * Encrypting and backing up directory '$vInFile' -> '$tDestFile' ..."
                if ! crypto_aes_encrypt_dir "$vInFile" "$tDestFile" "$password"; then
                    errmsg="Something went bad while encrypting directory '$vInFile'"
                    echo "ERROR: $errmsg"
                    logger --tag "$0" "$errmsg"
                fi
            else
                echo " * Encrypting and backing up file '$vInFile' -> '$tDestFile'..."
                if ! crypto_aes_encrypt_file "$vInFile" "$tDestFile" "$password"; then
                    errmsg="Something went bad while encrypting file '$vInFile'"
                    echo "ERROR: $errmsg"
                    logger --tag "$0" "$errmsg"
                fi

            fi
        else
            echo " * $vInFile does NOT exist after event..."
            sleep 1
        fi
    else
        echo "ERROR: inotifywait failure, retrying in 2 seconds..."
        sleep 2
    fi
    echo
done
