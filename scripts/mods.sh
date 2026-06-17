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

    for mod in "$MODS_SRC"/*; do
        [ -d "$mod" ] || continue
        local mod_name="$(basename "$mod")"
        echo "- Applying mod: $mod_name"

        if [ -d "$mod/system" ]; then
            cp -rfa "$mod/system/." "$EXTRACTED_FIRM_DIR/system/system/"
        fi

        if [ -d "$mod/product" ]; then
            cp -rfa "$mod/product/." "$EXTRACTED_FIRM_DIR/product/"
        fi

        if [ -d "$mod/system_ext" ]; then
            cp -rfa "$mod/system_ext/." "$EXTRACTED_FIRM_DIR/system_ext/"
        fi
    done

    echo "- All mods applied."
}
