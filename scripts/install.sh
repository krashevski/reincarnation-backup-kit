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
install.sh v3.0 — универсальный установщик Backup Kit (RU/EN)
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
=============================================================
DOC

set -euo pipefail

# -------------------------------------------------------------
# Colors (safe for set -u)
# -------------------------------------------------------------
if [[ "${FORCE_COLOR:-0}" == "1" || -t 1 ]]; then
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    BLUE="\033[0;34m"
    NC="\033[0m"
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; NC=""
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
# 5. Фуекцмя ok
# -------------------------------------------------------------
ok() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[OK]%b %b\n" \
        "${GREEN:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")"
}


# -------------------------------------------------------------
# 6. Функция info для логирования
# -------------------------------------------------------------
info() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[INFO]%b %b\n" \
        "${BLUE:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")" >&2
}


# -------------------------------------------------------------
# 7. Функция warn для логирования
# -------------------------------------------------------------
warn() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[WARN]%b %b\n" \
        "${YELLOW:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")" >&2
}

# -------------------------------------------------------------
# 8. Функция error для логирования
# -------------------------------------------------------------
error() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[ERROR]%b %b\n" \
        "${RED:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")" >&2
}


# -------------------------------------------------------------
# 9. Функция echo_echo_msg для логирования
# -------------------------------------------------------------
echo_msg() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b\n" "$(printf "$fmt" "$@")"
}

# -------------------------------------------------------------
# 10. Функция die для логирования
# -------------------------------------------------------------
die() {
    error "$@"
    exit 1
}

# -------------------------------------------------------------
# 11. Устанавливаем язык по умолчанию и загружаем переводы
# -------------------------------------------------------------
LANG_CODE="${LANG_CODE:-ru}"
load_messages "$LANG_CODE"

# --- Проверка root только для команд, где нужны права ---
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error run_sudo
        return 1
    fi
}

REAL_HOME="${HOME:-/home/$USER}"
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_HOME="/home/$SUDO_USER"
fi

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

# === Пути и переменные ===
TARGET_DIR="$HOME/bin"
BASHRC="$HOME/.bashrc"
PROFILE="$HOME/.profile"
EXPORT_LINE='export PATH="$HOME/bin:$PATH"'
RUN_USER="${SUDO_USER:-$USER}"
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
I18N_DIR="$TARGET_DIR/i18n"

# --- Проверка BACKUP_DIR ---
if [ -d "$BACKUP_DIR" ]; then
    owner=$(stat -c %U "$BACKUP_DIR")
    if [ "$owner" != "$RUN_USER" ]; then
        info "${MSG[backup_owner_fix]} $BACKUP_DIR → $RUN_USER:$RUN_USER"
        sudo chown -R "$RUN_USER:$RUN_USER" "$BACKUP_DIR"
        sudo chmod -R 755 "$BACKUP_DIR"
    fi
else
    error "${MSG[backup_not_exist]}"
    exit 1
fi

# --- Очистка WORKDIR ---
if [[ -d "$WORKDIR" ]]; then
    info "${MSG[workdir_clean]} $WORKDIR"
    rm -rf "$WORKDIR"/*
    ok "${MSG[workdir_cleaned]}"
fi

# --- Символическая ссылка /mnt/backups → ~/backups ---
ln -sfn "$BACKUP_DIR" "$HOME/backups"

echo "${MSG[installer]}"

# --- Дистрибутив ---
DISTRO_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
DISTRO_VER=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
info "${MSG[distro_found]}: $DISTRO_ID $DISTRO_VER"

# --- ~/bin ---
mkdir -p "$TARGET_DIR"
ok "$TARGET_DIR — ${MSG[dir_created]}"

# --- Списки скриптов ---
SCRIPTS_SYSTEM=("backup-system.sh" "restore-system.sh")
SCRIPTS_USERDATA=("backup-restore-userdata.sh" "backup-userdata.sh" "restore-userdata.sh" "check-last-archive.sh")
SCRIPTS_MEDIA=("install-nvidia-cuda.sh" "install-mediatools-flatpak.sh" "check-shotcut-gpu.sh" "install-mediatools-apt.sh")
SCRIPTS_OS=()
SCRIPTS_CRON=("add-cron-backup.sh" "cron-backup-userdata.sh" "clean-backup-logs.sh" "remove-cron-backup.sh")
HDD_SETUP=("menu.sh" "hdd-setup-profiles.sh" "show-system-mounts.sh" "check-cuda-tools.sh" "setup-symlinks.sh")
SCRIPTS_I18N=(
  "i18n/messages.sh"
  "i18n/messages_ru.sh"
  "i18n/messages_en.sh"
)

# --- OS-specific ---
if [[ "$DISTRO_ID" == "ubuntu" ]]; then
    if [[ "$DISTRO_VER" == "22.04" ]]; then
        SCRIPTS_OS=("backup-ubuntu-22.04.sh" "restore-ubuntu-22.04.sh")
    elif [[ "$DISTRO_VER" == "24.04" ]]; then
        SCRIPTS_OS=("backup-ubuntu-24.04.sh" "restore-ubuntu-24.04.sh")
    else
        error "Ubuntu $DISTRO_VER not supported"
        exit 1
    fi
elif [[ "$DISTRO_ID" == "debian" ]]; then
    SCRIPTS_OS=("backup-debian-12.sh" "restore-debian-12.sh")
else
    error "Distro $DISTRO_ID not supported"
    exit 1
fi

install_i18n() {
  echo "Installing i18n message files..."

  for file in "${SCRIPTS_I18N[@]}"; do
     install -Dm644 "$file" "$TARGET_DIR/$file"
  done
}


SCRIPTS=("install.sh" "${SCRIPTS_OS[@]}" "${SCRIPTS_SYSTEM[@]}" "${SCRIPTS_USERDATA[@]}" "${HDD_SETUP[@]}" "${SCRIPTS_MEDIA[@]}" "${SCRIPTS_CRON[@]}")


# --- Копирование скриптов ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for script in "${SCRIPTS[@]}"; do
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        cp "$SCRIPT_DIR/$script" "$TARGET_DIR/"
        chmod +x "$TARGET_DIR/$script"
        ok "$script → $TARGET_DIR"
    else
        warn "$script not found in $SCRIPT_DIR, skipped"
    fi
done

# --- Установка i18n ----
install_i18n

# --- PATH ---
PATH_ADDED=false
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    if [ -w "$BASHRC" ] && ! grep -Fxq "$EXPORT_LINE" "$BASHRC"; then
        echo "$EXPORT_LINE" >> "$BASHRC"
        PATH_ADDED=true
        warn "${MSG[path_added_bashrc]}"
    fi
    if [ -w "$PROFILE" ] && ! grep -Fxq "$EXPORT_LINE" "$PROFILE"; then
        echo "$EXPORT_LINE" >> "$PROFILE"
        PATH_ADDED=true
        warn "${MSG[path_added_profile]}"
    fi
else
    ok "~/bin already in PATH"
fi

# --- Каталоги ---
mkdir -p "$WORKDIR" "$LOG_DIR"
ok "Created: $WORKDIR, $LOG_DIR"

check_and_install_deps() {
    local REQUIRED_PKGS=("$@")
    local MISSING_PKGS=()

    # --- проверка наличия команд ---
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            MISSING_PKGS+=("$pkg")
        fi
    done

    # --- если всё есть ---
    if [ "${#MISSING_PKGS[@]}" -eq 0 ]; then
        ok "${MSG[deps_ok]}"
        return 0
    fi

    echo "⚠️ Отсутствуют зависимости: ${MISSING_PKGS[*]}"
    echo "🔧 Попытка автоматической установки..."

    # --- определение пакетного менеджера ---
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y "${MISSING_PKGS[@]}"

    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "${MISSING_PKGS[@]}"

    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y "${MISSING_PKGS[@]}"

    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm "${MISSING_PKGS[@]}"

    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y "${MISSING_PKGS[@]}"

    else
        error "Неизвестный пакетный менеджер. Установите вручную: ${MISSING_PKGS[*]}"
        return 1
    fi

    # --- повторная проверка ---
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            error "'$pkg' ${MSG[deps_missing]}"
            return 1
        fi
    done

    ok "${MSG[deps_ok]}"
}

check_and_install_deps rsync tar gzip pv

# --- Копирование backup_kit ---
SRC_DIR="$HOME/scripts/backup_kit"
DEST_DIR="$BACKUP_DIR/backup_kit"
if [[ -d "$SRC_DIR" ]]; then
    mkdir -p "$BACKUP_DIR"
    if [[ -d "$DEST_DIR" ]]; then
        info "${MSG[copy_skip]}: $DEST_DIR"
    else
        cp -r "$SRC_DIR" "$BACKUP_DIR/"
        ok "${MSG[copy_done]} → $DEST_DIR"
    fi
else
    warn "${MSG[copy_missing]} ($SRC_DIR)"
fi

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Требуются права root!"
        return 1
    fi
}

# --- Проверка ошибок ---
REAL_HOME="${HOME:-/home/$USER}"
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_HOME="/home/$SUDO_USER"
fi

if [[ ${ERROR_COUNT:-0} -eq 0 ]]; then
    # Запуск текстового меню Reincarnation Backup Kit
    if [[ -x "$REAL_HOME/bin/menu.sh" ]]; then
        echo -e "${MSG[text_menu]}"
        # Запуск меню от текущего пользователя
        exec "$REAL_HOME/bin/menu.sh"
    else
        echo -e "${MSG[menu_not]}"
    fi
fi

# --- Итоговый вывод скриптов для запуска пользователем ---
info "${MSG[scripts_list]}"
for script in "${SCRIPTS_SYSTEM[@]}" "${SCRIPTS_USERDATA[@]}" "${HDD_SETUP[@]}" "${SCRIPTS_MEDIA[@]}" "${SCRIPTS_CRON[@]}"; do
    # пропускаем служебные скрипты
    if [[ "$script" == "backup-restore-userdata.sh" || "$script" == "cron-backup-userdata.sh" ]]; then
        continue
    fi
    echo "  - $script"
done

# --- Завершение ---
ok "${MSG[done]}: $DISTRO_ID $DISTRO_VER"

