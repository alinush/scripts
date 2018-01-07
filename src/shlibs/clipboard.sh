#!/bin/bash

function clearClipboard {
    if which xclip >/dev/null; then
        echo -n | xclip -sel clip
    elif which pbcopy >/dev/null; then
        echo -n | pbcopy
    else
        echo "ERROR: Neither xclip nor pbcopy are available."
        exit 1
    fi
}

function setClipboard {
    if which xclip >/dev/null; then
        echo -n "$1" | xclip -sel clip
    elif which pbcopy >/dev/null; then
        echo -n "$1" | pbcopy
    else
        echo "ERROR: Neither xclip nor pbcopy are available."
        exit 1
    fi
}
