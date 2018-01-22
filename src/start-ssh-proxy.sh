#!/bin/bash

set -e

scriptdir=$(cd $(dirname $0); pwd -P)

if [ $# -lt 2 ]; then
    echo "Usage: `basename $0` <ssh-user@ssh-server> <port> [OPTIONS]"
    echo
    echo "Starts a SOCKS proxy on the specified server and port, secured via SSH."
    echo
    echo "OPTIONS:"
    echo " -b   runs in background mode"
    exit 1
fi

vServer=$1
vPort=$2

vBackground=
if [ "$3" == "-b" ]; then
    echo
    echo "Running in background as a daemon..."
    vBackground="-f"
fi

echo
echo "Starting SOCKS proxy secured via SSH on $vServer, accessible on local port $vPort ..."

echo

# $vBackground might start as a daemon with "-b"
# -D $vPort starts a SOCKS server on the specified port
# -q uses quiet mode
# -N means no commands will be sent to SSH server
# $vServer specifies user@server pair
set -x
ssh $vBackground    \
    -D $vPort       \
    -q              \
    -N              \
    $vServer        \
