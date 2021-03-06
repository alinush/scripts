#!/bin/bash

set -e

scriptdir=$(cd $(dirname $0); pwd -P)

if [ $# -lt 2 ]; then
    echo "Usage: `basename $0` <user@remote-ssh-server> <local-port> [OPTIONS]"
    echo
    echo "Starts a SOCKS proxy on the specified server and \"forwards\" it to the local port, secured via SSH."
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
    if [ -f ~/.ssh/id_rsa ]; then
        if head -n 2 ~/.ssh/id_rsa | tail -n 1 | grep "ENCRYPTED" &>/dev/null; then
            echo "ERROR: ~/.ssh/id_rsa is password protected, so cannot run in background mode."
            exit 1
        else
            vBackground="-f"
        fi
    else
        echo "ERROR: Need to ensure SSH secret key is not password-protected but no key file at ~/.ssh/id_rsa"
        exit 1
    fi
fi

echo
echo "Starting SOCKS proxy secured via SSH on $vServer, accessible on local port $vPort ..."

echo

# $vBackground might start as a daemon with "-b"
# -D $vPort starts a SOCKS server on the specified port
# -q uses quiet mode
# -N means no commands will be sent to SSH server
# $vServer specifies user@server pair
#set -x
#ssh                 \
#    $vBackground    \
#    -D $vPort       \
#    -q              \
#    -N              \
#    $vServer        \

# WARNING: Do not move $vBackground up because autossh will use it rather than ssh
autossh -M 20000    \
    -D $vPort       \
    -q              \
    -N              \
    $vBackground    \
    $vServer
