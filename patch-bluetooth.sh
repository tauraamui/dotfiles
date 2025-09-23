#!/bin/bash

# Create rtw_8821ce.conf file
cat << EOF | sudo tee /etc/modprobe.d/rtw_8821ce.conf
options rtw88_core disable_lps_deep=y
options rtw88_pci disable_msi=y disable_aspm=y
options rtw_core disable_lps_deep=y
options rtw_pci disable_msi=y disable_aspm=y
EOF

echo "Created /etc/modprobe.d/rtw_8821ce.conf"

# Create default-wifi-powersave-on.conf file
cat << EOF | sudo tee /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
[connection]
wifi.powersave = 2
EOF

echo "Created /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf"
