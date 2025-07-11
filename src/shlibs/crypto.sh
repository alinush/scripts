#!/bin/bash

# WARNING: Assumes os.sh is sourced!

# Global variables
#
# The AES mode that this library will use. Please see 'man enc'
# for documentation on other modes that you can use here.
gCryptoAesMode=aes-256-ctr

gCryptoKdfIvSize=32         # the KDF IV size in bytes
gCryptoAesIvSize=16         # AES IV size in bytes
gCryptoMacSize=32           # MAC size in bytes
# 1 byte for version
# 1 byte for type of plaintext (file or directory)
# KDF IVs \times 2
# AES IV
# MAC
gCryptoHeaderSize=$((1 + 1 + $gCryptoKdfIvSize * 2 + $gCryptoAesIvSize + $gCryptoMacSize))

# The version of the crypto library stored in MAJOR.MINOR format, 4 bits for
# each number. We start with 1.0 stored as 0001 0000 (bin) = 0x10 (hex)
gCryptoVersionByteHex=10

echo "Using crypto library... " >&2

echo " * Checking for tools..." >&2
echo "   + OpenSSL binary..." >&2
which openssl &>/dev/null || { echo " missing!"; exit 1; }
echo "   + printf..." >&2
which printf &>/dev/null || { echo " missing!"; exit 1; }
echo "   + hexdump..." >&2
which hexdump &>/dev/null || { echo " missing!"; exit 1; }
echo -n "   + sha256sum..." >&2
if which sha256sum &>/dev/null; then
    sha256cmd='sha256sum'
else
    if which shasum &>/dev/null; then
        sha256cmd='shasum -a 256'
    else
        echo " missing!"
        exit 1
    fi
fi
echo
echo " * All are tools here!" >&2
echo -n " * Checking OS..."
if [ -z "$OS" ]; then
    echo " did you source os.sh?"
    exit 1
else
    echo " $OS detected."
fi

ddCmd='dd'
readlinkCmd='readlink'
if [ "$OS" == "OSX" ]; then
    getFileSizeCmd='stat -f "%z"'

    if which greadlink &>/dev/null; then
        readlinkCmd='greadlink'
    else
        echo "ERROR: Missing greadlink (i.e., GNU readlink)"
        exit 1
    fi

    if which gdd &>/dev/null; then
        ddCmd='gdd'
    else
        echo "ERROR: Missing gdd (i.e., GNU dd)"
        exit 1
    fi 
else
    getFileSizeCmd='stat --printf "%s"'
fi
echo  >&2

#
# $1 path to file. 
# Both on Linux and OS X, if file is a symlink, prints the symlink size, not the pointed-to file size
#
get_file_size() {
    $getFileSizeCmd "$1"
}

#
# $1 hex string to be converted to binary
#
hex_to_binary() {
    # NOTE: sed and gsed are not really cross-platform
    #echo -n "$1" | sed 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI' | xargs printf
    echo -n "$1" | xxd -r -p
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

echo "Binary to hex and back works!" | binary_to_hex | hex_to_binary

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
    echo -n "($1|$2)" | $sha256cmd | cut -d' ' -f 1
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
# $1 the input file to encrypt or - for encrypting stdin
# $2 the destination file to store the result
# $3 the password to use, which will be turned into a 256-bit AES key using a KDF
#
# Returns: 0 for success, 1 for failure
#
crypto_aes_encrypt_file()
{
    # Variables for parameters
    local pInFile="$1"
    local pOutFile="$2"
    local pPassword="$3"
    
    if [ "$pInFile" = "$pOutFile" ]; then
        echo "ERROR: Input and output file cannot be the same" >&2
        return 1
    fi
    
    if [ -f "$pOutFile" ]; then
        echo "ERROR: Will NOT overwrite an existing encrypted file. Please delete '$pOutFile' first." >&2
        return 1
    fi

    if [ -d "$pOutFile" ]; then
        echo "ERROR: Output file cannot be a directory."
        return 1
    fi
    
    # Temporary variables
    local tKdfAesIv=`crypto_get_random_iv $gCryptoKdfIvSize`    # the IV used in the KDF for obtaining the AES key
    local tKdfMacIv=`crypto_get_random_iv $gCryptoKdfIvSize`    # the IV used in the KDF for obtaining the HMAC key
    local tAesIv=`crypto_get_random_iv $gCryptoAesIvSize`       # the AES IV
    local tMac=0000000000000000000000000000000000000000000000000000000000000000    # the MAC over the ciphertext (we will replace this later)
    local tAesKey=`crypto_kdf "aes-$pPassword" $tKdfAesIv`      # the AES encryption key
    local tMacKey=`crypto_kdf "hmac-$pPassword" $tKdfMacIv`     # the HMAC integrity key
    
    echo "KDF IV for AES key: $tKdfAesIv" >&2
    echo "KDF IV for MAC key: $tKdfMacIv" >&2
    echo "AES IV: $tAesIv" >&2
    
    #echo "AES key: $tAesKey"
    #echo "MAC key: $tMacKey"
    
    echo "Encrypting with $((${#tAesKey}/2 * 8))-bit key and $((${#tAesIv}/2 * 8))-bit IV ..." >&2

    # The type of file being encrypted: 0x00 for file, 0x01 for directory
    local tFileType=00
    if [ "$pInFile" == "-" ]; then
        tFileType=01
    fi
    
    # The destination encrypted file format is: << kdfAesIv, kdfMacIv, aesIv, hmac, ciphertext >>
    # The HMAC is computed over << kdfAesIv, kdfMacIv, aesiv, [32 zero bytes], ciphertext >>
    tMac=`(
        hex_to_binary $gCryptoVersionByteHex;
        hex_to_binary $tFileType;
        hex_to_binary $tKdfAesIv;
        hex_to_binary $tKdfMacIv;
        hex_to_binary $tAesIv;
        hex_to_binary $tMac;
        if [ "$pInFile" != "-" ]; then
            openssl enc -e -nosalt -$gCryptoAesMode -in "$pInFile" -iv $tAesIv -K $tAesKey; 
        else
            openssl enc -e -nosalt -$gCryptoAesMode -iv $tAesIv -K $tAesKey;
        fi) | tee >(cat >"$pOutFile") | crypto_hmac $tMacKey -hex`
      
    if [ $? -ne 0 ]; then
        echo "ERROR: The OpenSSL enc tool failed encrypting" >&2
        return 1
    fi
    
    echo "Computed MAC: $tMac" >&2
    
    local tOrigSize=`get_file_size "$pOutFile"`
    
    # Write in the actual MAC in the middle of the output file
    hex_to_binary $tMac | $ddCmd of="$pOutFile" obs=$gCryptoMacSize count=1 conv=notrunc oflag=seek_bytes seek=$(($gCryptoHeaderSize-$gCryptoMacSize)) 2>/dev/null
    
    # Checks that nothing went wrong and the bytes were written *in* not appended or prepended
    local tModifiedSize=`get_file_size "$pOutFile"`
        
    if [ "$tOrigSize" != "$tModifiedSize" ]; then
        echo "ERROR: Internal error, file size changed from $tOrigSize bytes to $tModifiedSize bytes after writing MAC to file" >&2
        return 1
    fi
    
    return 0
}

#
# $1 the input encrypted/ciphertext file
# $2 the output file where the decrypted plaintext will be stored or - for stdout
# $3 the password used to derive the AES key from 
#
crypto_aes_decrypt_file() {
    local pInFile="$1"
    local pOutFile="$2"
    local pPassword="$3"
    
    if [ "$pInFile" = "$pOutFile" ]; then
        echo "ERROR: Input and output file cannot be the same" >&2
        return 1
    fi
    
    local tSkipBytes=0
    local tVersionByte=`$ddCmd if="$pInFile" bs=1 count=1 iflag=skip_bytes skip=$tSkipBytes 2>/dev/null | binary_to_hex`
    if [ "$tVersionByte" != "$gCryptoVersionByteHex" ]; then
        echo "ERROR: Ciphertext file version (0x$tVersionByte) differs from this script's version (0x$gCryptoVersionByteHex)"
        return 1
    fi
    
    # the file type is stored as the first byte
    tSkipBytes=$(($tSkipBytes + 1))
    local tFileType=`$ddCmd if="$pInFile" bs=1 count=1 iflag=skip_bytes skip=$tSkipBytes 2>/dev/null | binary_to_hex`
    local tFileOrDir=
    if [ "$tFileType" = "00" ]; then
        echo "Type: file" >&2
        if [ -d "$pOutFile" ]; then
            pOutFile=`$readlinkCmd -f "$pOutFile"`/`basename "$pInFile"`.dec
            echo "Changed destination file to '$pOutFile' since you specified a directory"
        fi
        tFileOrDir="file"
    elif [ "$tFileType" = "01" ]; then
        echo "Type: directory" >&2
        tFileOrDir="directory"
    else
        echo "ERROR: Unknown encrypted content type (0x$tFileType)"
        return 1
    fi
 
    # the IV used in the KDF for obtaining the AES key
    tSkipBytes=$(($tSkipBytes + 1))
    local tKdfAesIv=`$ddCmd if="$pInFile" bs=$gCryptoKdfIvSize count=1 iflag=skip_bytes skip=$tSkipBytes 2>/dev/null | binary_to_hex`
    echo "KDF IV for AES key: $tKdfAesIv" >&2
    
    # the IV used in the KDF for obtaining the HMAC key
    tSkipBytes=$(($tSkipBytes + $gCryptoKdfIvSize))
    local tKdfMacIv=`$ddCmd if="$pInFile" bs=$gCryptoKdfIvSize count=1 iflag=skip_bytes skip=$tSkipBytes 2>/dev/null | binary_to_hex`
    echo "KDF IV for MAC key: $tKdfMacIv" >&2
    
    # the AES IV
    tSkipBytes=$(($tSkipBytes + $gCryptoKdfIvSize))
    local tAesIv=`$ddCmd if="$pInFile" bs=$gCryptoAesIvSize count=1 iflag=skip_bytes skip=$tSkipBytes 2>/dev/null | binary_to_hex`
    echo "AES IV: $tAesIv" >&2
    
    # the MAC over the KDF IVs, AES IV and ciphertext
    tSkipBytes=$(($tSkipBytes + $gCryptoAesIvSize))
    local tZeroes=0000000000000000000000000000000000000000000000000000000000000000
    local tMac=`$ddCmd if="$pInFile" bs=$gCryptoMacSize count=1 iflag=skip_bytes skip=$tSkipBytes 2>/dev/null | binary_to_hex`
    echo "Stored MAC: $tMac" >&2
    
    local tAesKey=`crypto_kdf "aes-$pPassword" $tKdfAesIv`  # the AES encryption key
    local tMacKey=`crypto_kdf "hmac-$pPassword" $tKdfMacIv` # the HMAC integrity key
    
    echo "Decrypting $tFileOrDir with $((${#tAesKey}/2 * 8))-bit key and $((${#tAesIv}/2 * 8))-bit IV ..." >&2
   
    local tComputedMac=
    local tRet= 

    if [ "$tFileType" == "00" ]; then
        if [ -f "$pOutFile" ]; then
            echo "ERROR: Will NOT overwrite an existing encrypted file. Please delete '$pOutFile' first." >&2
            return 1
        fi
        
        tComputedMac=`(
            hex_to_binary $tVersionByte;
            hex_to_binary $tFileType;
            hex_to_binary $tKdfAesIv; 
            hex_to_binary $tKdfMacIv;
            hex_to_binary $tAesIv; 
            hex_to_binary $tZeroes;
            $ddCmd if="$pInFile" iflag=skip_bytes skip=$gCryptoHeaderSize 2>/dev/null \
             | tee >(openssl enc -d -nosalt -$gCryptoAesMode -out "$pOutFile" -iv $tAesIv -K $tAesKey) ) | crypto_hmac $tMacKey -hex`
             
        tRet=$?
    else
        local tTempMacFile=`mktemp`

        mkdir -p "$pOutFile"
        
        ( hex_to_binary $tVersionByte;
        hex_to_binary $tFileType;
        hex_to_binary $tKdfAesIv;
        hex_to_binary $tKdfMacIv;
        hex_to_binary $tAesIv; 
        hex_to_binary $tZeroes;
        $ddCmd if="$pInFile" iflag=skip_bytes skip=$gCryptoHeaderSize 2>/dev/null ) \
            | tee >(crypto_hmac $tMacKey -hex >$tTempMacFile) | tail -c +$(($gCryptoHeaderSize+1)) \
            | openssl enc -d -nosalt -$gCryptoAesMode -iv $tAesIv -K $tAesKey | tar xz -C "$pOutFile"

        tRet=$?
        
        tComputedMac=`cat $tTempMacFile` 
        rm $tTempMacFile
    fi

    if [ $tRet -ne 0 ]; then
        echo "ERROR: The OpenSSL enc tool failed decrypting" >&2
        return 1
    fi
    
    echo "Computed MAC: $tComputedMac" >&2
    
    if [ "$tMac" != "$tComputedMac" ]; then
        echo "ERROR: Stored MAC '$tMac' did not match file's actual MAC '$tComputedMac'" >&2
        return 1
    fi
}

#
# $1 the directory to encrypt
# $2 the output file where the encrypted directory will be stored
# $3 the password used to derive the AES key from 
#
crypto_aes_encrypt_dir() {
    local pInputDir="$1"
    local pOutputFile="$2"
    local pPassword="$3"

    if [ ! -d "$pInputDir" ]; then
        echo "ERROR: '$pInputDir' is not a directory!" >&2
        return 1
    fi

    local tParentDir=`dirname "$pInputDir"`
    local tDirName=`basename "$pInputDir"`

    (
        cd "$tParentDir";
        tar cz "$tDirName" | crypto_aes_encrypt_file - "$pOutputFile" "$pPassword"
    ) | cat
}
