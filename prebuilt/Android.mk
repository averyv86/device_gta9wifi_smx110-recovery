# Copyright (C) 2025-2026 OrangeFox Recovery Project
# SPDX-License-Identifier: Apache-2.0
#
# prebuilt/Android.mk for:
# Samsung Galaxy Tab A9 WiFi (SM-X110) - codename: gta9wifi
# SoC: MediaTek Helio G99 (MT6789)
#
# ============================================================
# IMPORTANT: You must provide the actual SM-X110 kernel files:
#
#   prebuilt/kernel
#       - Extract from stock Samsung firmware via Odin .tar.md5
#       - Or build from Samsung Open Source Release (OSS kernel):
#         https://opensource.samsung.com  (search: SM-X110)
#
#   prebuilt/vendor/lib/modules/<version>/*.ko
#       - Extract from the vendor_dlkm or vendor partition of
#         your SM-X110 stock firmware using:
#             adb pull /vendor/lib/modules /path/to/prebuilt/vendor/lib/modules/
#         Or extract from the vendor.img in the firmware archive.
#       - The module directory version (e.g. "5.10") must match
#         the kernel version: uname -r on the device.
#
#   prebuilt/vendor/lib/modules/<version>/modules.dep
#   prebuilt/vendor/lib/modules/<version>/modules.load.recovery
#       - depmod generates modules.dep; modules.load.recovery lists
#         modules to load at boot in order.
# ============================================================

LOCAL_PATH := $(call my-dir)

# Only install prebuilt modules if the kernel directory exists
ifneq ($(wildcard $(LOCAL_PATH)/vendor/lib/modules),)
include $(CLEAR_VARS)
    LOCAL_MODULE := vendor_kernel_prebuilts
    LOCAL_MODULE_TAGS := optional
    LOCAL_MODULE_CLASS := ETC
    LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)
    LOCAL_HOST_REQUIRED_MODULES := depmod
    LOCAL_POST_INSTALL_CMD += \
        mkdir -p $(TARGET_RECOVERY_ROOT_OUT)/vendor; \
        cp -rf $(LOCAL_PATH)/vendor $(TARGET_RECOVERY_ROOT_OUT)/; \
        echo "Installing vendor_kernel_prebuilts for gta9wifi";
include $(BUILD_PHONY_PACKAGE)
endif
