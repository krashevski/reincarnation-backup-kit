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

# --- systemd-inhibit ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="Running restore" "$0" "$@"
fi

# Подключаем файл с сообщениями (messages.sh)
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/messages.sh"

# --- Проверка root ---
if [ "$EUID" -ne 0 ]; then
    info "$(say script_restart)"
    exec sudo bash "$0" "$@"
fi

info "$(say hdd_start)"

# === Логирование ===
LOG_FILE="/mnt/backups/logs/hdd_setup_profiles.log"
exec > >(tee -a "$LOG_FILE") 2>&1
exec 3>&1 4>&2
trap 'exec 1>&3 2>&4' EXIT
info "$(printf "$(say log_enabled)" "$LOG_FILE")"

# --- Поиск доступных дисков ---
info "$(say hdd_detect)"

ALL_DISKS=($(lsblk -ndo NAME,TYPE | awk '$2=="disk"{print $1}'))
AVAILABLE_DISKS=()

for d in "${ALL_DISKS[@]}"; do
    dev="/dev/$d"
    safe_dev=$(printf '%s' "$dev" | sed 's/[.[\*^$()+?{|]/\\&/g')
    # проверяем, есть ли у диска смонтированные разделы как архивы
    if mount | grep -qE "^$dev.* (/(mnt/)?backups?|/(mnt/)?backup)(\\s|$)"; then
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
PS3="$(say select_disk)"
select DISK in "${AVAILABLE_DISKS[@]}"; do
    [ -n "$DISK" ] && break
done
HDD="/dev/$DISK"
info "$(printf "${MSG[${L}_disk_selected]}" "$HDD")"

# Проверка монтирования разделов на выбранном диске
# Проверка значения переменной
if [ -z "$HDD" ]; then
    error "Переменная HDD пуста!"
    exit 1
fi

info "$(printf "$(say check_mounts)" "$HDD")"

read -rp "$(say pause)"

ensure_disk_free() {
    local disk="$1"
    info "Освобождаем диск $disk..."

    # 1) Отключаем авто-монтирование GNOME (без фейлов, если нет gsettings)
    gsettings set org.gnome.desktop.media-handling automount false 2>/dev/null || true
    gsettings set org.gnome.desktop.media-handling automount-open false 2>/dev/null || true

    # 2) Отключаем swap и лениво размонтируем любые возможные точки монтирования
    swapoff "${disk}"* 2>/dev/null || true
    umount -l "${disk}"* 2>/dev/null || true

    # 3) Размонтируем через udisksctl все реальные разделы (если udisksctl доступен)
    if command -v udisksctl >/dev/null 2>&1; then
        for part in $(lsblk -ln -o PATH "$disk" | tail -n +2); do
            udisksctl unmount -b "$part" 2>/dev/null || true
        done
        # НЕ ДЕЛАЕМ power-off здесь — устройство должно остаться в /dev для parted/mkfs
    fi

    # 4) Завершаем процессы, удерживающие диск (fuser возвращает PIDs)
    local pids
    pids=$(fuser -km "$disk" 2>/dev/null || true)
    if [ -n "$pids" ]; then
        info "Завершены процессы, удерживавшие диск: $pids"
    else
        info "Процессов, удерживающих диск, не найдено."
    fi

    # 5) Синхронизируем и даём ядру время
    sync
    udevadm settle

    # 6) Пытаемся перечитать таблицу разделов
    if ! blockdev --rereadpt "$disk" 2>/dev/null; then
        partprobe "$disk" 2>/dev/null || true
    fi

    # 7) Финальная проверка — если всё ещё есть процессы, считаем диск занятым
    if fuser -vm "$disk" 2>/dev/null | tail -n +2 | grep -q .; then
        error "Диск $disk всё ещё занят, невозможно продолжить"
        exit 1
    fi
}

# --- Размер диска ---
DISK_SIZE=$(lsblk -b -dn -o SIZE "$HDD")
DISK_SIZE_GB=$((DISK_SIZE / 1024 / 1024 / 1024))
info "$(say disk_size)" "$DISK_SIZE_GB GB"

# Покажем предупреждение прямо в терминале (и оно же попадёт в лог, если нужно)
printf '%s\n' "$(say warn_delete)" >/dev/tty

# Прочитаем ответ с управляющего терминала, чтобы read видел ввод
read -r -p "$(say confirm_action) " CONFIRM </dev/tty

# --- $EXISTING_USER ---
EXISTING_USER=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 {print $1,$3}' | sort -k2 -n | head -n1 | cut -d" " -f1)

echo "$(printf "${MSG[${L}_only_user]}" $EXISTING_USER $DISK)"

# --- $USER2 ---
read -rp "$(say create_second_user)" CREATE_USER2

if [[ "$CREATE_USER2" == "y" ]]; then
    read -rp "$(say second_user_name)" USER2
    echo "$(printf "${MSG[${L}_be_second_user]}" $USER2)"
else
    USER2=""   # ← инициализация пустым значением
    echo "$(say no_second_user)"
fi

# --- $USER3 ---
read -rp "$(say create_third_user)" CREATE_USER3

if [[ "$CREATE_USER3" == "y" ]]; then
    read -rp "$(say third_user_name)" USER3
    echo "$(printf "${MSG[${L}_be_third_user]}" $USER3)"
else
    USER3=""   # ← инициализация пустым значением
    echo "$(say no_third_user)"
fi

# Задание размеров разделов для созданных пользователей
info "$(say disk_size)" "$DISK_SIZE_GB GB"

# Ввод размера для существующего пользователя
read -r -p "$(printf "${MSG[${L}_existing_partition_size]}" "$EXISTING_USER")" SIZE1

# Очищаем от всего, кроме цифр
SIZE1=$(echo "$SIZE1" | tr -cd '0-9')

# Проверяем, что это число
if ! [[ "$SIZE1" =~ ^[0-9]+$ ]]; then
    error "Некорректный размер: $SIZE1"
    exit 1
fi

FREE=$((DISK_SIZE_GB - SIZE1))

info "$(printf "$(say remaining)") "$FREE" GB"

if [[ $CREATE_USER2 == [Yy] && -n "$USER2" ]]; then
    read -rp "$(printf "${MSG[${L}_second_partition_size]}" $USER2)" SIZE2
    FREE=$((DISK_SIZE_GB - SIZE1 - SIZE2))
    info "$(printf "$(say remaining)") "$FREE" GB"
fi
if [[ "$CREATE_USER3" == [Yy] && -n "$USER3" ]]; then
    read -rp "$(printf "${MSG[${L}_third_partition_size]}" $USER3)" SIZE3
    FREE=$((DISK_SIZE_GB - SIZE1 - SIZE2 - SIZE3))
    info "$(printf "$(say remaining)") "$FREE" GB"
fi

# --- Создание таблицы разделов ---
ensure_disk_free "$HDD"
parted -s "$HDD" mklabel gpt
partprobe "$HDD"
udevadm settle

# --- Создание раздела ---
START=1
END=$((START + SIZE1))
PART=1

info "$(printf "${MSG[${L}_create_existing_partition]}" $EXISTING_USER)"
ensure_disk_free "$HDD"
parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
partprobe "$HDD"
udevadm settle

mkfs.ext4 -F -L "${EXISTING_USER}" "${HDD}${PART}"

info "$(printf "${MSG[${L}_created_existing_partition]}" "$EXISTING_USER" "$HDD" "$PART" "$SIZE1")"

# Подготовка к следующему разделу
START=$END
PART=$((PART + 1))

# --- Создание раздела для USER2 (если задан) ---
if [[ -n "$USER2" && -n "$SIZE2" ]]; then
    END=$((START + SIZE2))
    info "$(printf "${MSG[${L}_create_second_partition]}" $USER2)"
    
    ensure_disk_free "$HDD"
    parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
    partprobe "$HDD"
    udevadm settle
    
    mkfs.ext4 -F -L "${USER2}" "${HDD}${PART}"
    
    info "$(printf "${MSG[${L}_created_second_partition]}" "$USER2" "$HDD" "$PART" "$SIZE2")"
    START=$END
    PART=$((PART + 1))
fi

# --- Создание раздела для USER3 (если задан) ---
if [[ -n "$USER3" && -n "$SIZE3" ]]; then
    END=$((START + SIZE3))
    info "$(printf "${MSG[${L}_create_third_partition]}" $USER3)"
    ensure_disk_free "$HDD" && parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
    
    ensure_disk_free "$HDD"
    parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
    partprobe "$HDD"
    udevadm settle
    
    mkfs.ext4 -F -L "${USER3}" "${HDD}${PART}"

    info "$(printf "${MSG[${L}_created_third_partition]}" "$USER3" "$HDD" "$PART" "$SIZE3")"
    START=$END
    PART=$((PART + 1))
fi

read -rp "$(say pause)"

# Функция проверки точек монтирования добавляет число 
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

# Вспомогательная функция для blkid (диск меньше, чем ожидалось, или разметка сбилась)
is_partition() {
    [ -b "$1" ]
}

mount_partitions() {
    local part=1
    
    # первый раздел — всегда /mnt/storage
    if is_partition "${HDD}${part}"; then
        UUID=$(blkid -s UUID -o value "${HDD}${part}")
        add_fstab_entry "$UUID" "/mnt/storage"
        part=$((part + 1))
    fi
    
    # второй пользователь (если создан)
    if [[ -n "${USER2:-}" ]] && is_partition "${HDD}${part}"; then
        UUID=$(blkid -s UUID -o value "${HDD}${part}")
        add_fstab_entry "$UUID" "/mnt/${USER2}"
        part=$((part + 1))
    fi


    # третий пользователь (если создан)
    if [[ -n "${USER3:-}" ]] && is_partition "${HDD}${part}"; then
        UUID=$(blkid -s UUID -o value "${HDD}${part}")
        add_fstab_entry "$UUID" "/mnt/${USER3}"
        part=$((part + 1))
    fi
}

if [[ "$HDD" != /dev/sd? && "$HDD" != /dev/nvme?n* ]]; then
    # Пропустить fstab для внешних дисков
    info "USB-диск, не записываем в /etc/fstab"
else
    mount_partitions
fi

# --- Проверка ---
df -h | grep -E "$EXISTING_USER|$USER2|$USER3" >&3

ok "$(say done_disks_users)"
info "$(say restore_hint)"

exit 0

