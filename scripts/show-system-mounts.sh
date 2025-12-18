#!/bin/bash
# =============================================================
# show-system-mounts.sh — список точек монтирования и симлинков
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky
# =============================================================

set -euo pipefail

# --- Inhibit recursion via systemd-inhibit ---
if [[ -t 1 ]] && command -v systemd-inhibit >/dev/null 2>&1; then
    if [[ -z "${INHIBIT_LOCK:-}" ]]; then
        export INHIBIT_LOCK=1
        exec systemd-inhibit \
            --what=handle-lid-switch:sleep:idle \
            --why="Backup in progress" \
            "$0" "$@"
    fi
fi

# -------------------------------------------------------------
# 1. Определяем директорию скрипта
# -------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -------------------------------------------------------------
# 2. Объявляем ассоциативный массив MSG (будет расширяться при source)
# -------------------------------------------------------------
declare -A MSG

# -------------------------------------------------------------
# 3. Функция загрузки сообщений
# -------------------------------------------------------------
load_messages() {
    local lang="$1"
    # очищаем предыдущие ключи
    MSG=()

    case "$lang" in
        ru)
            source "$SCRIPT_DIR/i18n/messages_ru.sh"
            ;;
        en)
            source "$SCRIPT_DIR/i18n/messages_en.sh"
            ;;
        *)
            echo "Unknown language: $lang" >&2
            return 1
            ;;
    esac
}

# -------------------------------------------------------------
# 4. Безопасный say
# -------------------------------------------------------------
say() {
    local key="$1"; shift
    local msg="${MSG[${key}]:-$key}"

    if [[ $# -gt 0 ]]; then
        printf "$msg\n" "$@"
    else
        printf '%s\n' "$msg"
    fi
}

# -------------------------------------------------------------
# 5. Функция info для логирования
# -------------------------------------------------------------
info() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b" "$(printf "$fmt" "$@")"
    printf "\n"
}


# -------------------------------------------------------------
# 6. Функция warn для логирования
# -------------------------------------------------------------
warn() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "[WARN] %b\n" "$(printf "$fmt" "$@")" >&2
}

# -------------------------------------------------------------
# 7. Функция error для логирования
# -------------------------------------------------------------
error() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "[ERROR] %b\n" "$(printf "$fmt" "$@")" >&2
}


# -------------------------------------------------------------
# 8. Функция echo_msg для логирования
# -------------------------------------------------------------
echo_msg() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b\n" "$(printf "$fmt" "$@")"
}

# -------------------------------------------------------------
# 9. Функция die для логирования
# -------------------------------------------------------------
die() {
    error "$@"
    exit 1
}

# -------------------------------------------------------------
# 10. Устанавливаем язык по умолчанию и загружаем переводы
# -------------------------------------------------------------
LANG_CODE="${LANG_CODE:-ru}"
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
if [[ "$(id -u)" -eq 0 ]]; then
    crontab -l 2>/dev/null || echo_msg empty
else
    crontab -l 2>/dev/null || echo_msg empty
fi
echo

exit 0
