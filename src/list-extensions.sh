#!/bin/bash

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [-r] [directory]"
    exit
fi

recursive=0
if [ "$1" = "-r" ]; then
    recursive=1
    shift
fi

vDir=${1:-`pwd`}
vDir=$(cd "$vDir"; pwd -P)

if [ $recursive -eq 0 ]; then
    echo "Listing extensions in this directory only: $vDir"
    find "$vDir" -type f -maxdepth 1 | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort -u
else
    echo "Listing extensions in this directory and its subdirs: $vDir"
    find "$vDir" -type f | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort -u
fi
