#!/bin/bash

set -e

scriptdir=$(readlink -f $(dirname $0))

cTxtGreen="\e[32m"
cTxtBoldGreen="\e[1;32m"
cTxtRed="\e[31m"
cTxtBoldRed="\e[1;31m"
cTxtBlue="\e[34m"
cTxtBoldBlue="\e[1;34m"
cTxtDefault="\e[0m"

repo_print_info() {
    local tStatus="${cTxtBoldRed}(updated successfully)"

    (
        cd "$1";
        if [ -d ".git" ]; then
            tOutput=`git pull --rebase 2>&1`
            if echo "$tOutput" | grep "Current branch .* is up to date" \
                2>&1 >/dev/null; then
                tStatus="${cTxtBoldGreen}(already up-to-date)"
            elif echo "$tOutput" | grep "Cannot pull with rebase: You have unstaged changes." 2>&1 >/dev/null; then
                tStatus="${cTxtBoldRed}(cannot pull, please stash changes first)"
            fi
            echo -n -e "${cTxtBoldGreen}Git $tStatus"
        elif [ -d ".svn" ]; then
            if [ -z "`svn update`" ]; then
                tStatus="${cTxtBoldGreen}(already up-to-date)"
            fi
            echo -n -e "${cTxtBoldBlue}SVN $tStatus"
        else
            echo -n -e "${cTxtBoldRed}unknown"
        fi
    )

    echo -e -n "${cTxtDefault}"
}

vRepoDir="$HOME/repos/"

echo "Working with repositories in '$vRepoDir'..."
echo

for d in `find "$vRepoDir" -maxdepth 1 -type d | grep -v "^$vRepoDir$"`; do
    echo "$d -> `repo_print_info $d`"
done
