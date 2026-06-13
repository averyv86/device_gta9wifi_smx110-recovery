#!/usr/bin/env python3
from __future__ import annotations

import argparse
import pathlib
import re
import shlex
import sys
from typing import Dict, Iterable

REQUIRED_KEYS = (
    "CI_ORANGEFOX_MANIFEST_URL",
    "CI_ORANGEFOX_MANIFEST_BRANCH",
    "CI_ORANGEFOX_SYNC_JOBS",
    "CI_DEVICE_TREE_PATH",
    "CI_LUNCH_TARGET",
    "CI_BUILD_TARGETS",
    "CI_CREATE_ODIN_PACKAGE",
    "CI_DEVICE_CODENAME",
    "CI_DEVICE_MODEL",
    "CI_BOARD_REQUIREMENT",
    "CI_TARGET_OTA_ASSERT_DEVICE",
    "CI_KERNEL_SOURCE",
    "CI_MODULES_SOURCE",
    "CI_VENDOR_MODULES_VERSION",
    "CI_BOARD_KERNEL_BASE",
    "CI_BOARD_KERNEL_PAGESIZE",
    "CI_BOARD_RAMDISK_OFFSET",
    "CI_BOARD_KERNEL_TAGS_OFFSET",
    "CI_BOARD_DTB_OFFSET",
    "CI_BOARD_BOOT_HEADER_VERSION",
    "CI_BOARD_KERNEL_CMDLINE",
    "CI_BOARD_BOOTIMAGE_PARTITION_SIZE",
    "CI_BOARD_RECOVERYIMAGE_PARTITION_SIZE",
    "CI_BOARD_DTBOIMG_PARTITION_SIZE",
    "CI_BOARD_SUPER_PARTITION_SIZE",
    "CI_BOARD_SAMSUNG_DYNAMIC_PARTITIONS_SIZE",
    "CI_TW_CUSTOM_CPU_TEMP_PATH",
    "CI_TW_BRIGHTNESS_PATH",
    "CI_TW_LOAD_VENDOR_MODULES",
)

HEX_KEYS = {
    "CI_BOARD_KERNEL_BASE",
    "CI_BOARD_RAMDISK_OFFSET",
    "CI_BOARD_KERNEL_TAGS_OFFSET",
    "CI_BOARD_DTB_OFFSET",
}
INT_KEYS = {
    "CI_ORANGEFOX_SYNC_JOBS",
    "CI_BOARD_KERNEL_PAGESIZE",
    "CI_BOARD_BOOT_HEADER_VERSION",
    "CI_BOARD_BOOTIMAGE_PARTITION_SIZE",
    "CI_BOARD_RECOVERYIMAGE_PARTITION_SIZE",
    "CI_BOARD_DTBOIMG_PARTITION_SIZE",
    "CI_BOARD_SUPER_PARTITION_SIZE",
    "CI_BOARD_SAMSUNG_DYNAMIC_PARTITIONS_SIZE",
}
BOOL_KEYS = {"CI_CREATE_ODIN_PACKAGE"}
PATH_KEYS = {"CI_TW_CUSTOM_CPU_TEMP_PATH", "CI_TW_BRIGHTNESS_PATH"}
MAKEFILE_UPDATES = {
    "BoardConfig.mk": {
        "BOARD_KERNEL_BASE": "CI_BOARD_KERNEL_BASE",
        "BOARD_KERNEL_PAGESIZE": "CI_BOARD_KERNEL_PAGESIZE",
        "BOARD_RAMDISK_OFFSET": "CI_BOARD_RAMDISK_OFFSET",
        "BOARD_KERNEL_TAGS_OFFSET": "CI_BOARD_KERNEL_TAGS_OFFSET",
        "BOARD_DTB_OFFSET": "CI_BOARD_DTB_OFFSET",
        "BOARD_BOOT_HEADER_VERSION": "CI_BOARD_BOOT_HEADER_VERSION",
        "BOARD_KERNEL_CMDLINE": "CI_BOARD_KERNEL_CMDLINE",
        "BOARD_BOOTIMAGE_PARTITION_SIZE": "CI_BOARD_BOOTIMAGE_PARTITION_SIZE",
        "BOARD_RECOVERYIMAGE_PARTITION_SIZE": "CI_BOARD_RECOVERYIMAGE_PARTITION_SIZE",
        "BOARD_DTBOIMG_PARTITION_SIZE": "CI_BOARD_DTBOIMG_PARTITION_SIZE",
        "BOARD_SUPER_PARTITION_SIZE": "CI_BOARD_SUPER_PARTITION_SIZE",
        "BOARD_SAMSUNG_DYNAMIC_PARTITIONS_SIZE": "CI_BOARD_SAMSUNG_DYNAMIC_PARTITIONS_SIZE",
    },
    "device.mk": {
        "TARGET_OTA_ASSERT_DEVICE": "CI_TARGET_OTA_ASSERT_DEVICE",
        "TW_CUSTOM_CPU_TEMP_PATH": "CI_TW_CUSTOM_CPU_TEMP_PATH",
        "TW_BRIGHTNESS_PATH": "CI_TW_BRIGHTNESS_PATH",
        "TW_LOAD_VENDOR_MODULES": "CI_TW_LOAD_VENDOR_MODULES",
    },
}


def parse_env_lines(lines: Iterable[str], source: str) -> Dict[str, str]:
    result: Dict[str, str] = {}
    for index, raw_line in enumerate(lines, start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise ValueError(f"{source}:{index}: expected KEY=VALUE")
        key, raw_value = line.split("=", 1)
        key = key.strip()
        if not re.fullmatch(r"[A-Z0-9_]+", key):
            raise ValueError(f"{source}:{index}: invalid key {key!r}")
        value = shlex.split(raw_value, posix=True)
        if len(value) > 1:
            parsed = " ".join(value)
        elif len(value) == 1:
            parsed = value[0]
        else:
            parsed = ""
        result[key] = parsed
    return result


def load_env_file(path: pathlib.Path) -> Dict[str, str]:
    return parse_env_lines(path.read_text(encoding="utf-8").splitlines(), str(path))


def merge_config(config_path: pathlib.Path, overrides_path: pathlib.Path | None) -> Dict[str, str]:
    values = load_env_file(config_path)
    if overrides_path and overrides_path.exists() and overrides_path.read_text(encoding="utf-8").strip():
        values.update(load_env_file(overrides_path))
    return values


def validate_config(values: Dict[str, str], repo_root: pathlib.Path) -> None:
    missing = [key for key in REQUIRED_KEYS if not values.get(key, "").strip()]
    if missing:
        raise ValueError("missing required config values: " + ", ".join(missing))

    for key in HEX_KEYS:
        if not re.fullmatch(r"0x[0-9A-Fa-f]+", values[key]):
            raise ValueError(f"{key} must be a hex value like 0x1234")

    for key in INT_KEYS:
        if not re.fullmatch(r"[0-9]+", values[key]):
            raise ValueError(f"{key} must be an integer")

    for key in BOOL_KEYS:
        if values[key].lower() not in {"true", "false"}:
            raise ValueError(f"{key} must be true or false")

    if not re.fullmatch(r"[A-Za-z0-9._/-]+", values["CI_DEVICE_CODENAME"]):
        raise ValueError("CI_DEVICE_CODENAME contains invalid characters")

    if not re.fullmatch(r"[A-Za-z0-9._/-]+", values["CI_DEVICE_MODEL"]):
        raise ValueError("CI_DEVICE_MODEL contains invalid characters")

    if not values["CI_KERNEL_SOURCE"].startswith(("http://", "https://", "/", ".")):
        raise ValueError("CI_KERNEL_SOURCE must be a direct URL or local path")

    if not values["CI_MODULES_SOURCE"].startswith(("http://", "https://", "/", ".")):
        raise ValueError("CI_MODULES_SOURCE must be a direct URL or local path")

    for key in PATH_KEYS:
        if not values[key].startswith("/"):
            raise ValueError(f"{key} must be an absolute device path")

    modules = values["CI_TW_LOAD_VENDOR_MODULES"].split()
    if not modules or any(not module.endswith(".ko") for module in modules):
        raise ValueError("CI_TW_LOAD_VENDOR_MODULES must be a space-separated list of .ko files")

    if not values["CI_ORANGEFOX_MANIFEST_URL"].startswith(("http://", "https://")):
        raise ValueError("CI_ORANGEFOX_MANIFEST_URL must be an HTTP(S) URL")

    board_info = (repo_root / "board-info.txt").read_text(encoding="utf-8")
    expected_board = values["CI_BOARD_REQUIREMENT"]
    if f"require board={expected_board}" not in board_info:
        raise ValueError("CI_BOARD_REQUIREMENT does not match board-info.txt")

    product_makefile = f"{values['CI_LUNCH_TARGET'].split('-', 1)[0]}.mk"
    product_mk = (repo_root / product_makefile).read_text(encoding="utf-8")
    if f"PRODUCT_MODEL  := {values['CI_DEVICE_MODEL']}" not in product_mk:
        raise ValueError("CI_DEVICE_MODEL does not match twrp_gta9wifi.mk")
    if f"PRODUCT_DEVICE := {values['CI_DEVICE_CODENAME']}" not in product_mk:
        raise ValueError("CI_DEVICE_CODENAME does not match twrp_gta9wifi.mk")


def write_shell_env(values: Dict[str, str], output_path: pathlib.Path) -> None:
    content = "".join(f"{key}={shlex.quote(value)}\n" for key, value in sorted(values.items()))
    output_path.write_text(content, encoding="utf-8")


def write_github_env(values: Dict[str, str], output_path: pathlib.Path) -> None:
    with output_path.open("a", encoding="utf-8") as handle:
        for key, value in sorted(values.items()):
            handle.write(f"{key}<<__EOF__\n{value}\n__EOF__\n")


def write_summary(values: Dict[str, str], output_path: pathlib.Path) -> None:
    lines = [
        "## OrangeFox CI build config",
        "",
        f"- Device codename: `{values['CI_DEVICE_CODENAME']}`",
        f"- Device model: `{values['CI_DEVICE_MODEL']}`",
        f"- OTA assert: `{values['CI_TARGET_OTA_ASSERT_DEVICE']}`",
        f"- Board requirement: `{values['CI_BOARD_REQUIREMENT']}`",
        f"- Lunch target: `{values['CI_LUNCH_TARGET']}`",
        f"- Build targets: `{values['CI_BUILD_TARGETS']}`",
        f"- Kernel source: `{values['CI_KERNEL_SOURCE']}`",
        f"- Modules source: `{values['CI_MODULES_SOURCE']}`",
        f"- Module version dir: `{values['CI_VENDOR_MODULES_VERSION']}`",
        f"- Create Odin package: `{values['CI_CREATE_ODIN_PACKAGE']}`",
        "",
        "### Applied overrides",
        "",
        "| Key | Value |",
        "| --- | --- |",
    ]
    for key in sorted(values):
        if key.startswith("CI_"):
            lines.append(f"| `{key}` | `{values[key]}` |")
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def replace_assignment(text: str, key: str, value: str, quoted: bool = False) -> str:
    replacement = f'{key} := "{value}"' if quoted else f"{key} := {value}"
    pattern = re.compile(rf"^(\s*{re.escape(key)}\s*:?=)\s*.*$", re.MULTILINE)
    new_text, count = pattern.subn(replacement, text, count=1)
    if count != 1:
        raise ValueError(f"failed to update {key}")
    return new_text


def apply_updates(values: Dict[str, str], repo_root: pathlib.Path) -> None:
    for relative_path, mapping in MAKEFILE_UPDATES.items():
        file_path = repo_root / relative_path
        text = file_path.read_text(encoding="utf-8")
        for make_key, config_key in mapping.items():
            text = replace_assignment(
                text,
                make_key,
                values[config_key],
                quoted=make_key in {"TW_CUSTOM_CPU_TEMP_PATH", "TW_BRIGHTNESS_PATH", "TW_LOAD_VENDOR_MODULES"},
            )
        file_path.write_text(text, encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="OrangeFox CI build config helper")
    subparsers = parser.add_subparsers(dest="command", required=True)

    for command in ("validate", "apply"):
        sub = subparsers.add_parser(command)
        sub.add_argument("--config", required=True, type=pathlib.Path)
        sub.add_argument("--overrides", type=pathlib.Path)
        sub.add_argument("--repo-root", required=True, type=pathlib.Path)
        sub.add_argument("--env-out", type=pathlib.Path)
        sub.add_argument("--github-env", type=pathlib.Path)
        sub.add_argument("--summary-out", type=pathlib.Path)
    return parser


def main(argv: Iterable[str]) -> int:
    args = build_parser().parse_args(argv)
    repo_root = args.repo_root.resolve()
    values = merge_config(args.config.resolve(), args.overrides.resolve() if args.overrides else None)
    validate_config(values, repo_root)
    if args.command == "apply":
        apply_updates(values, repo_root)
    if args.env_out:
        write_shell_env(values, args.env_out.resolve())
    if args.github_env:
        write_github_env(values, args.github_env.resolve())
    if args.summary_out:
        write_summary(values, args.summary_out.resolve())
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (FileNotFoundError, OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
