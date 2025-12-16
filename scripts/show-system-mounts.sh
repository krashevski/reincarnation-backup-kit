#!/bin/bash
# =============================================================
# show-system-mounts.sh — список точек монтирования и симлинков
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky
# =============================================================

set -euo pipefail

# --- Inhibit recursion via systemd-inhibit ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="Backup in progress" "$0" "$@"
fi

# 1. Сначала объявляем массив
declare -A MSG

# 2. Затем функции, НИКАКИХ source ДО ФУНКЦИЙ!
# -------------------------------------------------------------

# загрузка сообщений
load_messages() {
    local lang="$1"
    MSG=()   # очистка
    case "$lang" in
        ru)
            source "$SCRIPT_DIR/i18n/messages_ru.sh"
            ;;
        en)
            source "$SCRIPT_DIR/i18n/messages_en.sh"
            ;;
        *)
            echo "Unknown language: $lang" >&2
            ;;
    esac
}

# безопасный say
say() {
    local key="$1"
    if [[ -n "${MSG[$key]+set}" ]]; then
        echo "${MSG[$key]}"
    else
        echo "[$key]"
    fi
}

info() {
    local key="$1"
    shift
    local fmt
    fmt="$(say "$key")"
    printf "%b" "$(printf "$fmt" "$@")"
    printf "\n"           # ОБЯЗАТЕЛЬНЫЙ перевод строки
}


# -------------------------------------------------------------
# 3. И только теперь подключаем пути и загружаем сообщения
# -------------------------------------------------------------

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# НЕ ПОДКЛЮЧАЙ messages.sh больше, он НЕ НУЖЕН!
# source "$SCRIPT_DIR/messages.sh"   # ← УДАЛИТЬ

# Если LANG_CODE экспортирован — используем его,
# если нет — по умолчанию "ru"
: "${LANG_CODE:=ru}"

load_messages "$LANG_CODE"

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
# Determine home of real user
# ----------------------------
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    USER_HOME="/home/$SUDO_USER"
else
    USER_HOME="${HOME:-/home/$USER}"
fi

# ----------------------------
# Output
# ----------------------------

echo
say physical_disks
show_disks_info

echo
say mounts_header
lsblk -o NAME,PATH,LABEL,MOUNTPOINT,FSTYPE,UUID -e 7,11

echo
info symlinks_header "$USER_HOME"
find "$USER_HOME" -maxdepth 1 -type l -printf "%f -> %l\n"

echo
say crontab_header
if sudo crontab -l 2>/dev/null; then
  :
else
  echo "(empty)"
fi
echo

