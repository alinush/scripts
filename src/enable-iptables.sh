#!/bin/bash

echo "Restoring rules..."
sudo iptables-restore < /etc/iptables.rules
