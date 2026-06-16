#!/bin/bash
# =============================================================================
# SReStocker - A34 Debloat Script (Still under habding)
# =============================================================================

: "${YELLOW:=\e[33m}"
: "${NC:=\e[0m}"

REMOVE_FROM_METADATA() {
    local EXTRACTED_FIRM_DIR="$1"
    local DELETED_PATH="$2"

    local REL_PATH="${DELETED_PATH#$EXTRACTED_FIRM_DIR/}"

    local PARTITION
    if [[ "$REL_PATH" == system/* ]]; then
        PARTITION="system"
        REL_PATH="${REL_PATH#system/}"
    elif [[ "$REL_PATH" == product/* ]]; then
        PARTITION="product"
        REL_PATH="${REL_PATH#product/}"
    elif [[ "$REL_PATH" == system_ext/* ]]; then
        PARTITION="system_ext"
        REL_PATH="${REL_PATH#system_ext/}"
    elif [[ "$REL_PATH" == vendor/* ]]; then
        PARTITION="vendor"
        REL_PATH="${REL_PATH#vendor/}"
    elif [[ "$REL_PATH" == odm/* ]]; then
        PARTITION="odm"
        REL_PATH="${REL_PATH#odm/}"
    else
        return 0
    fi

    local FS_CONFIG="$EXTRACTED_FIRM_DIR/config/${PARTITION}_fs_config"
    local FILE_CONTEXTS="$EXTRACTED_FIRM_DIR/config/${PARTITION}_file_contexts"

    [ -f "$FS_CONFIG" ] && sed -i "\|^${REL_PATH} |d" "$FS_CONFIG" 2>/dev/null
    [ -f "$FILE_CONTEXTS" ] && sed -i "\|^/${REL_PATH} |d" "$FILE_CONTEXTS" 2>/dev/null
}

DEBLOAT_APPS=(
    "HMT" "PaymentFramework" "SamsungCalendar" "LiveTranscribe" "DigitalWellbeing"
    "Maps" "Duo" "Photos" "FactoryCameraFB" "WlanTest" "AssistantShell" "BardShell"
    "DuoStub" "GoogleCalendarSyncAdapter" "AndroidDeveloperVerifier" "AndroidGlassesCore"
    "SOAgent77" "YourPhone_Stub" "AndroidAutoStub" "SingleTakeService" "SamsungBilling"
    "AndroidSystemIntelligence" "GoogleRestore" "Messages" "SearchSelector" "AirGlance"
    "AirReadingGlass" "SamsungTTS" "ARCore" "ARDrawing" "ARZone" "BGMProvider"
    "BixbyWakeup" "BlockchainBasicKit" "Cameralyzer" "DictDiotekForSec"
    "EasymodeContactsWidget81" "Fast" "FBAppManager_NS" "FunModeSDK" "GearManagerStub"
    "KidsHome_Installer" "LinkSharing_v11" "LiveDrawing" "MAPSAgent" "MdecService"
    "MinusOnePage" "MoccaMobile" "Netflix_stub" "Notes40" "ParentalCare" "PhotoTable"
    "PlayAutoInstallConfig" "SamsungPassAutofill_v1" "SmartReminder" "SmartSwitchStub"
    "UnifiedWFC" "UniversalMDMClient" "VideoEditorLite_Dream_N" "VisionIntelligence3.7"
    "VoiceAccess" "VTCameraSetting" "WebManual" "WifiGuider" "KTAuth" "KTCustomerService"
    "KTUsimManager" "LGUMiniCustomerCenter" "LGUplusTsmProxy" "SketchBook"
    "SKTMemberShip_new" "SktUsimService" "TWorld" "AirCommand" "AppUpdateCenter"
    "AREmoji" "AREmojiEditor" "AuthFramework" "AutoDoodle" "AvatarEmojiSticker"
    "AvatarEmojiSticker_S" "Bixby" "BixbyInterpreter" "BixbyVisionFramework3.5"
    "DevGPUDriver-EX2200" "DigitalKey" "Discover" "DiscoverSEP" "EarphoneTypeC"
    "EasySetup" "FBInstaller_NS" "FBServices" "FotaAgent" "GalleryWidget"
    "GameDriver-EX2100" "GameDriver-EX2200" "GameDriver-SM8150" "HashTagService"
    "MultiControlVP6" "LedCoverService" "LinkToWindowsService" "LiveStickers"
    "MemorySaver_O_Refresh" "MultiControl" "OMCAgent5" "OneDrive_Samsung_v3"
    "OneStoreService" "SamsungCarKeyFw" "SamsungPass"
    "SettingsBixby" "SetupIndiaServicesTnC" "SKTFindLostPhone" "SKTHiddenMenu"
    "SKTMemberShip" "SKTOneStore" "SmartEye" "SmartPush" "SmartThingsKit"
    "SmartTouchCall" "SOAgent7" "SOAgent75" "SolarAudio-service" "SPPPushClient"
    "sticker" "StickerFaceARAvatar" "StoryService" "SumeNNService" "SVoiceIME"
    "SwiftkeyIme" "SwiftkeySetting" "SystemUpdate" "TADownloader" "TalkbackSE"
    "TaPackAuthFw" "TPhoneOnePackage" "TPhoneSetup" "UltraDataSaving_O" "Upday"
    "UsimRegistrationKOR" "YourPhone_P1_5" "AvatarPicker" "GpuWatchApp"
    "KT114Provider2" "KTHiddenMenu" "KTOneStore" "KTServiceAgent" "KTServiceMenu"
    "LGUGPSnWPS" "LGUHiddenMenu" "LGUOZStore" "SKTFindLostPhoneApp" "SmartPush_64"
    "SOAgent76" "TService" "vexfwk_service" "VexScanner" "LiveEffectService"
)

PROTECTED_APP_TOKENS=(
    "DeviceServices" "DeviceService"
    "Knox" "Security" "Fmm" "FindMyMobile"
    "SetupWizard" "Provision" "ManagedProvisioning"
    "TeleService" "MmsService" "CarrierConfig"
    "SystemUI" "Settings" "framework-res"
    "PackageInstaller" "PermissionController"
    "GoogleServicesFramework" "Phonesky"
    "SamsungCamera"
)

IS_PROTECTED_APP() {
    local app="$1"
    for token in "${PROTECTED_APP_TOKENS[@]}"; do
        [[ "$app" == *"$token"* ]] && return 0
    done
    return 1
}

REMOVE_PATH_IF_EXISTS() {
    local path="$1"
    local root="$2"
    if [[ -e "$path" ]]; then
        rm -rf "$path" || echo "[WARN] Failed to remove: $path"
        [ -n "$root" ] && REMOVE_FROM_METADATA "$root" "$path"
    fi
}

REMOVE_APP_DIRS() {
    local root="$1"
    local app_token="$2"

    local APP_DIRS=(
        "$root/system/system/app"
        "$root/system/system/priv-app"
        "$root/product/app"
        "$root/product/priv-app"
        "$root/system_ext/app"
        "$root/system_ext/priv-app"
        "$root/vendor/app"
        "$root/vendor/priv-app"
        "$root/odm/app"
        "$root/odm/priv-app"
        "$root/prism/app"
        "$root/prism/priv-app"
    )

    local removed=0
    for dir in "${APP_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r -d '' candidate; do
            REMOVE_PATH_IF_EXISTS "$candidate" "$root"
            removed=1
        done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -iname "*${app_token}*" -print0 2>/dev/null)
    done

    return $(( 1 - removed ))
}

REMOVE_APP_RESIDUALS() {
    local root="$1"
    local app_token="$2"

    local CONFIG_DIRS=(
        "$root/system/system/etc/permissions"
        "$root/system/system/etc/default-permissions"
        "$root/system/system/etc/sysconfig"
        "$root/product/etc/permissions"
        "$root/product/etc/default-permissions"
        "$root/product/etc/sysconfig"
        "$root/system_ext/etc/permissions"
        "$root/system_ext/etc/default-permissions"
        "$root/system_ext/etc/sysconfig"
        "$root/vendor/etc/permissions"
        "$root/vendor/etc/default-permissions"
        "$root/vendor/etc/sysconfig"
        "$root/odm/etc/permissions"
        "$root/odm/etc/default-permissions"
        "$root/odm/etc/sysconfig"
        "$root/prism/etc/permissions"
        "$root/prism/etc/default-permissions"
        "$root/prism/etc/sysconfig"
    )

    for cfg in "${CONFIG_DIRS[@]}"; do
        [[ -d "$cfg" ]] || continue
        while IFS= read -r -d '' f; do
            REMOVE_PATH_IF_EXISTS "$f" "$root"
        done < <(find "$cfg" -type f -iname "*${app_token}*.xml" -print0 2>/dev/null)
    done

    while IFS= read -r -d '' oat_dir; do
        REMOVE_PATH_IF_EXISTS "$oat_dir" "$root"
    done < <(find "$root" -type d -iname "*${app_token}*" -path "*/oat/*" -print0 2>/dev/null)
}

DEBLOAT_APPS_AND_RESIDUALS() {
    if [ "$#" -ne 1 ]; then
        echo -e "Usage: ${FUNCNAME[0]} <EXTRACTED_FIRM_DIR>"
        return 1
    fi

    local EXTRACTED_FIRM_DIR="$1"
    echo -e "- Debloating apps + related residuals (safe mode)."

    local removed_count=0
    local skipped_protected=0

    for app in "${DEBLOAT_APPS[@]}"; do
        if IS_PROTECTED_APP "$app"; then
            echo -e "  • Skip protected token: $app"
            skipped_protected=$((skipped_protected + 1))
            continue
        fi

        if REMOVE_APP_DIRS "$EXTRACTED_FIRM_DIR" "$app"; then
            echo -e "  • Removed app payloads for token: $app"
            removed_count=$((removed_count + 1))
        fi

        REMOVE_APP_RESIDUALS "$EXTRACTED_FIRM_DIR" "$app"
    done

    echo -e "  • Removed tokens: $removed_count"
    echo -e "  • Protected skips: $skipped_protected"
}

REMOVE_ESIM_FILES() {
    if [ "$#" -ne 1 ]; then
        echo -e "Usage: ${FUNCNAME[0]} <EXTRACTED_FIRM_DIR>"
        return 1
    fi

    local EXTRACTED_FIRM_DIR="$1"
    echo -e "- Removing ESIM files."
    local d="$EXTRACTED_FIRM_DIR"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/autoinstalls/autoinstalls-com.google.android.euicc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/default-permissions/default-permissions-com.google.android.euicc.xml" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/permissions/privapp-permissions-com.samsung.euicc.xml" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/permissions/privapp-permissions-com.samsung.android.app.esimkeystring.xml" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/permissions/privapp-permissions-com.samsung.android.app.telephonyui.esimclient.xml" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/privapp-permissions-com.samsung.android.app.telephonyui.esimclient.xml" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/sysconfig/preinstalled-packages-com.samsung.euicc.xml" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/sysconfig/preinstalled-packages-com.samsung.android.app.esimkeystring.xml" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/priv-app/EsimClient" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/priv-app/EsimKeyString" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/priv-app/EuiccService" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/priv-app/EuiccGoogle" "$d"
}

REMOVE_FABRIC_CRYPTO() {
    if [ "$#" -ne 1 ]; then
        echo -e "Usage: ${FUNCNAME[0]} <EXTRACTED_FIRM_DIR>"
        return 1
    fi

    local d="$1"
    echo -e "- Removing fabric crypto."
    REMOVE_PATH_IF_EXISTS "$d/system/system/bin/fabric_crypto" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/init/fabric_crypto.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/permissions/FabricCryptoLib.xml" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/vintf/manifest/fabric_crypto_manifest.xml" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/framework/FabricCryptoLib.jar" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/framework/oat/arm/FabricCryptoLib.odex" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/framework/oat/arm/FabricCryptoLib.vdex" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/framework/oat/arm64/FabricCryptoLib.odex" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/framework/oat/arm64/FabricCryptoLib.vdex" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/lib64/com.samsung.security.fabric.cryptod-V1-cpp.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/lib64/vendor.samsung.hardware.security.fkeymaster-V1-ndk.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/priv-app/KmxService" "$d"
}

REMOVE_DEBLOAT_LIBS() {
    if [ "$#" -ne 1 ]; then
        echo -e "Usage: ${FUNCNAME[0]} <EXTRACTED_FIRM_DIR>"
        return 1
    fi

    local d="$1"
    echo -e "- Removing debloated app libraries."

    REMOVE_PATH_IF_EXISTS "$d/system/lib/hidl_tlc_payment_comm_client.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib/libtlc_payment_comm.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib/libtlc_payment_direct_comm.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib/libtlc_payment_spay.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib/vendor.samsung.hardware.tlc.payment@1.0.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/hidl_tlc_payment_comm_client.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libtlc_payment_comm.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libtlc_payment_direct_comm.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libtlc_payment_spay.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/vendor.samsung.hardware.tlc.payment@1.0.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/lib/vendor.samsung.hardware.tlc.payment@1.0-impl.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/lib/vendor.samsung.hardware.tlc.payment@1.0.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/lib64/vendor.samsung.hardware.tlc.payment@1.0-impl.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/lib64/vendor.samsung.hardware.tlc.payment@1.0.so" "$d"

    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libSamsungAPVoiceEngine.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libVoiceCommandEngine.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libtensorflowlite_jni_voicecommand.so" "$d"

    REMOVE_PATH_IF_EXISTS "$d/system/lib/libvoicechanger.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libvoicechanger.so" "$d"

    REMOVE_PATH_IF_EXISTS "$d/system_ext/lib/libvoicerecognition.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system_ext/lib/libvoicerecognition_jni.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system_ext/lib64/libvoicerecognition.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system_ext/lib64/libvoicerecognition_jni.so" "$d"

    REMOVE_PATH_IF_EXISTS "$d/system/lib/libgfxgrab.gpuwatchapp.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib/libgpustat.gpuwatchapp.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib/libsysinfo.gpuwatchapp.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libgfxgrab.gpuwatchapp.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libgpustat.gpuwatchapp.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libsysinfo.gpuwatchapp.samsung.so" "$d"

    REMOVE_PATH_IF_EXISTS "$d/system/lib/libaudiomirroring_jni.audiomirroring.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libaudiomirroring_jni.audiomirroring.samsung.so" "$d"

    REMOVE_PATH_IF_EXISTS "$d/system/lib/libSDKMoireDetector.spenocr.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib/libSDKRecognitionOCR.spenocr.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib/libSDKRecognitionText.spensdk.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib/libSDKonnxruntime.spenocr.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libSDKMoireDetector.spenocr.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libSDKRecognitionOCR.spenocr.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libSDKRecognitionText.spensdk.samsung.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libSDKonnxruntime.spenocr.samsung.so" "$d"

    REMOVE_PATH_IF_EXISTS "$d/system/lib/libBarcodeReader.quram.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib/libSEF.quram.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib/libagifencoder.quram.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib/libimagecodec.quram.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libBarcodeReader.quram.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libSEF.quram.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libagifencoder.quram.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libimagecodec.quram.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/lib64/libsecjpegquram.so" "$d"

    REMOVE_PATH_IF_EXISTS "$d/vendor/lib64/hw/android.hardware.soundtrigger3-impl.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/lib64/hw/android.hardware.soundtrigger@2.3-impl.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/lib64/hw/sound_trigger.primary.default.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/lib/hw/android.hardware.soundtrigger3-impl.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/lib/hw/android.hardware.soundtrigger@2.3-impl.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/lib/hw/sound_trigger.primary.default.so" "$d"

    REMOVE_PATH_IF_EXISTS "$d/vendor/lib64/hw/android.hardware.renderscript@1.0-impl.so" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/lib/hw/android.hardware.renderscript@1.0-impl.so" "$d"
}

REMOVE_UNUSED_SERVICES() {
    if [ "$#" -ne 1 ]; then
        echo -e "Usage: ${FUNCNAME[0]} <EXTRACTED_FIRM_DIR>"
        return 1
    fi

    local d="$1"
    echo -e "- Removing unused init services."

    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/mtklog.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/md_monitor.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/bootperf.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/boringssl_self_test.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/loghidlvendorservice.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/atrace_categories.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/vendor_flash_recovery.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/eara-io-service.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/networksetting.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system_ext/etc/init/loghidlsysservice.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system_ext/etc/init/netdiag.rc" "$d"

    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/gbe.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/chipinfo_init.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/emservice.rc" "$d"

    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/vendor.samsung.hardware.tlc.payment@1.0-service.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/vendor.samsung.hardware.tlc.iccc-service.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/vendor.samsung.hardware.tlc.kg-service.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/vendor.samsung.hardware.tlc.mpos_tui@1.0-service.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/vendor.samsung.hardware.security.skpm-service.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/vendor.samsung.hardware.security.engmode@1.0-service.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/vendor.samsung.hardware.security.drk@2.0-service.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/vendor.samsung.hardware.security.hdcp.wifidisplay-default.rc" "$d"
    REMOVE_PATH_IF_EXISTS "$d/vendor/etc/init/wsm-service.rc" "$d"

    REMOVE_PATH_IF_EXISTS "$d/system/etc/init/audiomirroring.rc" "$d"
}

DEBLOAT() {
    if [ "$#" -ne 1 ]; then
        echo -e "Usage: ${FUNCNAME[0]} <EXTRACTED_FIRM_DIR>"
        return 1
    fi

    local EXTRACTED_FIRM_DIR="$1"
    local d="$EXTRACTED_FIRM_DIR"
    echo -e "${YELLOW}Debloating apps and files (deep safe mode).${NC}"

    DEBLOAT_APPS_AND_RESIDUALS "$d"
    REMOVE_ESIM_FILES "$d"
    REMOVE_FABRIC_CRYPTO "$d"
    REMOVE_DEBLOAT_LIBS "$d"
    REMOVE_UNUSED_SERVICES "$d"

    echo -e "- Deleting additional unnecessary files and folders."
    REMOVE_PATH_IF_EXISTS "$d/system/system/app"/SamsungTTS* "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/init/boot-image.bprof" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/init/boot-image.prof" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/etc/mediasearch" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/hidden" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/preload" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/priv-app/MediaSearch" "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/priv-app"/GameDriver-* "$d"
    REMOVE_PATH_IF_EXISTS "$d/system/system/tts" "$d"
    REMOVE_PATH_IF_EXISTS "$d/product/app/Gmail2/oat" "$d"
    REMOVE_PATH_IF_EXISTS "$d/product/app/Maps/oat" "$d"
    REMOVE_PATH_IF_EXISTS "$d/product/app/SpeechServicesByGoogle/oat" "$d"
    REMOVE_PATH_IF_EXISTS "$d/product/app/YouTube/oat" "$d"
    REMOVE_PATH_IF_EXISTS "$d/product/priv-app"/HotwordEnrollment* "$d"

    echo -e "- Cleaning metadata for debloated files..."
    local config_dir="$d/config"
    for fc in "$config_dir"/*_file_contexts; do
        [ -f "$fc" ] && sort -u "$fc" -o "$fc" 2>/dev/null
    done
    for fs in "$config_dir"/*_fs_config; do
        [ -f "$fs" ] && sort -u "$fs" -o "$fs" 2>/dev/null
    done

    echo -e "- Debloat complete"
}
