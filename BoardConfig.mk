# Copyright (C) 2025-2026 OrangeFox Recovery Project
# SPDX-License-Identifier: GPL-3.0-only
#
# BoardConfig for:
# Samsung Galaxy Tab A9 WiFi (SM-X110) - codename: gta9wifi
# SoC: MediaTek Helio G99 (MT6789)

DEVICE_PATH := device/samsung/gta9wifi

# Architecture
TARGET_ARCH                := arm64
TARGET_ARCH_VARIANT        := armv8-2a
TARGET_CPU_ABI             := arm64-v8a
TARGET_CPU_VARIANT         := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a76

# Platform
TARGET_BOOTLOADER_BOARD_NAME  := gta9wifi
TARGET_BOARD_PLATFORM         := mt6789
TARGET_BOARD_PLATFORM_GPU     := mali-g57mc2
BOARD_USES_QCOM_HARDWARE      := false

# Kernel / Recovery image
# NOTE: Replace prebuilt/kernel with the actual kernel for SM-X110
TARGET_PREBUILT_KERNEL        := $(DEVICE_PATH)/prebuilt/kernel
TARGET_KERNEL_ARCH            := $(TARGET_ARCH)
TARGET_KERNEL_HEADER_ARCH     := $(TARGET_ARCH)

# MediaTek Helio G99 (MT6789) kernel parameters
# NOTE: Verify these offsets from your device's boot image using unpackbootimg
BOARD_KERNEL_BASE           := 0x40078000
BOARD_KERNEL_PAGESIZE       := 2048
BOARD_RAMDISK_OFFSET        := 0x11088000
BOARD_KERNEL_TAGS_OFFSET    := 0x07c08000
BOARD_DTB_OFFSET            := 0x07c08000
BOARD_KERNEL_IMAGE_NAME     := kernel
BOARD_BOOT_HEADER_VERSION   := 2
BOARD_MKBOOTIMG_ARGS        += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS        += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS        += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_ARGS        += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS        += --pagesize $(BOARD_KERNEL_PAGESIZE)

# Kernel cmdline (MediaTek)
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2

# Generic kernel image (GKI)
BOARD_USES_GENERIC_KERNEL_IMAGE     := true
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := false

# Non-A/B device — dedicated recovery partition
BOARD_USES_RECOVERY_AS_BOOT :=
AB_OTA_UPDATER := false

# Use LZ4 ramdisk compression
BOARD_RAMDISK_USE_LZ4 := true

# Verified Boot (AVB)
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

# Allow for building with minimal manifest
ALLOW_MISSING_DEPENDENCIES             := true
BUILD_BROKEN_USES_NETWORK              := true
BUILD_BROKEN_DUP_RULES                 := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_MISSING_REQUIRED_MODULES  := true

# Partitions
# NOTE: Verify these sizes from your device:
#   adb shell cat /proc/partitions
#   adb shell ls -la /dev/block/by-name/
BOARD_FLASH_BLOCK_SIZE                := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE        := 67108864
BOARD_RECOVERYIMAGE_PARTITION_SIZE    := 67108864
BOARD_DTBOIMG_PARTITION_SIZE          := 8388608

BOARD_USES_METADATA_PARTITION := true
BOARD_HAS_NO_REAL_SDCARD := false

# Dynamic Partitions (Super)
# NOTE: Verify BOARD_SUPER_PARTITION_SIZE from your device:
#   adb shell cat /sys/block/dm-0/size  (or check /proc/partitions for super)
BOARD_SUPER_PARTITION_SIZE        := 6442450944
BOARD_SUPER_PARTITION_GROUPS      := samsung_dynamic_partitions
BOARD_SAMSUNG_DYNAMIC_PARTITIONS_SIZE := 6438256640
BOARD_SAMSUNG_DYNAMIC_PARTITIONS_PARTITION_LIST += \
    system \
    system_ext \
    product \
    vendor \
    odm

BOARD_PARTITION_LIST := $(call to-upper, $(BOARD_SAMSUNG_DYNAMIC_PARTITIONS_PARTITION_LIST))
$(foreach p, $(BOARD_PARTITION_LIST), $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := ext4))
$(foreach p, $(BOARD_PARTITION_LIST), $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))
$(foreach p, $(filter-out SYSTEM, $(BOARD_PARTITION_LIST)), $(eval BOARD_USES_$(p)IMAGE := true))

# Workaround for error copying vendor files to recovery ramdisk
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4

# Filesystems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USES_MKE2FS        := true

# Recovery
TARGET_SYSTEM_PROP := \
    $(DEVICE_PATH)/system.prop

TARGET_RECOVERY_FSTAB := \
    $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab

TARGET_BOARD_INFO_FILE := \
    $(DEVICE_PATH)/board-info.txt

TARGET_RECOVERY_PIXEL_FORMAT := RGBA_8888

# Debugging
TARGET_USES_LOGD := true
#TARGET_RECOVERY_DEVICE_MODULES += strace
#RECOVERY_BINARY_SOURCE_FILES   += $(TARGET_OUT_EXECUTABLES)/strace
