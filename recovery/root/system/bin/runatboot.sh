#!/system/bin/sh

# Copyright (C) 2025-2026 OrangeFox Recovery Project
# SPDX-License-Identifier: GPL-3.0-only
#
# runatboot.sh for:
# Samsung Galaxy Tab A9 WiFi (SM-X110) - codename: gta9wifi
# SoC: MediaTek Helio G99 (MT6789)

# Load touchscreen driver if it didn't load properly
MODULES_DIR="/vendor/lib/modules"

# NOTE: Update DRIVERS to match the actual touchscreen module name for SM-X110
DRIVERS="sec_touchscreen"

for d in $DRIVERS;
    do
        lsmod | grep -q "^$d" && continue
        path=$(find "$MODULES_DIR" -name "$d.ko" | head -n 1)
        if [ -f "$path" ]; 
            then 
                insmod "$path"
                echo "Force inserted module: $d" >> /tmp/recovery.log
        fi
done

exit 0
