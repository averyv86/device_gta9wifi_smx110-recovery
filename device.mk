# Copyright (C) 2025-2026 OrangeFox Recovery Project
# SPDX-License-Identifier: GPL-3.0-only
#
# device.mk for:
# Samsung Galaxy Tab A9 WiFi (SM-X110) - codename: gta9wifi
# SoC: MediaTek Helio G99 (MT6789)

DEVICE_PATH := device/samsung/gta9wifi

# Enable updating of APEXes
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

# Enable developer GSI keys
$(call inherit-product, $(SRC_TARGET_DIR)/product/developer_gsi_keys.mk)

# Configure emulated_storage.mk
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# OTA device(s)
TARGET_OTA_ASSERT_DEVICE := gta9wifi|SM-X110

# FastbootD support
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd

# Update engine (non-A/B: sideload only)
PRODUCT_PACKAGES += \
    update_engine_sideload

# API levels — SM-X110 shipped with Android 13 (API 33)
PRODUCT_SHIPPING_API_LEVEL  := 33
PRODUCT_TARGET_VNDK_VERSION := 33
BOARD_SHIPPING_API_LEVEL    := 33
SHIPPING_API_LEVEL          := 33

# Display — 8.7" TFT LCD, 800x1340, ~180 dpi
TARGET_SCREEN_WIDTH   := 800
TARGET_SCREEN_HEIGHT  := 1340
TARGET_SCREEN_DENSITY := 180

# Dynamic partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_BUILD_SUPER_PARTITION  := false

# Tablet with microSD slot
PRODUCT_CHARACTERISTICS := tablet

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)

# TWRP — General
TW_THEME                := portrait_hdpi
TW_DEFAULT_LANGUAGE     := en
TW_USE_TOOLBOX          := true
TW_INCLUDE_NTFS_3G      := true
TW_INCLUDE_RESETPROP    := true
TW_INCLUDE_LIBRESETPROP := true
TW_MAX_BRIGHTNESS       := 255
TW_DEFAULT_BRIGHTNESS   := 150
TW_EXTRA_LANGUAGES      := true
TW_EXCLUDE_APEX         := true
TW_INCLUDE_FASTBOOTD    := true
TWRP_INCLUDE_LOGCAT     := true
TW_INCLUDE_PYTHON       := true
TW_NO_SCREEN_BLANK      := true
TW_FRAMERATE            := 60

# Samsung uses Download Mode, not standard fastboot bootloader
TW_NO_REBOOT_BOOTLOADER  := true
TW_HAS_DOWNLOAD_MODE     := true

# Hardware paths for SM-X110
# NOTE: Verify these paths on your actual device
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone1/temp"
TW_BRIGHTNESS_PATH      := "/sys/class/backlight/panel/brightness"

# Touchscreen & vendor modules for MediaTek Helio G99
# NOTE: Update module names to match your actual kernel modules
TW_LOAD_VENDOR_MODULES := "sec_touchscreen.ko mt6789-afe-pcm.ko"

TW_EXCLUDE_DEFAULT_USB_INIT          := true
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true

TW_SUPPORT_INPUT_AIDL_HAPTICS        := false

# TWRP — Crypto (FBE on Android 13)
TW_INCLUDE_CRYPTO               := true
TW_INCLUDE_CRYPTO_FBE           := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true

# Set a future security patch date so OrangeFox can decrypt any ROM
PLATFORM_VERSION             := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)

PLATFORM_SECURITY_PATCH := 2127-12-31
VENDOR_SECURITY_PATCH   := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH     := $(PLATFORM_SECURITY_PATCH)
