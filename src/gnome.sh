scriptdir=$(readlink -f $(dirname $0))

echo
echo "Restoring gnome settings..."
echo
echo "Disabling nautilus automount open..."
echo
gsettings set org.gnome.desktop.media-handling automount-open false || :
gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action blank || :
gsettings set org.gnome.settings-daemon.plugins.power lid-close-battery-action blank || :
gsettings set org.gnome.settings-daemon.plugins.power lid-close-suspend-with-external-monitor false || :
