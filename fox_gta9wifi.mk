# Copyright (C) 2025-2026 OrangeFox Recovery Project
# SPDX-License-Identifier: GPL-3.0-only
#
# OrangeFox recovery settings for:
# Samsung Galaxy Tab A9 WiFi (SM-X110) - codename: gta9wifi
# SoC: MediaTek Helio G99 (MT6789)

# OrangeFox maintainer
OF_MAINTAINER := averyv86

# Screen settings (8.7" TFT LCD, 800x1340)
OF_SCREEN_H := 1340
OF_STATUS_H := 72
OF_STATUS_INDENT_LEFT := 40
OF_STATUS_INDENT_RIGHT := 40
OF_ALLOW_DISABLE_NAVBAR := 0
OF_CLOCK_POS := 1
OF_OPTIONS_LIST_NUM := 9

# Quick backup (Boot partition)
OF_QUICK_BACKUP_LIST := /boot;

# Flashlight
OF_FL_PATH1 := /sys/class/leds/torch-sec1/brightness
OF_USE_GREEN_LED := 0

# Security (Disables MTP & ADB during password prompt)
OF_ADVANCED_SECURITY := 1

# HOS & Custom ROMs
OF_NO_TREBLE_COMPATIBILITY_CHECK := 1
OF_DEFAULT_KEYMASTER_VERSION := 4.1

# Non-A/B device with dedicated recovery partition
OF_AB_DEVICE_WITH_RECOVERY_PARTITION := 0
OF_ENABLE_ALL_PARTITION_TOOLS := 1

# Fix recovery issues caused by large splash images
OF_SPLASH_MAX_SIZE = 2048

# Ignore the loop block errors after flashing ZIPs
OF_LOOP_DEVICE_ERRORS_TO_LOG := 1

# Use legacy code to fix clock issues
OF_USE_LEGACY_TIME_FIXUP := 1

# Wipe /metadata after /data format
OF_WIPE_METADATA_AFTER_DATAFORMAT := 1

# Ensure that /sdcard is unbinded before /data repair/format
OF_UNBIND_SDCARD_F2FS := 1

# Force "F2FS" when formatting /data
OF_FORCE_DATA_FORMAT_F2FS := 1

# Force casefolding to avoid /data issues
OF_FORCE_CASEFOLDING := 1

# Use device mapper paths for dynamic partitions
FOX_RECOVERY_SYSTEM_PARTITION := "/dev/block/mapper/system"
FOX_RECOVERY_VENDOR_PARTITION := "/dev/block/mapper/vendor"
