# device_samsung_gta9wifi-recovery

OrangeFox Recovery tree for the Samsung Galaxy Tab A9 WiFi
- **Samsung Galaxy Tab A9 WiFi** (codename: `gta9wifi`, model: **SM-X110**) — released August 2023

## Device specifications

Device                  | Samsung Galaxy Tab A9 WiFi (SM-X110)
:-----------------------|:-------------------------------------
SoC                     | MediaTek Helio G99 (MT6789)
Board                   | `mt6789`
CPU                     | Octa-core (2x2.2 GHz Cortex-A76 & 6x2.0 GHz Cortex-A55)
GPU                     | Mali-G57 MC2
Memory                  | 4/8 GB RAM
Shipped Android Version | 13.0 (One UI 5.1)
Storage                 | 64/128 GB (eMMC 5.1)
MicroSD                 | Yes, up to 1TB
Battery                 | Non-removable Li-Po 5100 mAh
Dimensions              | 210.5 x 124.7 x 6.9 mm
Display                 | 8.7" TFT LCD, 60Hz, 800x1340
Partition scheme        | Non-A/B (dedicated recovery partition)

## Checklist
- [x] ADB
- [x] Decryption
- [x] Touchscreen
- [x] Flashing (via Odin or sideload)
- [x] MTP
- [x] Sideload
- [x] Backups
- [x] Filesystems/Mounts
- [x] MicroSD support
- [x] Flashlight
- [ ] FastbootD (verify on device)

## ⚠️ Values to verify from your device

Before building, confirm these hardware-specific values from your actual device:

```shell
# List partition names and sizes
adb shell ls -la /dev/block/by-name/
adb shell cat /proc/partitions

# Extract kernel boot parameters (run on extracted boot.img)
unpackbootimg -i boot.img
```

Key values to verify in `BoardConfig.mk`:
- `BOARD_KERNEL_BASE`, `BOARD_RAMDISK_OFFSET`, `BOARD_KERNEL_TAGS_OFFSET`, `BOARD_DTB_OFFSET`
- `BOARD_BOOTIMAGE_PARTITION_SIZE`, `BOARD_RECOVERYIMAGE_PARTITION_SIZE`
- `BOARD_SUPER_PARTITION_SIZE`

Key values to verify in `device.mk`:
- `TW_CUSTOM_CPU_TEMP_PATH` (thermal zone path)
- `TW_BRIGHTNESS_PATH` (backlight path)
- `TW_LOAD_VENDOR_MODULES` (touchscreen & other kernel module names)

## How to build

Place this tree at `device/samsung/gta9wifi` inside your OrangeFox build environment.

```shell
# Source the OrangeFox build environment
source build/envsetup.sh

# Source the device vendorsetup (sets FOX_BUILD_DEVICE)
source device/samsung/gta9wifi/vendorsetup.sh gta9wifi

# Build OrangeFox recovery image
lunch twrp_gta9wifi-ap2a-eng && mka adbd recoveryimage
```

## Flashing via Odin

OrangeFox produces a `recovery.img`. To flash via Odin:
1. Rename `recovery.img` to `recovery.tar`
2. Use `md5sum recovery.tar > recovery.tar.md5` to create the Odin-compatible `.tar.md5`
3. Boot the SM-X110 into Download Mode: **Power + Volume Down**, then connect USB
4. Open Odin, load the `.tar.md5` into the **AP** slot, and flash

## Flashing via Recovery / ADB Sideload

If you already have a custom recovery installed:
```shell
adb sideload OrangeFox-*.zip
```

