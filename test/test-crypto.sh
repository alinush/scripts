#!/bin/bash

set -e

scriptdir=$(readlink -f $(dirname $0))

. $scriptdir/test-utils.sh
. $scriptdir/../src/shlibs/crypto.sh 2>&1 >/dev/null

test_hex_to_binary_file() {
    local tHexStringOrig="1234abcdef"
    local tTempFile=`mktemp`
    
    hex_to_binary_file $tHexStringOrig $tTempFile

    local tHexString=`binary_file_to_hex $tTempFile`
    
    echo "Hex orignal:   $tHexStringOrig"
    echo "Hex read back: $tHexString"
    
    if [ "$tHexString" != "$tHexStringOrig" ]; then
        test_failed "Original hex string '$tHexStringOrig' differs from the one read back '$tHexString'"
    fi
}

test_crypto_aes() {
    local tInputFile=`mktemp`
    local tOutputFile=`mktemp`
    local tDecryptedFile=`mktemp`
    local tPassword="my random password with spaces"
    
    echo "hi all hi all hi all!" > $tInputFile
    
    echo "Encrypting '$tInputFile', storing in '$tOutputFile'"

    rm $tOutputFile
    if ! crypto_aes_encrypt_file $tInputFile $tOutputFile "$tPassword"; then
        test_failed "Could not encrypt input file"
    fi
    
    rm $tDecryptedFile
    if ! crypto_aes_decrypt_file $tOutputFile $tDecryptedFile "$tPassword"; then
        test_failed "Could not decrypt the encrypted file"
    fi
    
    if ! diff -rupN $tInputFile $tDecryptedFile; then
        test_failed "The original file is different than the decrypted file"
    fi
}

test_hex_to_binary_file
test_crypto_aes


tests_succeeded
