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
:<<'DOC'
=============================================================
hdd-setup-profiles.sh — разметка HDD и создание пользователей
Part of Backup Kit — HDD setup and user creation with logging
MIT License — Copyright (c) 2025 Vladislav Krashevsky support ChatGPT
=============================================================
DOC

set -euo pipefail

# Подключаем файл с сообщениями (messages.sh)
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/messages.sh"

# --- Проверка root ---
if [[ $EUID -ne 0 ]]; then
    error "$(say run_sudo)"
    exit 1
fi

info "$(say hdd_start)"

# === Логирование ===
LOG_FILE="/mnt/backups/logs/hdd_setup_profiles_restore.log"
exec > >(tee -a "$LOG_FILE") 2>&1
exec 3>&1 4>&2
trap 'exec 1>&3 2>&4' EXIT
info "$(say log_enabled)" "$LOG_FILE"

# --- Список дисков ---
info "$(say hdd_start)"
lsblk -d -o NAME,SIZE,MODEL | grep -v loop >&3

read -rp "$(say prompt_disk)" DISK
HDD="/dev/$DISK"

if [[ ! -b "$HDD" ]]; then
    error "$(say error_no_disk)"
    exit 1
fi

# --- Подтверждение удаления данных ---
read -rp "$(say warn_delete)" CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    info "$(say done_disks_users)"
    exit 0
fi

# --- Пользователи ---
EXISTING_USER=$(logname)
read -rp "$(say prompt_user2)" USER2
read -rp "$(say prompt_user3)" USER3

# --- Размер диска ---
DISK_SIZE=$(lsblk -b -dn -o SIZE "$HDD")
DISK_SIZE_GB=$((DISK_SIZE / 1024 / 1024 / 1024))
info "$(say disk_size)" "$DISK_SIZE_GB GB"

# --- Запрос размеров разделов ---
read -rp "$(printf "${MSG[${L}_user_size]}" "$EXISTING_USER")" SIZE1
FREE=$((DISK_SIZE_GB - SIZE1))
info "$(say remaining)" "$FREE GB"

read -rp "$(printf "${MSG[${L}_user_size]}" "$USER2")" SIZE2
FREE=$((FREE - SIZE2))
info "$(say remaining)" "$FREE GB"

read -rp "$(printf "${MSG[${L}_user_size]}" "$USER3")" SIZE3
FREE=$((FREE - SIZE3))
info "$(say remaining)" "$FREE GB"

if (( FREE < 0 )); then
    error "$(say error_size)"
    exit 1
fi

# --- Создание таблицы разделов ---
info "$(say creating_partitions)"
parted -s "$HDD" mklabel gpt
parted -s "$HDD" mkpart primary ext4 1MiB "$((SIZE1))GiB"
parted -s "$HDD" mkpart primary ext4 "$((SIZE1))GiB" "$((SIZE1+SIZE2))GiB"
parted -s "$HDD" mkpart primary ext4 "$((SIZE1+SIZE2))GiB" 100%

# --- Форматирование ---
info "$(say formatting)"
mkfs.ext4 -F "${HDD}1"
mkfs.ext4 -F "${HDD}2"
mkfs.ext4 -F "${HDD}3"

# --- Получение UUID ---
UUID1=$(blkid -s UUID -o value "${HDD}1")
UUID2=$(blkid -s UUID -o value "${HDD}2")
UUID3=$(blkid -s UUID -o value "${HDD}3")

# --- Создание пользователей ---
for U in "$USER2" "$USER3"; do
    if ! id "$U" &>/dev/null; then
        info "$(say creating_user)" "$U"
        useradd -m "$U"
        echo "$U:password" | chpasswd
        ok "$(say creating_user)" "$U (password='password')"
    else
        info "$(say user_exists)"
    fi
done

# --- Настройка /etc/fstab ---
info "$(say hdd_start)"
add_fstab_entry() {
    local UUID=$1
    local MOUNTPOINT=$2
    local FS=ext4
    local OPTS="defaults"
    local PASS="0 2"

    if grep -q "UUID=$UUID" /etc/fstab || grep -q "[[:space:]]$MOUNTPOINT[[:space:]]" /etc/fstab; then
        info "$(say fstab_exists)"
    else
        echo "UUID=$UUID $MOUNTPOINT $FS $OPTS $PASS" >> /etc/fstab
        ok "$(say fstab_added)" "$MOUNTPOINT"
    fi
}

# add_fstab_entry "$UUID1" "/home/$EXISTING_USER"
add_fstab_entry "$UUID2" "/home/$USER2"
add_fstab_entry "$UUID3" "/home/$USER3"

# --- Монтирование ---
mount -a

# --- Проверка ---
df -h | grep -E "$EXISTING_USER|$USER2|$USER3" >&3

ok "$(say done_disks_users)"
info "$(say restore_hint)"

exit 0

