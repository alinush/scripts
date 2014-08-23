# Global variables: 

# The AES mode that this library will use. Please see 'man enc'
# for documentation on other modes that you can use here.
gCryptoAesMode=aes-256-ctr

gCryptoKdfIvSize=32         # the KDF IV size in bytes
gCryptoAesIvSize=16         # AES IV size in bytes
gCryptoMacSize=32           # MAC size in bytes

echo "Using crypto library... "

set -e
echo " * Checking for tools..."
echo "   + OpenSSL binary..."
which openssl &>/dev/null
echo "   + sed..."
which sed &>/dev/null
echo "   + printf..."
which printf &>/dev/null
echo "   + hexdump..."
which hexdump &>/dev/null
echo "   + sha256sum..."
which sha256sum &>/dev/null
echo " * All are tools here!"
echo 
set +e

#
# $1 hex string to be converted to binary
#
hex_to_binary() {
    echo -n "$1" | sed 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI' | xargs printf
}

#
# $1 hex string to be converted to binary
# $2 file where binary data will be stored
#
hex_to_binary_file() {
    hex_to_binary "$1" >$2
}

binary_file_to_hex() {
    hexdump -ve '1/1 "%.2x"' "$1"
}

binary_to_hex() {
    hexdump -ve '1/1 "%.2x"'
}

#
# $1 the IV size in bytes
#
crypto_get_random_iv()
{
    echo "`openssl rand -hex $1`"
}

#
# $1 the password
# $2 the IV/salt used for the KDF
#
crypto_kdf()
{
    echo -n "($1|$2)" | sha256sum | cut -d' ' -f 1
}

#
# $1 the HMAC key 
# $2 -hex or -binary
# $@ extra arguments for openssl dgst tool like -binary
#
crypto_hmac()
{
    local tKey=$1; shift;
    local tOutputType=$1; shift;
    
    if [ "$tOutputType" = "-hex" ]; then
        openssl dgst -sha256 -mac HMAC -macopt hexkey:$tKey $@ | cut -d' ' -f 2
        echo
    elif [ "$tOutputType" = "-binary" ]; then
        openssl dgst -sha256 -mac HMAC -macopt hexkey:$tKey -binary $@
    fi
}

#
# $1 the input file to encrypt
# $2 the destination file to store the result
# $3 the password to use, which will be turned into a 256-bit AES key using a KDF
#
crypto_aes_encrypt_file()
{
    # Variables for parameters
    local pInFile="$1"
    local pOutFile="$2"
    local pPassword="$3"
    
    if [ "$pInFile" = "$pOutFile" ]; then
        echo "ERROR: Input and output file cannot be the same"
        return 1
    fi
    
    if [ -f "$pOutFile" ]; then
        echo "ERROR: Will NOT overwrite an existing encrypted file. Please delete '$pOutFile' first."
        return 1
    fi
    
    # Temporary variables
    local tKdfAesIv=`crypto_get_random_iv $gCryptoKdfIvSize`    # the IV used in the KDF for obtaining the AES key
    local tKdfMacIv=`crypto_get_random_iv $gCryptoKdfIvSize`    # the IV used in the KDF for obtaining the HMAC key
    local tAesIv=`crypto_get_random_iv $gCryptoAesIvSize`       # the AES IV
    local tMac=0000000000000000000000000000000000000000000000000000000000000000    # the MAC over the ciphertext (we will replace this later)
    local tAesKey=`crypto_kdf "aes-$pPassword" $tKdfAesIv`      # the AES encryption key
    local tMacKey=`crypto_kdf "hmac-$pPassword" $tKdfMacIv`     # the HMAC integrity key
    
    echo "KDF IV for AES key: $tKdfAesIv"
    echo "KDF IV for MAC key: $tKdfMacIv"
    echo "AES IV: $tAesIv"
    
    #echo "AES key: $tAesKey"
    #echo "MAC key: $tMacKey"
    
    echo "Encrypting with $((${#tAesKey}/2 * 8))-bit key and $((${#tAesIv}/2 * 8))-bit IV"
    
    # The destination encrypted file format is: << kdfAesIv, kdfMacIv, aesIv, hmac, ciphertext >>
    # The HMAC is computed over << kdfAesIv, kdfMacIv, aesiv, [32 zero bytes], ciphertext >>
    tMac=`( hex_to_binary $tKdfAesIv;
      hex_to_binary $tKdfMacIv;
      hex_to_binary $tAesIv;
      hex_to_binary $tMac;
      openssl enc -e -nosalt -$gCryptoAesMode -in "$pInFile" -iv $tAesIv -K $tAesKey; ) \
        | tee >(cat >$pOutFile) | crypto_hmac $tMacKey -hex`
      
    if [ $? -ne 0 ]; then
        echo "ERROR: The OpenSSL enc tool failed encrypting"
        return 1
    fi
    
    echo "Computed MAC: $tMac"
    
    local tOrigSize=`stat --printf %s $pOutFile`
    
    # Write in the actual MAC in the output file
    hex_to_binary $tMac | dd of="$pOutFile" obs=$gCryptoMacSize count=1 conv=notrunc oflag=seek_bytes seek=$(($gCryptoKdfIvSize * 2 + $gCryptoAesIvSize)) 2>/dev/null
    
    local tModifiedSize=`stat --printf %s $pOutFile`
        
    if [ "$tOrigSize" != "$tModifiedSize" ]; then
        echo "ERROR: Internal error, file size changed from $tOrigSize bytes to $tModifiedSize bytes after writing MAC to file"
        return 1
    fi
    
    return 0
}

#
# $1 the input encrypted/ciphertext file
# $2 the output file where the decrypted plaintext will be stored
# $3 the password used to derive the AES key from 
#
crypto_aes_decrypt_file()
{
    local pInFile="$1"
    local pOutFile="$2"
    local pPassword="$3"
    
    if [ "$pInFile" = "$pOutFile" ]; then
        echo "ERROR: Input and output file cannot be the same"
        return 1
    fi
    
    if [ -f "$pOutFile" ]; then
        echo "ERROR: Will NOT overwrite an existing encrypted file. Please delete '$pOutFile' first."
        return 1
    fi
    
    # the IV used in the KDF for obtaining the AES key
    local tKdfAesIv=`dd if="$pInFile" bs=$gCryptoKdfIvSize count=1 2>/dev/null | binary_to_hex`
    echo "KDF IV for AES key: $tKdfAesIv"
    
    # the IV used in the KDF for obtaining the HMAC key
    local tKdfMacIv=`dd if="$pInFile" bs=$gCryptoKdfIvSize count=1 iflag=skip_bytes skip=$gCryptoKdfIvSize 2>/dev/null | binary_to_hex`
    echo "KDF IV for MAC key: $tKdfMacIv"
    
    # the AES IV
    local tAesIv=`dd if="$pInFile" bs=$gCryptoAesIvSize count=1 iflag=skip_bytes skip=$(($gCryptoKdfIvSize * 2)) 2>/dev/null | binary_to_hex`
    echo "AES IV: $tAesIv"
    
    # the MAC over the KDF IVs, AES IV and ciphertext
    local tZeroes=0000000000000000000000000000000000000000000000000000000000000000
    local tMac=`dd if="$pInFile" bs=$gCryptoMacSize count=1 iflag=skip_bytes skip=$(($gCryptoKdfIvSize * 2 + $gCryptoAesIvSize)) 2>/dev/null | binary_to_hex`
    echo "Stored MAC: $tMac"
    
    local tAesKey=`crypto_kdf "aes-$pPassword" $tKdfAesIv`  # the AES encryption key
    local tMacKey=`crypto_kdf "hmac-$pPassword" $tKdfMacIv` # the HMAC integrity key
    
    echo "Decrypting with $((${#tAesKey}/2 * 8))-bit key and $((${#tAesIv}/2 * 8))-bit IV"
    
    local tComputedMac=`( hex_to_binary $tKdfAesIv; 
      hex_to_binary $tKdfMacIv;
      hex_to_binary $tAesIv; 
      hex_to_binary $tZeroes;
      dd if="$pInFile" iflag=skip_bytes skip=$(($gCryptoKdfIvSize * 2 + $gCryptoAesIvSize + $gCryptoMacSize)) 2>/dev/null \
        | tee >(openssl enc -d -nosalt -$gCryptoAesMode -out $pOutFile -iv $tAesIv -K $tAesKey) ) | crypto_hmac $tMacKey -hex`
    
    if [ $? -ne 0 ]; then
        echo "ERROR: The OpenSSL enc tool failed decrypting"
        return 1
    fi
    
    echo "Computed MAC: $tComputedMac"
    
    if [ "$tMac" != "$tComputedMac" ]; then
        echo "ERROR: Stored MAC '$tMac' did not match file's actual MAC '$tComputedMac'"
        return 1
    fi
}
