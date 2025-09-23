/etc/modprobe.d/rtw_8821ce.conf

options rtw88_core disable_lps_deep=y
options rtw88_pci disable_msi=y disable_aspm=y
options rtw_core disable_lps_deep=y
options rtw_pci disable_msi=y disable_aspm=y


/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf

[connection]
wifi.powersave = 2
