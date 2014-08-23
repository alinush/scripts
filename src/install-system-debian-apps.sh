#!/bin/bash

# Remove a few of these: Rhythmbox
#echo "Removing some crappy apps..."
#sudo apt-get remove rhythmbox

# VLC, git, svn
echo "Installing some new apps..."
sudo apt-get install vim minicom subversion git libxss1 gedit-plugins build-essential vlc apt-file cpufreqd cpufrequtils eclipse eclipse-cdt virtualbox gpointing-device-settings
