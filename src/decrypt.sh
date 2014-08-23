#!/bin/bash

set -e

scriptdir=$(readlink -f $(dirname $0))

. $scriptdir/shlibs/crypto.sh

vInFile=$1
vOutFile=$2

if [ $# -ne 2 ]; then
    echo "Usage: $0 <ciphertext> <plaintext>"
    exit 1
fi

echo "Operation:"
echo " * decrypt('$vInFile') -> '$vOutFile'"; echo;

read -s -p " * Please enter password: " vPassword; echo; 

echo " * Decrypting '$vInFile', storing in '$vOutFile' ..."
echo

crypto_aes_decrypt_file $vInFile $vOutFile $vPassword

echo "Decryption was successful!"
