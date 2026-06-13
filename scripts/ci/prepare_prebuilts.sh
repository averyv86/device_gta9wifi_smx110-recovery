#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=${1:?env file is required}
DEVICE_TREE=${2:?device tree path is required}

# shellcheck disable=SC1090
source "$ENV_FILE"

PREBUILT_DIR="$DEVICE_TREE/prebuilt"
TMP_DIR="${RUNNER_TEMP:-/tmp}/orangefox-prebuilts"
KERNEL_TMP="$TMP_DIR/kernel"
MODULES_TMP="$TMP_DIR/modules"

rm -rf "$TMP_DIR"
mkdir -p "$KERNEL_TMP" "$MODULES_TMP" "$PREBUILT_DIR/vendor/lib/modules"

fetch_source() {
    local source=$1
    local destination_dir=$2
    local fallback_name=${3:-download.bin}
    local resolved file_name

    mkdir -p "$destination_dir"

    if [[ "$source" =~ ^https?:// ]]; then
        file_name=${source##*/}
        [[ -n "$file_name" ]] || file_name=$fallback_name
        curl --fail --location --retry 3 --silent --show-error "$source" -o "$destination_dir/$file_name"
        printf '%s\n' "$destination_dir/$file_name"
    else
        resolved="$source"
        if [[ ! "$resolved" = /* ]]; then
            resolved="$GITHUB_WORKSPACE/$resolved"
        fi
        if [[ ! -e "$resolved" ]]; then
            echo "Missing local source: $resolved" >&2
            return 1
        fi
        cp -R "$resolved" "$destination_dir/"
        file_name=$(basename "$resolved")
        printf '%s\n' "$destination_dir/$file_name"
    fi
}

extract_if_needed() {
    local source_path=$1
    local destination_dir=$2
    mkdir -p "$destination_dir"

    if [[ -d "$source_path" ]]; then
        cp -R "$source_path"/. "$destination_dir"/
        return
    fi

    case "$source_path" in
        *.tar)
            tar -xf "$source_path" -C "$destination_dir"
            ;;
        *.tar.gz|*.tgz)
            tar -xzf "$source_path" -C "$destination_dir"
            ;;
        *.tar.xz)
            tar -xJf "$source_path" -C "$destination_dir"
            ;;
        *.tar.zst|*.tzst)
            tar --use-compress-program=unzstd -xf "$source_path" -C "$destination_dir"
            ;;
        *.zip)
            unzip -q "$source_path" -d "$destination_dir"
            ;;
        *)
            cp "$source_path" "$destination_dir"/
            ;;
    esac
}

prepare_kernel() {
    local fetched kernel_path
    fetched=$(fetch_source "$CI_KERNEL_SOURCE" "$TMP_DIR/kernel-download" kernel.bin)
    extract_if_needed "$fetched" "$KERNEL_TMP"

    kernel_path=$(find "$KERNEL_TMP" -type f \( -name kernel -o -name 'Image*' \) | head -n 1 || true)
    if [[ -z "$kernel_path" ]]; then
        kernel_path=$(find "$KERNEL_TMP" -type f | head -n 1 || true)
    fi
    if [[ -z "$kernel_path" ]]; then
        echo "Unable to locate a kernel binary from $CI_KERNEL_SOURCE" >&2
        return 1
    fi

    cp "$kernel_path" "$PREBUILT_DIR/kernel"
}

prepare_modules() {
    local fetched
    fetched=$(fetch_source "$CI_MODULES_SOURCE" "$TMP_DIR/modules-download" modules.bin)
    extract_if_needed "$fetched" "$MODULES_TMP"

    local modules_root version_dir
    if [[ -d "$MODULES_TMP/vendor/lib/modules" ]]; then
        modules_root="$MODULES_TMP/vendor/lib/modules"
    elif [[ -d "$MODULES_TMP/lib/modules" ]]; then
        modules_root="$MODULES_TMP/lib/modules"
    elif find "$MODULES_TMP" -type f -name '*.ko' | grep -q .; then
        modules_root="$MODULES_TMP"
    else
        echo "Unable to locate kernel modules from $CI_MODULES_SOURCE" >&2
        return 1
    fi

    if [[ "$modules_root" = "$MODULES_TMP" ]]; then
        version_dir="$PREBUILT_DIR/vendor/lib/modules/$CI_VENDOR_MODULES_VERSION"
        mkdir -p "$version_dir"
        find "$MODULES_TMP" -maxdepth 1 -type f -name '*.ko' -exec cp {} "$version_dir"/ \;
    else
        cp -R "$modules_root"/. "$PREBUILT_DIR/vendor/lib/modules"/
        version_dir=$(find "$PREBUILT_DIR/vendor/lib/modules" -mindepth 1 -maxdepth 1 -type d | head -n 1 || true)
        if [[ -z "$version_dir" ]]; then
            version_dir="$PREBUILT_DIR/vendor/lib/modules/$CI_VENDOR_MODULES_VERSION"
            mkdir -p "$version_dir"
            find "$PREBUILT_DIR/vendor/lib/modules" -maxdepth 1 -type f -name '*.ko' -exec mv {} "$version_dir"/ \;
        fi
    fi

    if ! find "$version_dir" -maxdepth 1 -type f -name '*.ko' | grep -q .; then
        echo "No .ko modules were copied into $version_dir" >&2
        return 1
    fi

    if [[ ! -f "$version_dir/modules.load.recovery" ]]; then
        read -r -a module_list <<< "$CI_TW_LOAD_VENDOR_MODULES"
        printf '%s\n' "${module_list[@]}" > "$version_dir/modules.load.recovery"
    fi

    if command -v depmod >/dev/null 2>&1 && [[ ! -f "$version_dir/modules.dep" ]]; then
        depmod -b "$PREBUILT_DIR/vendor" "$(basename "$version_dir")" || true
    fi
}

prepare_kernel
prepare_modules
