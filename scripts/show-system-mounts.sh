#!/bin/bash
# =============================================================
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, subject to the following:
# The above copyright notice and this permission notice shall
# be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
# =============================================================
# show-system-mounts.sh — список точек монтирования и симлинков
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky
# =============================================================

set -euo pipefail

# --- Пути к библиотекам ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$BIN_DIR/lib"

# --- Подключение библиотек ---
source "$LIB_DIR/i18n.sh"
init_app_lang

source "$LIB_DIR/logging.sh"
source "$LIB_DIR/user_home.sh"
source "$LIB_DIR/real_user.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/context.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

# root / inhibit здесь не используем
require_root || return 1
# inhibit_run "$0" "$@"

# --- Функция для информации о дисках ---
show_disks_info() {
    for dev in /sys/block/sd*; do
        name=$(basename "$dev")
        rota=$(cat "$dev/queue/rotational")
        type=$([ "$rota" -eq 1 ] && echo "HDD" || echo "SSD")
        size=$(lsblk -dn -o SIZE "/dev/$name")
        model=$(cat "/sys/block/$name/device/model" 2>/dev/null || echo "Unknown")
        echo "$name: $type, $size, $model"
    done
}

# ----------------------------
# Output
# ----------------------------

echo
info show_physical_disks
show_disks_info

echo
info show_mounts_header
lsblk -o NAME,PATH,LABEL,MOUNTPOINT,FSTYPE,UUID -e 7,11

echo
info show_symlinks_header "$TARGET_HOME"
find "$TARGET_HOME" -maxdepth 1 -type l -printf "%f -> %l\n"

echo
info show_crontab_header
if [[ "$(id -u)" -eq 0 ]]; then
    crontab -l 2>/dev/null || echo_msg empty
else
    crontab -l 2>/dev/null || echo_msg empty
fi
echo

exit 0
