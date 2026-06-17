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
        echo "- Mods/Apps folder not found, skipping. (Download may have been skipped)"
        return 0
    fi

    local SYS_FOLDERS=("app" "priv-app" "etc" "lib" "lib64" "framework" "media" "overlay" "fonts" "usr")
    local PART_FOLDERS=("product" "system_ext")

    for mod in "$MODS_SRC"/*; do
        [ -d "$mod" ] || continue
        local mod_name="$(basename "$mod")"
        echo "- Applying mod: $mod_name"

        for folder in "${SYS_FOLDERS[@]}"; do
            if [ -d "$mod/$folder" ]; then
                mkdir -p "$EXTRACTED_FIRM_DIR/system/system/$folder"
                cp -rfa "$mod/$folder/." "$EXTRACTED_FIRM_DIR/system/system/$folder/"
            fi
        done

        for folder in "${PART_FOLDERS[@]}"; do
            if [ -d "$mod/$folder" ]; then
                mkdir -p "$EXTRACTED_FIRM_DIR/$folder"
                cp -rfa "$mod/$folder/." "$EXTRACTED_FIRM_DIR/$folder/"
            fi
        done
    done

    echo "- All mods applied."
}
