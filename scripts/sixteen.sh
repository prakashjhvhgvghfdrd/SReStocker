#!/bin/bash

set -euo pipefail

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <STOCK_DEVICE> <TARGET_DEVICE> <OUTPUT_FILESYSTEM>"
    exit 1
fi

export STOCK_DEVICE="$1"
export TARGET_DEVICE="$2"
export OUTPUT_FILESYSTEM="$3"

VERSION="1"

export OUT_DIR="$(pwd)/OUT"
export WORK_DIR="$(pwd)/WORK"
export FIRM_DIR="$(pwd)/FIRMWARE"
export DEVICES_DIR="$(pwd)/SReStocker/Devices"
export VNDKS_COLLECTION="$(pwd)/SReStocker/vndks"

export BUILD_PARTITIONS="product,system_ext,system"

source "$(pwd)/scripts/debloat.sh"
source "$(pwd)/scripts/core_building.sh"
source "$(pwd)/scripts/selinux_engine.sh"
source "$(pwd)/scripts/mods.sh"
source "$(pwd)/scripts/floating_features.sh"
source "$(pwd)/scripts/build_prop.sh"

echo "Starting SReStocker Process..."
echo "Stock Device Config: $STOCK_DEVICE"
echo "Target Firmware Device: $TARGET_DEVICE"

EXTRACT_FIRMWARE "$FIRM_DIR/$TARGET_DEVICE"
EXTRACT_FIRMWARE_IMG "$FIRM_DIR/$TARGET_DEVICE"

APPLY_STOCK_CONFIG "$FIRM_DIR/$TARGET_DEVICE"

APPLY_STOCK_ROM_FLOATING_FEATURE

DEBLOAT "$FIRM_DIR/$TARGET_DEVICE"
FIX_SELINUX "$FIRM_DIR/$TARGET_DEVICE"
APPLY_CUSTOM_FEATURES "$FIRM_DIR/$TARGET_DEVICE"

APPLY_MODS "$FIRM_DIR/$TARGET_DEVICE"

APPLY_CUSTOM_FLOATING_FEATURES
APPLY_CUSTOM_BUILD_PROPS "$FIRM_DIR/$TARGET_DEVICE"

D_ID="$(grep -m1 '^ro.build.PDA=' "$FIRM_DIR/$TARGET_DEVICE/system/system/build.prop" | cut -d= -f2 | tr -d '\r')"

NEW_ID="${D_ID}_SReStocker"

BUILD_PROP "$FIRM_DIR/$TARGET_DEVICE" "system" "ro.build.display.id" "$NEW_ID"
BUILD_PROP "$FIRM_DIR/$TARGET_DEVICE" "product" "ro.build.display.id" "$NEW_ID"

BUILD_IMG "$FIRM_DIR/$TARGET_DEVICE" "$OUTPUT_FILESYSTEM" "$OUT_DIR"

echo "Process Complete! Output images are in $OUT_DIR"
