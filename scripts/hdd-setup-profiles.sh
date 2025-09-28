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

# --- Поиск доступных дисков ---
info "$(say hdd_detect)"

ALL_DISKS=($(lsblk -ndo NAME,TYPE | awk '$2=="disk"{print $1}'))
AVAILABLE_DISKS=()

for d in "${ALL_DISKS[@]}"; do
    dev="/dev/$d"
    # проверяем, есть ли у диска смонтированные разделы как архивы
    if mount | grep -qE "^$dev.* (/(mnt/)?backups?|/(mnt/)?backup)(\s|$)"; then
        warn "$(printf "${MSG[${L}_skip_archive]}" "$dev")"
        continue
    fi
    AVAILABLE_DISKS+=("$d")
done

if [ ${#AVAILABLE_DISKS[@]} -eq 0 ]; then
    error "$(say no_partitioning)"
    exit 1
fi

# --- Выбор диска пользователем ---
echo "$(say sel_partition)"
select DISK in "${AVAILABLE_DISKS[@]}"; do
    [ -n "$DISK" ] && break
done

HDD="/dev/$DISK"
info "$(printf "${MSG[${L}_disk_selected]}" "$HDD")"

# --- Подтверждение удаления данных ---
read -rp "$(say warn_delete)" CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    info "$(say done_disks_users)"
    exit 0
fi

# --- Выбор диска пользователем ---
echo "$(say sel_partition)"
select DISK in "${AVAILABLE_DISKS[@]}"; do
    [ -n "$DISK" ] && break
done

HDD="/dev/$DISK"
info "$(printf "${MSG[${L}_disk_selected]}" "$HDD")"

# --- Размер диска ---
DISK_SIZE=$(lsblk -b -dn -o SIZE "$HDD")
DISK_SIZE_GB=$((DISK_SIZE / 1024 / 1024 / 1024))
info "$(say disk_size)" "$DISK_SIZE_GB GB"

FREE=$DISK_SIZE_GB

# --- Запрос размеров с проверкой ---
ask_size() {
    local USERNAME=$1
    local SIZE
    while true; do
        read -rp "$(printf "${MSG[${L}_user_size]}" "$USERNAME")" SIZE
        if (( SIZE < 1 )); then
            error "$(say error_min_size)"
            continue
        fi
        if (( SIZE > FREE )); then
            error "$(say error_not_enough)"  # добавить в messages.sh
            continue
        fi
        break
    done
    echo "$SIZE"
}

# --- $EXISTING_USER ---
SIZE1=$(ask_size "$EXISTING_USER")
FREE=$((FREE - SIZE1))
info "$(say remaining)" "$FREE GB"

# --- $USER2 ---
read -p "Хотите ли создать второго пользователя ($USER2)? (y/n): " CREATE_USER2
if [[ "$CREATE_USER2" == "y" ]]; then
    SIZE2=$(ask_size "$USER2")
    FREE=$((FREE - SIZE2))
    info "$(say remaining)" "$FREE GB"
else
    SIZE2=0
fi

# --- $USER3 ---
read -p "Хотите ли создать третьего пользователя ($USER3)? (y/n): " CREATE_USER3
if [[ "$CREATE_USER3" == "y" ]]; then
    SIZE3=$(ask_size "$USER3")
    FREE=$((FREE - SIZE3))
    info "$(say remaining)" "$FREE GB"
else
    SIZE3=0
fi

# --- Создание таблицы разделов ---
parted -s "$HDD" mklabel gpt

START=1
PART=1

# Раздел для $EXISTING_USER
END=$((START + SIZE1))
parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
mkfs.ext4 "${HDD}${PART}"
mkdir -p "/mnt/hdd_home/$EXISTING_USER"
mount "${HDD}${PART}" "/mnt/hdd_home/$EXISTING_USER"
START=$END
PART=$((PART + 1))

# Раздел для $USER2 (если выбран)
if [[ "$CREATE_USER2" == "y" ]]; then
    END=$((START + SIZE2))
    parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
    mkfs.ext4 "${HDD}${PART}"
    mkdir -p "/mnt/hdd_home/$USER2"
    mount "${HDD}${PART}" "/mnt/hdd_home/$USER2"
    START=$END
    PART=$((PART + 1))
fi

# Раздел для $USER3 (если выбран)
if [[ "$CREATE_USER3" == "y" ]]; then
    END=$((START + SIZE3))
    parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
    mkfs.ext4 "${HDD}${PART}"
    mkdir -p "/mnt/hdd_home/$USER3"
    mount "${HDD}${PART}" "/mnt/hdd_home/$USER3"
    START=$END
    PART=$((PART + 1))
fi

echo "Разметка и монтирование завершены."
lsblk -f "$HDD"
mount | grep "/mnt/hdd_home"


add_fstab_entry() {
    local UUID="$1"
    local MOUNTPOINT="$2"
    local FSTYPE="${3:-ext4}"
    local OPTIONS="${4:-defaults}"
    local PASS="0 2"

    # если каталог существует — ищем свободное имя
    if [ -d "$MOUNTPOINT" ]; then
        local base="$MOUNTPOINT"
        local n=1
        while [ -d "$MOUNTPOINT" ]; do
            MOUNTPOINT="${base}${n}"
            n=$((n+1))
        done
        info "$(printf "${MSG[${L}_mountpoint_exists]}" "$MOUNTPOINT")"
    fi

    # создаём каталог
    sudo mkdir -p "$MOUNTPOINT"

    # проверка: нет ли уже записи с этим UUID или этим MOUNTPOINT
    if grep -q "UUID=$UUID" /etc/fstab || grep -q "[[:space:]]$MOUNTPOINT[[:space:]]" /etc/fstab; then
        warn "$(say fstab_exists)"
    else
        echo "UUID=$UUID  $MOUNTPOINT  $FSTYPE  $OPTIONS  $PASS" | sudo tee -a /etc/fstab
        ok "$(say fstab_added)" "$MOUNTPOINT"
    fi
}

add_fstab_entry "$UUID1" "/mnt/storage"
add_fstab_entry "$UUID2" "/home/$USER2"
add_fstab_entry "$UUID3" "/home/$USER3"

# --- Монтирование ---
sudo mount -a

# --- Проверка ---
df -h | grep -E "$EXISTING_USER|$USER2|$USER3" >&3


ok "$(say done_disks_users)"
info "$(say restore_hint)"

exit 0

