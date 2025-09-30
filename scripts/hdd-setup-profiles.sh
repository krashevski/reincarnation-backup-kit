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
PS3="Введите номер для выбора диска: "
select DISK in "${AVAILABLE_DISKS[@]}"; do
    [ -n "$DISK" ] && break
done
HDD="/dev/$DISK"
info "$(printf "${MSG[${L}_disk_selected]}" "$HDD")"

# --- Размер диска ---
DISK_SIZE=$(lsblk -b -dn -o SIZE "$HDD")
DISK_SIZE_GB=$((DISK_SIZE / 1024 / 1024 / 1024))
info "$(say disk_size)" "$DISK_SIZE_GB GB"

# --- Подтверждение удаления данных ---
warn "$(say warn_delete)"
read -rp "$(say confirm_action)" CONFIRM

# --- $EXISTING_USER ---
EXISTING_USER=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 {print $1,$3}' | sort -k2 -n | head -n1 | cut -d" " -f1)

echo "Вы, "$EXISTING_USER", являетесь единственным пользователем диска "$DISK"."

# --- $USER2 ---
read -p "Хотите ли создать второго пользователя (USER2)? (y/n): " CREATE_USER2

if [[ "$CREATE_USER2" == "y" ]]; then
    read -p "Введите имя второго пользователя: " USER2
    echo "Второй пользователь будет: $USER2"
else
    USER2=""   # ← инициализация пустым значением
    echo "Второй пользователь не создаётся."
fi

# --- $USER3 ---
read -p "Хотите ли создать третьего пользователя (USER3)? (y/n): " CREATE_USER3

if [[ "$CREATE_USER3" == "y" ]]; then
    read -p "Введите имя третьего пользователя: " USER3
    echo "Третий пользователь будет: $USER3"
else
    USER3=""   # ← инициализация пустым значением
    echo "Третий пользователь не создаётся."
fi

# Задание размеров разделов для созданных пользователей
info "$(say disk_size)" "$DISK_SIZE_GB GB"
read -p "Ведите размер раздела для пользователя "$EXISTING_USER", GB: " SIZE1
FREE=$((DISK_SIZE_GB - SIZE1))
info "$(printf "$(say remaining)" "$FREE") GB"
if [[ $CREATE_USER2 == [Yy] && -n "$USER2" ]]; then
    read -rp "Введите размер раздела для пользователя "$USER2", GB: " SIZE2
    FREE=$((DISK_SIZE_GB - SIZE1 - SIZE2))
    info "$(printf "$(say remaining)" "$FREE") GB"
fi
if [[ "$CREATE_USER3" == [Yy] && -n "$USER3" ]]; then
    read -rp "Введите размер раздела для пользователя $USER3, GB: " SIZE3
    FREE=$((DISK_SIZE_GB - SIZE1 - SIZE2 - SIZE3))
    info "$(printf "$(say remaining)" "$FREE") GB"
fi

# --- Создание таблицы разделов ---
parted -s "$HDD" mklabel gpt

# --- Создание раздела ---
START=1
END=$((START + SIZE1))
PART=1

info "Создаём раздел для пользователя $EXISTING_USER"
parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
mkfs.ext4 "${HDD}${PART}"
info "Раздел для $EXISTING_USER создан: ${HDD}${PART} (${SIZE1} GB)"

# Подготовка к следующему разделу
START=$END
PART=$((PART + 1))

# --- Создание раздела для USER2 (если задан) ---
if [[ -n "$USER2" && -n "$SIZE2" ]]; then
    END=$((START + SIZE2))
    info "Создаём раздел для пользователя $USER2"
    parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
    mkfs.ext4 "${HDD}${PART}"
    info "Раздел для $USER2 создан: ${HDD}${PART} (${SIZE2} GB)"
    START=$END
    PART=$((PART + 1))
fi

# --- Создание раздела для USER3 (если задан) ---
if [[ -n "$USER3" && -n "$SIZE3" ]]; then
    END=$((START + SIZE3))
    info "Создаём раздел для пользователя $USER3"
    parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
    mkfs.ext4 "${HDD}${PART}"
    info "Раздел для $USER3 создан: ${HDD}${PART} (${SIZE3} GB)"
    START=$END
    PART=$((PART + 1))
fi

read -p "Пауза. Нажмите Enter для продолжения..."


# --- Проверка ---
df -h | grep -E "$EXISTING_USER|$USER2|$USER3" >&3


ok "$(say done_disks_users)"
info "$(say restore_hint)"

exit 0

