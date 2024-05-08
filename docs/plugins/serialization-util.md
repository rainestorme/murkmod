# Chromebook Serialization Utility

This plugin provides a wrapper around @kubisnax's [Chromebook Serialization Utility](https://github.com/kubisnax/chromebook_serialization_tool/).

When run, this plugin will:
- Prompt the user for confirmation (I don't want that liability)
- Set gbb_flags to 0x0
- Dump vpd logs
- Delete mlb_serial_number
- Delete stable_device_secret_DO_NOT_SHARE
- Delete Product_S/N 
- Shutdown/reboot the system

If you have a Chromebook that is definitely, 100% accounted for in your school and is definitely not "removed" from the premisies, then you can use this script to change its serial number and VPD data to make it unidentifiable.
