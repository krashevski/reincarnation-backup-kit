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
Part of Backup Kit — HDD setup and users creation
MIT License — Copyright (c) 2025 Vladislav Krashevsky support ChatGPT
=============================================================
DOC

set -euo pipefail

# Стандартная библиотека REBK
# --- Определяем BIN_DIR относительно скрипта ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Путь к библиотекам всегда относительно BIN_DIR
LIB_DIR="$BIN_DIR/lib"

# source "$(dirname "$0")/lib/init.sh"

source "$LIB_DIR/i18n.sh"
init_app_lang

source "$LIB_DIR/logging.sh"       # error / die
source "$LIB_DIR/user_home.sh"     # resolve_target_home
source "$LIB_DIR/real_user.sh"     # resolve_real_user
source "$LIB_DIR/privileges.sh"    # require_root
source "$LIB_DIR/context.sh"       # контекст выполнения
source "$LIB_DIR/guards-inhibit.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

require_root || return 1
# inhibit_run "$0" "$@"

info hdd_start

# === Логирование ===
LOG_FILE="/mnt/backups/logs/hdd_setup_profiles.log"
exec > >(tee -a "$LOG_FILE") 2>&1
exec 3>&1 4>&2
trap 'exec 1>&3 2>&4' EXIT
info log_enabled "$LOG_FILE"

# --- Поиск доступных дисков ---
info hdd_detect

ALL_DISKS=($(lsblk -ndo NAME,TYPE | awk '$2=="disk"{print $1}'))
AVAILABLE_DISKS=()

# Определяем диск с корневой системой
ROOT_DEV=$(df / | tail -1 | awk '{print $1}')   # например /dev/sda1
ROOT_DISK=$(basename "$ROOT_DEV")               # sda1
ROOT_DISK_NAME="${ROOT_DISK%%[0-9]*}"          # sda

for d in "${ALL_DISKS[@]}"; do
    dev="/dev/$d"
    safe_dev=$(printf '%s' "$dev" | sed 's/[.[\*^$()+?{|]/\\&/g')
    
    # Пропускаем диск с ОС
    if [[ "$d" == "$ROOT_DISK_NAME" ]]; then
        warn skip_os_disk "$dev"
        continue
    fi
    
    # проверяем, есть ли у диска смонтированные разделы как архивы
    if mount | grep -qE "^$dev.* (/(mnt/)?backups?|/(mnt/)?backup)(\\s|$)"; then
        warn skip_archive "$dev"
        continue
    fi
    AVAILABLE_DISKS+=("$d")
done

if [ ${#AVAILABLE_DISKS[@]} -eq 0 ]; then
    error no_partitioning
    exit 1
fi

# --- Выбор диска пользователем ---
echo_msg sel_partition

select_prompt() {
    local key="$1"
    PS3="$(say "$key") "
}

select_prompt select_disk

select DISK in "${AVAILABLE_DISKS[@]}"; do
    case "$REPLY" in
        0)
            info exit_selected
            return 0    # или break / exit 0 — по архитектуре меню
            ;;
        *)
            if [[ -n "$DISK" ]]; then
                break
            else
                warn invalid_choice
            fi
            ;;
    esac
done

HDD="/dev/$DISK"
info disk_selected "$HDD"

# Проверка монтирования разделов на выбранном диске
# Проверка значения переменной
if [ -z "$HDD" ]; then
    error var_empty
    exit 1
fi

info check_mounts "$HDD"

ensure_disk_free() {
    local disk="$1"
    info freeing_disk "$disk"

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
        info term_holding_processes "$pids"
    else
        info no_found_holding
    fi

    # 5) Синхронизируем и даём ядру время
    sync
    udevadm settle --timeout=10 || true

    # 6) Пытаемся перечитать таблицу разделов
    if ! blockdev --rereadpt "$disk" 2>/dev/null; then
        partprobe "$disk" 2>/dev/null || true
    fi

    # 7) Финальная проверка — если всё ещё есть процессы, считаем диск занятым
    if fuser -vm "$disk" 2>/dev/null | tail -n +2 | grep -q .; then
        error disk_busy "$disk"
        exit 1
    fi
}

# --- Размер диска ---
DISK_SIZE=$(LC_ALL=C lsblk -b -dn -o SIZE "$HDD" 2>/dev/null || echo "")

if [[ -z "$DISK_SIZE" ]]; then
    error hdd_cannot_detect_size "$HDD"
    exit 1
fi

DISK_SIZE_GB=$((DISK_SIZE / 1024 / 1024 / 1024))
info disk_size "${DISK_SIZE_GB} GB"

# Покажем предупреждение прямо в терминале (и оно же попадёт в лог, если нужно)
printf '%s\n' "$(say warn_delete)" >/dev/tty

# Прочитаем ответ с управляющего терминала, чтобы read видел ввод
# Используем /dev/tty напрямую, чтобы read работал даже под sudo/systemd
read -r -p "$(say confirm_action)" answer </dev/tty

if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Aborted by user" >/dev/tty
    exit 0
fi
# --- $EXISTING_USER ---
# --- Выбор существующего пользователя для multi-user системы ---
sudo_user="${SUDO_USER:-}"

if [[ -n "$sudo_user" && "$sudo_user" != "root" ]]; then
    EXISTING_USER="$sudo_user"
elif logname &>/dev/null; then
    EXISTING_USER="$(logname)"
else
    EXISTING_USER="$(
        getent passwd |
        awk -F: '$3 >= 1000 && $3 < 60000 && $7 !~ /(false|nologin)$/ {print $1}' |
        head -n1
    )"
fi

# Получаем домашнюю директорию
USER_HOME="$(getent passwd "$EXISTING_USER" | cut -d: -f6)"

# Проверка существования домашней директории
if [[ ! -d "$USER_HOME" ]]; then
    echo "ERROR: Home directory not found for user $EXISTING_USER"
    exit 1
fi

echo_msg only_user "$EXISTING_USER" "$DISK"

# --- $USER2 ---
read -rp "$(echo_msg create_second_user)" CREATE_USER2

if [[ "$CREATE_USER2" == "y" ]]; then
    read -rp "$(echo_msg second_user_name)" USER2
    echo_msg be_second_user "$USER2"
else
    USER2=""   # ← инициализация пустым значением
    echo_msg no_second_user
fi

# --- $USER3 ---
read -rp "$(echo_msg create_third_user)" CREATE_USER3

if [[ "$CREATE_USER3" == "y" ]]; then
    read -rp "$(echo_msg third_user_name)" USER3
    echo_msg be_third_user "$USER3"
else
    USER3=""   # ← инициализация пустым значением
    echo_msg no_third_user
fi

# Задание размеров разделов для созданных пользователей
info disk_size "$DISK_SIZE_GB GB"

# Ввод размера для существующего пользователя
read -r -p "$(echo_msg existing_partition_size "$EXISTING_USER")" SIZE1

# Очищаем от всего, кроме цифр
SIZE1=$(echo "$SIZE1" | tr -cd '0-9')

# Проверяем, что это число
if ! [[ "$SIZE1" =~ ^[0-9]+$ ]]; then
    error "$(say invalid_size)" $SIZE1
    exit 1
fi

FREE=$((DISK_SIZE_GB - SIZE1))

info remaining "$FREE GB"

if [[ $CREATE_USER2 == [Yy] && -n "$USER2" ]]; then
    read -r -p "$(say second_partition_size "$USER2")" SIZE2
    FREE=$((DISK_SIZE_GB - SIZE1 - SIZE2))
    info remaining "$FREE GB"
fi
if [[ "$CREATE_USER3" == [Yy] && -n "$USER3" ]]; then
    read -r -p "$(say third_partition_size "$USER3")" SIZE3
    FREE=$((DISK_SIZE_GB - SIZE1 - SIZE2 - SIZE3))
    info remaining "$FREE GB"
fi

# --- Создание таблицы разделов ---
ensure_disk_free "$HDD"
parted -s "$HDD" mklabel gpt
partprobe "$HDD"
udevadm settle --timeout=10 || true

# --- Создание раздела ---
START=1
END=$((START + SIZE1))
PART=1

info create_existing_partition "$EXISTING_USER"

# ensure_disk_free "$HDD"
parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
partprobe "$HDD"
udevadm settle --timeout=10 || true

mkfs.ext4 -F -L "${EXISTING_USER}" "${HDD}${PART}"

if mkfs.ext4 -F -L "${EXISTING_USER}" "${HDD}${PART}" >>"$LOG_FILE" 2>&1; then
    info done_fs "${HDD}${PART}" "${EXISTING_USER}"   # Вывод: "Готово: FS /dev/$PART для USER"
else
    error fs_failed "${HDD}${PART}" "${EXISTING_USER}"  # Вывод: "[ERROR] Не удалось создать FS"
    exit 1
fi

# Подготовка к следующему разделу
START=$END
PART=$((PART + 1))

# --- Создание раздела для USER2 (если задан) ---
if [[ -n "$USER2" && -n "$SIZE2" ]]; then
    END=$((START + SIZE2))
    info create_second_partition "$USER2"
    
#   ensure_disk_free "$HDD"
    parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
    partprobe "$HDD"
    udevadm settle  --timeout=10 || true
    
    mkfs.ext4 -F -L "${USER2}" "${HDD}${PART}"
    
    if mkfs.ext4 -F -L "${USER2}" "${HDD}${PART}" >>"$LOG_FILE" 2>&1; then
        info done_fs "${HDD}${PART}" "${USER2}"   # Вывод: "Готово: FS /dev/$PART для USER"
    else
        error fs_failed "${HDD}${PART}" "${USER2}"  # Вывод: "[ERROR] Не удалось создать FS"
    exit 1
    fi
    START=$END
    PART=$((PART + 1))
fi

# --- Создание раздела для USER3 (если задан) ---
if [[ -n "$USER3" && -n "$SIZE3" ]]; then
    END=$((START + SIZE3))
    info create_third_partition "$USER3"
    ensure_disk_free "$HDD" && parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
    
#   ensure_disk_free "$HDD"
    parted -s "$HDD" mkpart primary ext4 "${START}GiB" "${END}GiB"
    partprobe "$HDD"
    udevadm settle  --timeout=10 || true
    
    mkfs.ext4 -F -L "${USER3}" "${HDD}${PART}"

    if mkfs.ext4 -F -L "${USER3}" "${HDD}${PART}" >>"$LOG_FILE" 2>&1; then
        info done_fs "${HDD}${PART}" "${USER3}"   # Вывод: "Готово: FS /dev/$PART для USER"
    else
        error fs_failed "${HDD}${PART}" "${USER3}"  # Вывод: "[ERROR] Не удалось создать FS"
    exit 1
    fi
    START=$END
    PART=$((PART + 1))
fi

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
        info mountpoint_exists "$MOUNTPOINT"
    fi

    # создаём каталог
    sudo mkdir -p "$MOUNTPOINT"

    # проверка: нет ли уже записи с этим UUID или этим MOUNTPOINT
    if grep -q "UUID=$UUID" /etc/fstab || grep -q "[[:space:]]$MOUNTPOINT[[:space:]]" /etc/fstab; then
        warn fstab_exists
    else
        echo "UUID=$UUID  $MOUNTPOINT  $FSTYPE  $OPTIONS  $PASS" | sudo tee -a /etc/fstab
        echo_msg fstab_added "$MOUNTPOINT"
    fi
}

# Вспомогательная функция для blkid (диск меньше, чем ожидалось, или разметка сбилась)
is_partition() {
    [ -b "$1" ]
}

# Является ли устройство USB
is_usb_disk() {
    local dev="$1"
    local name
    name=$(basename "$dev")
    local tran
    tran=$(lsblk -ndo TRAN "/dev/$name" 2>/dev/null)
    [[ "$tran" == "usb" ]]
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

if is_usb_disk "$HDD"; then
    info no_write_usb
else
    mount_partitions
fi

if mountpoint -q /mnt/storage; then
    info part_mounted

    # multi-user support
    export EXISTING_USER
    export USER_HOME

    SCRIPT_DIR="$(dirname "$(realpath "$0")")"
    exec "$SCRIPT_DIR/setup-symlinks.sh"
else
    warn say no_part_mounted
fi

# --- Проверка ---
df -h | grep -E "$EXISTING_USER|$USER2|$USER3" >&3

echo_msg done_disks_users
info restore_hint

exit 0

