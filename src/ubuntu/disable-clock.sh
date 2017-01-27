echo "WARNING: This script will remove the clock from the taskbar, but keep the date!"

read -p "Proceed [y/N]? " ANS

if [ "$ANS" = "y" ]; then
    dconf write /com/canonical/indicator/datetime/time-format "'custom'"
    dconf write /com/canonical/indicator/datetime/custom-time-format "'%a %d %h'"
else
    exit
fi
