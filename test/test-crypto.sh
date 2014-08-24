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

test_crypto_aes_file() {
    local tInputFile=`mktemp`
    local tOutputFile=`mktemp`
    local tDecryptedFile=`mktemp`
    local tPassword="my random password with spaces"

    echo "hi all hi all hi all!" > $tInputFile
    
    echo "Encrypting '$tInputFile', storing in '$tOutputFile'"

    rm -r $tOutputFile
    if ! crypto_aes_encrypt_file $tInputFile $tOutputFile "$tPassword"; then
        test_failed "Could not encrypt input file"
    fi
    
    rm -r $tDecryptedFile
    if ! crypto_aes_decrypt_file $tOutputFile $tDecryptedFile "$tPassword"; then
        test_failed "Could not decrypt the encrypted file"
    fi
    
    if ! diff -rupN $tInputFile $tDecryptedFile; then
        test_failed "The original file is different than the decrypted file"
    fi
}

test_crypto_aes_dir() {
    local tInputDir=`mktemp -d`
    local tOutputFile=`mktemp`
    local tDecryptedDir=`mktemp -d`
    local tPassword="my random pass with spaces"

    echo "some random directory file" > $tInputDir/somefile
    
    rm -r $tOutputFile
    if ! crypto_aes_encrypt_dir "$tInputDir" "$tOutputFile" "$tPassword"; then
        test_failed "Could not encrypt input directory"
    fi

    rm -r $tDecryptedDir
    if ! crypto_aes_decrypt_file "$tOutputFile" "$tDecryptedDir" "$tPassword"; then
        test_failed "Could not decrypt directory"
    fi

    if ! diff -rupN $tInputDir $tDecryptedDir/`basename $tInputDir`; then
        test_failed "The original dir is different than the decrypted dir"
    fi
}

echo
echo "Testing hex conversion..."
test_hex_to_binary_file

echo
echo "Testing AES file encryption..."
test_crypto_aes_file

echo
echo "Testing AES directory encryption..."
test_crypto_aes_dir

tests_succeeded
