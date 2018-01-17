#!/bin/bash

set -e

scriptdir=$(cd $(dirname $0); pwd -P)

. $scriptdir/shlibs/os.sh

vInFile=$1
vOutFile=$2

if [ $# -ne 2 ]; then
    echo "Usage: `basename $0` <ciphertext> <plaintext>"
    exit 1
fi

if [ -f "$vOutFile" ]; then
    echo "ERROR: '$vOutFile' already exists. Will not overwrite so please delete."
    exit 1
fi

if [ ! -f "$vInFile" ]; then
    echo "ERROR: '$vInFile' does not exist."
    exit 1
fi

. $scriptdir/shlibs/crypto.sh >&2

echo "Operation:"
echo " * decrypt('$vInFile') -> '$vOutFile'"; echo;

read -s -p " * Please enter password: " vPassword; echo; 

echo " * Decrypting '$vInFile', storing in '$vOutFile' ..."
echo

if ! crypto_aes_decrypt_file $vInFile $vOutFile "$vPassword"; then
    exit 1
fi

echo "Decryption was successful!"
