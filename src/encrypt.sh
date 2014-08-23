#!/bim/bash
set -e

scriptdir=$(readlink -f $(dirname $0))

. "$scriptdir/shlibs/crypto.sh"

vInFile=$1
vOutFile=$2

if [ $# -ne 2 ]; then
    echo "Usage: $0 <plaintext> <ciphertext>"
    exit 1
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

crypto_aes_encrypt_file $vInFile $vOutFile $vPassword 

echo "All done!"
