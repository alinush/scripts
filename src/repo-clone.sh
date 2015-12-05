#!/bin/sh

vRepo=$1
vUser='alinush'

if [ $# -ne 1 ]; then
    echo "Usage: $0 <repository-name> [OPTIONS]"
    echo
    echo "Clones the specified repository from your Gitlab or GitHub account"
    echo
    echo "OPTIONS:"
    echo "You can pass in any extra options you would normally pass to"
    echo "'git clone <reponame>', such as --recursive"
    exit 1
fi

# Discard first parameter
shift 1

echo; echo "Trying GitHub for '$vRepo'..."; echo
if ! git clone git@github.com:alinush/${vRepo}.git $@; then
    echo; echo "Trying GitLab for '$vRepo'..."; echo
    if git clone git@gitlab.com:alinush/${vRepo}.git $@; then
        echo; echo "Cloned '$vRepo' successfully!"; echo
    else
        echo; echo "Could not find '$vRepo' in GitHub nor in GitLab"; echo
    fi
else
    echo; echo "Cloned '$vRepo' successfully!"; echo
fi
