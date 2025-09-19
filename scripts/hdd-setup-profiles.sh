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
Author: Vladislav
=============================================================
DOC

set -euo pipefail

# === Цвета ===
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

ok()      { echo -e "${GREEN}[OK]${NC} $*"; }
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# === Двуязычные сообщения ===
declare -A MSG=(
  [ru_start]="Запуск разметки HDD и создания пользователей..."
  [en_start]="Starting HDD setup and user creation..."

  [ru_error_root]="Скрипт нужно запускать от root"
  [en_error_root]="Script must be run as root"

  [ru_log_enabled]="Логирование включено. Подробный лог: "
  [en_log_enabled]="Logging enabled. Detailed log: "

  [ru_prompt_disk]="Введите имя HDD (например, sdb): "
  [en_prompt_disk]="Enter HDD name (e.g., sdb): "

  [ru_error_no_disk]="Устройство не найдено!"
  [en_error_no_disk]="Device not found!"

  [ru_warn_delete]="⚠️ ВНИМАНИЕ: Все данные на диске будут удалены! Продолжить? (y/n): "
  [en_warn_delete]="⚠️ WARNING: All data on the disk will be erased! Continue? (y/n): "

  [ru_prompt_user2]="Введите имя второго пользователя: "
  [en_prompt_user2]="Enter name of second user: "

  [ru_prompt_user3]="Введите имя третьего пользователя: "
  [en_prompt_user3]="Enter name of third user: "

  [ru_disk_size]="Размер выбранного диска: "
  [en_disk_size]="Selected disk size: "

  [ru_remaining]="Остаток: "
  [en_remaining]="Remaining: "

  [ru_error_size]="Сумма указанных размеров превышает размер диска!"
  [en_error_size]="Sum of specified sizes exceeds disk size!"

  [ru_creating_partitions]="Создание таблицы разделов..."
  [en_creating_partitions]="Creating partition table..."

  [ru_formatting]="Форматирование разделов..."
  [en_formatting]="Formatting partitions..."

  [ru_creating_user]="Создаю пользователя "
  [en_creating_user]="Creating user "

  [ru_user_exists]="Пользователь уже существует."
  [en_user_exists]="User already exists."

  [ru_fstab_exists]="fstab: запись уже существует, пропускаю."
  [en_fstab_exists]="fstab entry already exists, skipping."

  [ru_fstab_added]="fstab: добавлена запись для "
  [en_fstab_added]="fstab: added entry for "

  [ru_done]="Операция завершена. Диски смонтированы, пользователи настроены."
  [en_done]="Operation completed. Disks mounted, users configured."

  [ru_restore_hint]="Для восстановления пользовательских данных используйте rsync-restore-userdata.sh"
  [en_restore_hint]="To restore user data, use rsync-restore-userdata.sh"
)

# === Выбор языка ===
L=${LANG_CHOICE:-ru}

say() {
    local key="$1"
    echo -e "${MSG[${L}_$key]}${2:-}"
}

info_key()  { info "$(say "$1" "$2")"; }
ok_key()    { ok "$(say "$1" "$2")"; }
warn_key()  { warn "$(say "$1" "$2")"; }
error_key() { error "$(say "$1" "$2")"; }

# === Логирование ===
LOG_FILE="/mnt/backups/logs/hdd_setup_profiles_restore.log"
exec > >(tee -a "$LOG_FILE") 2>&1
exec 3>&1 4>&2
trap 'exec 1>&3 2>&4' EXIT

info_key start
info_key log_enabled "$LOG_FILE"

# --- Проверка root ---
if [[ $EUID -ne 0 ]]; then
    error_key error_root
    exit 1
fi

# --- Список дисков ---
info_key ru_start
lsblk -d -o NAME,SIZE,MODEL | grep -v loop >&3

read -rp "$(say ru_prompt_disk)" DISK
HDD="/dev/$DISK"

if [[ ! -b "$HDD" ]]; then
    error_key ru_error_no_disk
    exit 1
fi

# --- Подтверждение удаления данных ---
read -rp "$(say ru_warn_delete)" CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    info_key ru_done
    exit 0
fi

# --- Пользователи ---
EXISTING_USER=$(logname)
read -rp "$(say ru_prompt_user2)" USER2
read -rp "$(say ru_prompt_user3)" USER3

# --- Размер диска ---
DISK_SIZE=$(lsblk -b -dn -o SIZE "$HDD")
DISK_SIZE_GB=$((DISK_SIZE / 1024 / 1024 / 1024))
info_key ru_disk_size "$DISK_SIZE_GB GB"

# --- Запрос размеров разделов ---
read -rp "Сколько GB выделить для $EXISTING_USER: " SIZE1
FREE=$((DISK_SIZE_GB - SIZE1))
info_key ru_remaining "$FREE GB"

read -rp "Сколько GB выделить для $USER2: " SIZE2
FREE=$((FREE - SIZE2))
info_key ru_remaining "$FREE GB"

read -rp "Сколько GB выделить для $USER3: " SIZE3
FREE=$((FREE - SIZE3))
info_key ru_remaining "$FREE GB"

if (( FREE < 0 )); then
    error_key ru_error_size
    exit 1
fi

# --- Создание таблицы разделов ---
info_key ru_creating_partitions
parted -s "$HDD" mklabel gpt
parted -s "$HDD" mkpart primary ext4 1MiB "$((SIZE1))GiB"
parted -s "$HDD" mkpart primary ext4 "$((SIZE1))GiB" "$((SIZE1+SIZE2))GiB"
parted -s "$HDD" mkpart primary ext4 "$((SIZE1+SIZE2))GiB" 100%

# --- Форматирование ---
info_key ru_formatting
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
        info_key ru_creating_user "$U"
        useradd -m "$U"
        echo "$U:password" | chpasswd
        ok_key ru_creating_user "$U (password='password')"
    else
        info_key ru_user_exists
    fi
done

# --- Настройка /etc/fstab ---
info_key ru_start
add_fstab_entry() {
    local UUID=$1
    local MOUNTPOINT=$2
    local FS=ext4
    local OPTS="defaults"
    local PASS="0 2"

    if grep -q "UUID=$UUID" /etc/fstab || grep -q "[[:space:]]$MOUNTPOINT[[:space:]]" /etc/fstab; then
        info_key ru_fstab_exists
    else
        echo "UUID=$UUID $MOUNTPOINT $FS $OPTS $PASS" >> /etc/fstab
        ok_key ru_fstab_added "$MOUNTPOINT"
    fi
}

add_fstab_entry "$UUID1" "/home/$EXISTING_USER"
add_fstab_entry "$UUID2" "/home/$USER2"
add_fstab_entry "$UUID3" "/home/$USER3"

# --- Монтирование ---
mount -a

# --- Проверка ---
df -h | grep -E "$EXISTING_USER|$USER2|$USER3" >&3

ok_key ru_done
info_key ru_restore_hint

exit 0

