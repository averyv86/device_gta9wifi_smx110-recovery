# Copyright (C) 2025-2026 OrangeFox Recovery Project
# SPDX-License-Identifier: GPL-3.0-only
#
# Top-level product makefile for:
# Samsung Galaxy Tab A9 WiFi (SM-X110) - codename: gta9wifi

# Inherit from these configurations
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Inherit from device configuration
$(call inherit-product, device/samsung/gta9wifi/device.mk)

# Inherit from TWRP common configuration
$(call inherit-product, vendor/twrp/config/common.mk)

# Import OrangeFox specifics
$(call inherit-product, device/samsung/gta9wifi/fox_gta9wifi.mk)

## Device identifier
PRODUCT_DEVICE := gta9wifi
PRODUCT_BRAND  := Samsung
PRODUCT_MODEL  := SM-X110
PRODUCT_MANUFACTURER := Samsung
PRODUCT_NAME   := twrp_$(PRODUCT_DEVICE)
