#!/system/bin/sh

# Copyright (C) 2025-2026 OrangeFox Recovery Project
# SPDX-License-Identifier: GPL-3.0-only
#
# virtual_torch.sh for:
# Samsung Galaxy Tab A9 WiFi (SM-X110) - codename: gta9wifi
#
# NOTE: This script is NOT used by default. The Samsung torch is controlled
# directly via /sys/class/leds/torch-sec1/brightness (OF_FL_PATH1).
# Only enable this via virtual_torch.rc if direct sysfs control fails.

TORCH_NODE=/sys/class/leds/torch-sec1/brightness
VIRTUAL_TORCH_DIR=/tmp/of_torch
CONTROL_NODE=$VIRTUAL_TORCH_DIR/brightness
PREVIOUS_VAL=-1

rm -rf $VIRTUAL_TORCH_DIR
mkdir -p $VIRTUAL_TORCH_DIR
echo 0 > $CONTROL_NODE

chmod 666 $CONTROL_NODE
echo 255 > $VIRTUAL_TORCH_DIR/max_brightness

while usleep 100000; do
    CURRENT_VAL=$(cat $CONTROL_NODE)

    [ -z "$CURRENT_VAL" ] || [ "$CURRENT_VAL" = "$PREVIOUS_VAL" ] && continue
    PREVIOUS_VAL=$CURRENT_VAL

    echo $CURRENT_VAL > $TORCH_NODE
done
