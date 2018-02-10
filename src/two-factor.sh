#!/bin/bash

set -e

scriptdir=$(cd $(dirname $0); pwd -P)

. $scriptdir/shlibs/clipboard.sh

which oathtool &>/dev/null || { echo "ERROR: No 'oathtool' installed."; exit 1; } 

key=$1
if [ $# -lt 1 ]; then
    echo "Usage: $0 <hex-or-base64-otp-key>"
    exit 1
fi

# TODO: better way to check if key is hex- or base64-encoded
otp=`oathtool --totp $key || :`
if [ -z "$otp" ]; then
    otp=`oathtool --totp -b $key || :`
fi

if [ -z "$otp" ]; then
    echo "ERROR: Could not decode 2FA key (tried hex and base64)"
    exit 1
fi

echo "Copied OTP '$otp' to clipboard..."
setClipboard $otp
