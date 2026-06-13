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

## 🔴 Required: Add device-specific kernel and modules

This tree does **not** include the prebuilt kernel or kernel modules because they
must come from the actual SM-X110 device firmware. The build will fail without them.

### Step 1 — Get the kernel binary

**Option A – Extract from stock Samsung firmware:**
1. Download SM-X110 firmware from [SamFW](https://samfw.com) or [Frija](https://github.com/SlackingVeteran/frija)
2. Unpack the Odin `.tar.md5`: `tar xf SM-X110_*.tar.md5`
3. Decompress the AP image: `zstd -d AP_*.tar.zst | tar x` (or use `lz4 -d`)
4. Extract `boot.img` from the unpacked archive
5. Unpack boot image: `unpackbootimg -i boot.img -o boot_out/`
6. Copy the kernel: `cp boot_out/kernel prebuilt/kernel`

**Option B – Build from Samsung OSS kernel source:**
- Download kernel source from <https://opensource.samsung.com> (search: SM-X110)
- Follow the build instructions to produce an `Image` or `Image.gz-dtb`
- Copy the output to `prebuilt/kernel`

### Step 2 — Get kernel modules

```shell
# Boot the device into stock ROM with ADB enabled, then:
adb pull /vendor/lib/modules prebuilt/vendor/lib/modules
```

Or extract directly from `vendor.img` in the stock firmware.

The module directory version (e.g. `5.10`) must match `uname -r` on the device.

### Step 3 — Verify and update kernel boot parameters

After extracting `boot.img`, run:
```shell
unpackbootimg -i boot.img
```
Then update these values in `BoardConfig.mk` to match:
- `BOARD_KERNEL_BASE`
- `BOARD_RAMDISK_OFFSET`
- `BOARD_KERNEL_TAGS_OFFSET`
- `BOARD_DTB_OFFSET`
- `BOARD_KERNEL_PAGESIZE`

---

## Checklist
- [x] ADB
- [x] Decryption (FBE, Android 13)
- [x] Touchscreen (verify module name)
- [x] Flashing (via Odin or sideload)
- [x] MTP
- [x] Sideload
- [x] Backups (including EFS)
- [x] Filesystems/Mounts
- [x] MicroSD support
- [x] Cache, EFS, NVData, Protect partitions
- [x] Flashlight
- [ ] FastbootD (Samsung uses Download Mode — verify on device)

## ⚠️ Values to verify from your device

Before building, confirm these hardware-specific values from your actual device:

```shell
# List partition names and sizes
adb shell ls -la /dev/block/by-name/
adb shell cat /proc/partitions

# Verify kernel HAL service binary names for vendor init RCs
adb shell ls /vendor/bin/hw/

# Verify thermal and backlight sysfs paths
adb shell ls /sys/class/thermal/
adb shell ls /sys/class/backlight/

# Verify vendor module names for TW_LOAD_VENDOR_MODULES
adb shell find /vendor/lib/modules -name "*.ko" | xargs -I{} basename {}
```

Key values to verify/update:
| File | Value | How to find |
|---|---|---|
| `BoardConfig.mk` | Kernel base/offsets | `unpackbootimg -i boot.img` |
| `BoardConfig.mk` | `BOARD_BOOTIMAGE_PARTITION_SIZE` | `/proc/partitions` |
| `BoardConfig.mk` | `BOARD_SUPER_PARTITION_SIZE` | `/proc/partitions` |
| `device.mk` | `TW_CUSTOM_CPU_TEMP_PATH` | `ls /sys/class/thermal/*/temp` |
| `device.mk` | `TW_BRIGHTNESS_PATH` | `ls /sys/class/backlight/` |
| `device.mk` | `TW_LOAD_VENDOR_MODULES` | `find /vendor/lib/modules -name '*.ko'` |
| `recovery/root/vendor/etc/init/*.rc` | Binary names | `ls /vendor/bin/hw/` |

## GitHub Actions CI build

This repository now includes `.github/workflows/build-orangefox.yml` for manual OrangeFox builds.

### 1. Fill the single build config

Edit `.github/orangefox-build.env` with the device-specific values you already collected:
- kernel offsets and pagesize
- partition sizes
- thermal/backlight sysfs paths
- module list
- source locations for the kernel binary and vendor modules

The workflow also accepts per-run overrides, but the config file is the main interface.

### 2. Provide the required prebuilts

The workflow can populate `prebuilt/kernel` and `prebuilt/vendor/lib/modules` from either:
- a local file or directory path already present in the repository checkout, or
- a direct HTTP(S) URL such as a mirrored release asset

Expected config keys:
- `CI_KERNEL_SOURCE`
- `CI_MODULES_SOURCE`
- `CI_VENDOR_MODULES_VERSION`

If your modules source is a flat directory of `.ko` files, the workflow creates `prebuilt/vendor/lib/modules/<version>/` and writes `modules.load.recovery` from `CI_TW_LOAD_VENDOR_MODULES`.

### 3. Run the workflow

Open **Actions** → **Build OrangeFox Recovery** → **Run workflow**.

Available workflow inputs:
- `build_config_path`
- `build_config_overrides`
- `kernel_source`
- `modules_source`
- `orangefox_manifest_url`
- `orangefox_manifest_branch`
- `create_odin_package`
- `sync_jobs`

### 4. What the workflow does

The workflow will:
1. validate the config and guardrails
2. sync the OrangeFox source tree
3. copy this device tree into `device/samsung/gta9wifi`
4. apply your config to `BoardConfig.mk` and `device.mk`
5. prepare kernel and module prebuilts
6. run `lunch twrp_gta9wifi-ap2a-eng && mka adbd recoveryimage`
7. upload `recovery.img`, `orangefox-build.log`, `build-summary.md`, and optionally `recovery.tar` plus `recovery.tar.md5`

### 5. Guardrails

The workflow fails early if:
- required config keys are missing
- numeric or hex fields are malformed
- `gta9wifi` / `SM-X110` / `board-info.txt` checks do not match this tree
- the kernel or module sources cannot be resolved
- no kernel image or `.ko` modules can be found in the supplied sources

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

## ⚠️ Back up EFS before flashing anything!

The `/efs` partition contains your modem security keys. Losing it may permanently
break cellular functionality (not relevant for WiFi tablet, but the partition
still contains DRM/calibration data). OrangeFox will include it in the Quick Backup.

