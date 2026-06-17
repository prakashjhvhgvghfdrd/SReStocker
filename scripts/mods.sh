#!/bin/bash

: "${YELLOW:=\e[33m}"
: "${NC:=\e[0m}"

APPLY_MODS() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: APPLY_MODS <EXTRACTED_FIRM_DIR>"
        return 1
    fi
    local EXTRACTED_FIRM_DIR="$1"
    echo -e "${YELLOW}Applying Mods.${NC}"

    local MODS_SRC="$(pwd)/SReStocker/Mods/Apps"
    if [ ! -d "$MODS_SRC" ]; then
        echo "- Mods/Apps folder not found, skipping."
        return 0
    fi

    if [ -d "$MODS_SRC/system" ]; then
        echo "- Applying mod: system"
        cp -rfa "$MODS_SRC/system/." "$EXTRACTED_FIRM_DIR/system/system/"
    fi

    if [ -d "$MODS_SRC/product" ]; then
        echo "- Applying mod: product"
        cp -rfa "$MODS_SRC/product/." "$EXTRACTED_FIRM_DIR/product/"
    fi

    if [ -d "$MODS_SRC/system_ext" ]; then
        echo "- Applying mod: system_ext"
        cp -rfa "$MODS_SRC/system_ext/." "$EXTRACTED_FIRM_DIR/system_ext/"
    fi

    echo "- All mods applied."
}
