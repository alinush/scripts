#!/bin/bash

set -e

scriptdir=$(readlink -f $(dirname $0))

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
    crypto_aes_encrypt_file $vInFile $vOutFile "$vPassword"
elif [ -d "$vInFile" ]; then
    crypto_aes_encrypt_dir $vInFile $vOutFile "$vPassword"
else
    echo "ERROR: '$vInFile' is not a file or a directory."
    exit 1
fi

echo "Encryption succeeded!"
