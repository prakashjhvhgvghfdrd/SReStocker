# SReStocker (sixteen)

**SReStocker** is a bash-based pipeline that ports a Samsung "stock" device
configuration (build props, `floating_feature.xml`, SELinux policy, VNDK,
debloat rules) onto another device's firmware, then rebuilds flashable
`system` / `system_ext` / `product` images. This branch, **sixteen**, targets
firmware built on **One UI 8 / Android 16**.

In short: give it a firmware zip for `TARGET_DEVICE` and a known-good config
for `STOCK_DEVICE`, and it produces a "ported" build with the stock device's
personality applied — cleaned up, debloated, and SELinux-patched so it boots.

> ⚠️ This is a low-level firmware modification tool. It downloads, unpacks,
> patches, and repacks Samsung firmware images. Use it only on devices and
> firmware you own or are authorized to modify, and always keep a way to
> restore stock firmware (Odin flashable stock firmware / device unbrick
> guide) before flashing anything built with this tool.

---

## How it works

```
DOWNLOAD_FIRMWARE  →  EXTRACT_FIRMWARE  →  EXTRACT_FIRMWARE_IMG
        │
        ▼
APPLY_STOCK_CONFIG (system_ext layout, stock overlays, per-device files)
        │
        ▼
APPLY_VNDK  →  APPLY_STOCK_ROM_FLOATING_FEATURE
        │
        ▼
DEBLOAT  →  FIX_SELINUX  →  APPLY_CUSTOM_FEATURES
        │
        ▼
APPLY_MODS  →  APPLY_CUSTOM_FLOATING_FEATURES  →  APPLY_CUSTOM_BUILD_PROPS
        │
        ▼
BUILD_IMG (erofs or ext4)  →  OUT/*.img
```

All of the above is orchestrated by [`scripts/sixteen.sh`](scripts/sixteen.sh)
and also runs automatically in CI via
[`.github/workflows/sixteen.yml`](.github/workflows/sixteen.yml).

### Key terms

| Term | Meaning |
|---|---|
| **STOCK_DEVICE** | The device whose *configuration* (build props, floating features, SELinux tweaks, overlays) you want to apply. Must have a folder under `SReStocker/Devices/`. |
| **TARGET_DEVICE** | The device model whose *firmware* you are actually rebuilding (its `AP_*.tar` is what gets downloaded and patched). |
| **SAMFW_URL** | A direct `.zip` download URL for the target device's firmware, e.g. from [samfw.com](https://samfw.com). |
| **OUTPUT_FILESYSTEM** | `erofs` or `ext4` — the filesystem used when repacking the final partition images. |

---

## Repository layout

```
SReStocker-sixteen/
├── scripts/
│   ├── sixteen.sh            # main entrypoint / orchestrator
│   ├── core_building.sh      # firmware download, extraction, image unpack/repack
│   ├── debloat.sh            # app + library + service removal
│   ├── selinux_engine.sh     # rule-driven SELinux policy patcher
│   ├── mods.sh                # applies SReStocker/Mods/Apps overlay (downloaded in CI)
│   ├── floating_features.sh  # SEC_FLOATING_FEATURE_* XML editor helpers
│   ├── build_prop.sh         # custom build.prop tweaks
│   ├── convert_to_ext4.sh    # f2fs → ext4 conversion helper
│   └── setup_directories.sh  # workspace scaffolding
├── rules/selinux/            # keyword/exact-match SELinux patch rules (editable, no code changes needed)
├── bin/                      # vendored native tools: apktool, erofs-utils, lpunpack/lpdump, make_ext4fs, py_scripts
├── SReStocker/
│   ├── Devices/<MODEL>/      # per-stock-device config + floating_feature.xml + Stock/ overlay files
│   └── vndks/<version>/      # donor VNDK system_ext payloads by Android/VNDK version
└── upload_gofile.sh          # uploads the final zip to GoFile (used by CI)
```

---

## Requirements

Run this on Linux (the CI workflow uses `ubuntu-24.04`). You'll need:

```
p7zip-full lz4 android-sdk-libsparse-utils f2fs-tools fuse2fs fuse e2fsprogs
python3 python3-pip zipalign unzip openjdk-17-jdk jq wget vim-common attr xmlstarlet
```

Most steps also require **root** (loop mounts, `chown`), so local runs use
`sudo bash scripts/sixteen.sh ...`.

---

## Usage

### Option A — GitHub Actions (recommended)

1. Go to **Actions → SReStocker Sixteen → Run workflow**.
2. Fill in:
   - `STOCK_DEVICE` — pick from the dropdown (currently `SM-A135F`).
   - `TARGET_DEVICE` — the model whose firmware you're rebuilding, e.g. `SM-S711B`.
   - `SAMFW_URL` — a direct firmware `.zip` URL for `TARGET_DEVICE`.
   - `OUTPUT_FILESYSTEM` — `erofs` or `ext4`.
   - `COMPRESS_IMG_TO_XZ` — optional, shrinks the release download.
3. On success, the workflow creates a GitHub Release with a GoFile download
   link containing `system.img`, `system_ext.img`, and `product.img`.

### Option B — Local run

```bash
git clone <this repo>
cd SReStocker-sixteen

# fetch the external Mods/Apps overlay (optional, only needed if you use APPLY_MODS)
mkdir -p SReStocker/Mods
curl -Lf -o apps.zip https://github.com/Xiatsuma/SReStocker-Mods/releases/download/v3.0/apps.zip
unzip -q apps.zip -d SReStocker/Mods && mv SReStocker/Mods/apps SReStocker/Mods/Apps

bash scripts/setup_directories.sh FIRMWARE WORK OUT

export SAMFW_URL="https://example.com/direct/firmware.zip"
source scripts/core_building.sh
DOWNLOAD_FIRMWARE "SM-S711B" "FIRMWARE"

sudo bash scripts/sixteen.sh SM-A135F SM-S711B erofs
```

Output images land in `OUT/`.

---

## Adding a new STOCK_DEVICE

1. Create `SReStocker/Devices/<MODEL>/`.
2. Add a `config` file:
   ```
   STOCK_HAS_AB_SLOT=FALSE
   STOCK_VNDK_VERSION=33
   STOCK_HAS_SEPARATE_SYSTEM_EXT=FALSE
   STOCK_DVFS_FILENAME=dvfs_policy_...
   ```
3. Add the device's `floating_feature.xml` (pulled from its stock firmware,
   found at `system/system/etc/floating_feature.xml`).
4. Optionally add a `Stock/` folder — its contents are copied verbatim onto
   the target firmware root (overlays, camera data, etc. — see
   `APPLY_STOCK_CONFIG` in `core_building.sh`).
5. Optionally add an `extra/` folder — copied into `OUT/` as-is (untouched
   passthrough files for the final release).
6. Add `<MODEL>` to the `STOCK_DEVICE` dropdown in
   `.github/workflows/sixteen.yml` if you want it selectable in CI.

---

## Customizing behavior

- **Debloat list** — edit `DEBLOAT_APPS` / `PROTECTED_APP_TOKENS` in
  `scripts/debloat.sh`. Tokens are matched case-insensitively against
  app folder names; anything matching a `PROTECTED_APP_TOKENS` substring is
  never removed.
- **SELinux patches** — edit the plain-text rule files in `rules/selinux/`
  (no script changes needed):
  - `keywords_drop.list` — keyword-based line removal from the VNDK mapping `.cil`.
  - `exact_drop.list` — `relative/path|exact line` pairs to delete.
  - `append_if_missing.list` — `relative/path|exact line` pairs to add if absent.
- **Floating features** — add/edit calls to `UPDATE_FLOATING_FEATURE "KEY" "value"`
  or `DELETE_FLOATING_FEATURE "KEY"` inside `APPLY_CUSTOM_FLOATING_FEATURES`
  in `scripts/floating_features.sh`.
- **build.prop tweaks** — add `CUSTOM_BUILD_PROP` calls in
  `APPLY_CUSTOM_BUILD_PROPS` in `scripts/build_prop.sh`.
- **File overlays / mods** — drop files into
  `SReStocker/Mods/Apps/{system,system_ext,product}/` and `APPLY_MODS` copies
  them onto the corresponding partition.

---

## Known limitations

- Only `system`, `system_ext`, and `product` partitions are rebuilt by
  default (`BUILD_PARTITIONS` in `sixteen.sh`); `vendor`/`odm` are not
  currently repacked.
- `scripts/debloat.sh` is still being tuned — review the removal list before
  relying on it for a daily-driver build.
- Only one `STOCK_DEVICE` profile (`SM-A135F`) ships today; porting to a
  different chipset/VNDK family than what's in `SReStocker/vndks/` may
  require adding a new VNDK donor folder.
- GoFile is the only upload backend currently wired into CI.

---

## License

Licensed under the **PolyForm Noncommercial License 1.0.0** — see
[`LICENSE`](LICENSE). In short: free to use, modify, and distribute for any
**noncommercial** purpose (personal, educational, research, hobby, charitable,
governmental). Commercial use is not permitted without separate permission
from the licensor. See [`LICENSE`](LICENSE) for the full, authoritative terms.

Copyright (C) 2026 [Xiatsuma](https://github.com/Xiatsuma).
