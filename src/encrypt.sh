#!/bin/bash

set -e

scriptdir=$(cd $(dirname $0); pwd -P)

. "$scriptdir/shlibs/os.sh"

vInFile=$1
vOutFile=$2

if [ $# -ne 2 ]; then
    echo "Usage: `basename $0` <plaintext> <ciphertext>"
    exit 1
fi

if [ ! -f "$vInFile" -a ! -d "$vInFile" ]; then
    echo "ERROR: '$vInFile' is not a file nor a directory"
    exit 1
fi

if [ -f "$vOutFile" ]; then
    echo "ERROR: '$vOutFile' already exists. Will not overwrite so please delete."
    exit 1
fi

. "$scriptdir/shlibs/crypto.sh" >&2

if [ -d "$vOutFile" ]; then
    vOutFile=`$readlinkCmd -f "$vOutFile"`/`basename "$vInFile"`.enc
fi

echo "Operation:"
echo " * encrypt('$vInFile') -> '$vOutFile'"; echo;

read -s -p " * Please enter password: " pass1; echo;
read -s -p " * Please confirm password: " pass2; echo;

echo

if [ "$pass1" != "$pass2" ]; then
    echo "ERROR: Passwords don't match."
    exit 1
fi

vPassword="$pass1"

if [ -z "$vPassword" ]; then
    echo "ERROR: Password cannot be empty."
    exit 1
fi

echo "Thank you! Passwords match!"; echo

echo " * Encrypting '$vInFile', storing in '$vOutFile' ..."
echo

if [ -f "$vInFile" ]; then
    if ! crypto_aes_encrypt_file "$vInFile" "$vOutFile" "$vPassword"; then
        exit 1
    fi
elif [ -d "$vInFile" ]; then
    if ! crypto_aes_encrypt_dir "$vInFile" "$vOutFile" "$vPassword"; then
        exit 1
    fi
else
    echo "ERROR: '$vInFile' is not a file or a directory."
    exit 1
fi

echo "Encryption succeeded!"
