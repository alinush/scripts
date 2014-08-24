#!/bin/bash

set -e

scriptdir=$(readlink -f $(dirname $0))

vInFile=$1
vOutFile=$2

if [ $# -ne 2 ]; then
    echo "Usage: $0 <ciphertext> <plaintext> OPTIONS"
    echo
    echo "OPTIONS:"
    echo "  --directory     enable this if you are decrypting a directory"
    echo "  --file          enable this if you are decrypting a file"
    echo 
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

crypto_aes_decrypt_file $vInFile $vOutFile "$vPassword"

echo "Decryption was successful!"
