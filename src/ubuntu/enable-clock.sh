echo "WARNING: This script will (re)enable the clock in the taskbar!"

read -p "Proceed [y/N]? " ANS

if [ "$ANS" = "y" ]; then
    dconf reset /com/canonical/indicator/datetime/time-format 
    dconf reset /com/canonical/indicator/datetime/custom-time-format 
else
    exit
fi
