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

source "$(dirname "$0")/lib/init.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/context.sh"
source "$LIB_DIR/guards-inhibit.sh"

inhibit_run "$0" "$@"

# === Пути и переменные ===

BASHRC="$HOME/.bashrc"
PROFILE="$HOME/.profile"
EXPORT_LINE='export PATH="$HOME/bin:$PATH"'

## layout / policy
TARGET_DIR="$HOME/bin"
BACKUP_DIR="/mnt/backups"
LOG_DIR="$BACKUP_DIR/logs"

WORKDIR="$BACKUP_DIR/workdir"
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

info installer

# --- Дистрибутив ---
DISTRO_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
DISTRO_VER=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
info distro_found "$DISTRO_ID" "$DISTRO_VER"

# --- ~/bin ---
mkdir -p "$TARGET_DIR"
ok  dir_created "$TARGET_DIR"

# --- Списки скриптов ---
SCRIPTS_SYSTEM=("backup-system.sh" "restore-system.sh" "backup-restore-firefox.sh")
SCRIPTS_USERDATA=("backup-restore-userdata.sh" "backup-userdata.sh" "restore-userdata.sh" "check-last-archive.sh")
SCRIPTS_MEDIA=("install-nvidia-cuda.sh" "install-mediatools-flatpak.sh" "check-shotcut-gpu.sh" "install-mediatools-apt.sh")
SCRIPTS_OS=()
SCRIPTS_CRON=("add-cron-backup.sh" "cron-backup-userdata.sh" "clean-backup-logs.sh" "remove-cron-backup.sh")
HDD_SETUP=("menu.sh" "hdd-setup-profiles.sh" "show-system-mounts.sh" "check-cuda-tools.sh" "setup-symlinks.sh")
SCRIPTS_I18N=(
  "i18n/messages_ru.sh"
  "i18n/messages_en.sh"
  "i18n/messages_ja.sh"
)
SCRIPTS_LIB=("lib/deps.sh" "lib/guards-inhibit.sh" "lib/logging.sh" "lib/init.sh" "lib/context.sh")

# --- OS-specific ---
if [[ "$DISTRO_ID" == "ubuntu" ]]; then
    if [[ "$DISTRO_VER" == "22.04" ]]; then
        SCRIPTS_OS=("backup-ubuntu-22.04.sh" "restore-ubuntu-22.04.sh")
    elif [[ "$DISTRO_VER" == "24.04" ]]; then
        SCRIPTS_OS=("backup-ubuntu-24.04.sh" "restore-ubuntu-24.04.sh")
    else
        error distro_ver_not_supported "$DISTRO_VER"
        exit 1
    fi
elif [[ "$DISTRO_ID" == "debian" ]]; then
    SCRIPTS_OS=("backup-debian-12.sh" "restore-debian-12.sh")
else
    error distro not_supported "$DISTRO_ID"
    exit 1
fi

# -------------------------------------------------------------
# Функция установки файлов i18n
# -------------------------------------------------------------
install_i18n() {
  echo "Installing i18n message files..."

  for file in "${SCRIPTS_I18N[@]}"; do
     install -Dm644 "$file" "$TARGET_DIR/$file"
  done
}

# -------------------------------------------------------------
# Функция установки файлов библиотеки lib
# -------------------------------------------------------------
install_lib() {
    echo "Installing library files..."

    for file in "${SCRIPTS_LIB[@]}"; do
        install -Dm644 "$file" "$TARGET_DIR/$file"
    done
}

# -------------------------------------------------------------
# Установка исполняемых скриптов
# -------------------------------------------------------------
SCRIPTS=("install.sh" "${SCRIPTS_OS[@]}" "${SCRIPTS_SYSTEM[@]}" \
         "${SCRIPTS_USERDATA[@]}" "${HDD_SETUP[@]}" \
         "${SCRIPTS_MEDIA[@]}" "${SCRIPTS_CRON[@]}")

# --- Копирование скриптов ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for script in "${SCRIPTS[@]}"; do
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        cp "$SCRIPT_DIR/$script" "$TARGET_DIR/"
        chmod +x "$TARGET_DIR/$script"
        ok "$script → $TARGET_DIR"
    else
        warn script_skipped "$script" "$SCRIPT_DIR"
    fi
done

# --- Установка i18n и lib ----
install_i18n
install_lib

# --- PATH ---
PATH_ADDED=false
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    if [ -w "$BASHRC" ] && ! grep -Fxq "$EXPORT_LINE" "$BASHRC"; then
        echo "$EXPORT_LINE" >> "$BASHRC"
        PATH_ADDED=true
        warn path_added_bashrc
    fi
    if [ -w "$PROFILE" ] && ! grep -Fxq "$EXPORT_LINE" "$PROFILE"; then
        echo "$EXPORT_LINE" >> "$PROFILE"
        PATH_ADDED=true
        warn path_added_profile
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
        ok deps_ok
        return 0
    fi

    warn deps_missing_list "${MISSING_PKGS[*]}"
    info deps_install_try

    # --- определение пакетного менеджера ---
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y "${MISSING_PKGS[@]}"
        # ВНИМАНИЕ: предполагается, что имя команды совпадает с именем пакета# 

    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "${MISSING_PKGS[@]}"

    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y "${MISSING_PKGS[@]}"

    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm "${MISSING_PKGS[@]}"

    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y "${MISSING_PKGS[@]}"

    else
        error unknown_manager ${MISSING_PKGS[*]}
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
info scripts_list
for script in "${SCRIPTS_SYSTEM[@]}" "${SCRIPTS_USERDATA[@]}" "${HDD_SETUP[@]}" "${SCRIPTS_MEDIA[@]}" "${SCRIPTS_CRON[@]}"; do
    # пропускаем служебные скрипты
    if [[ "$script" == "backup-restore-userdata.sh" || "$script" == "cron-backup-userdata.sh" ]]; then
        continue
    fi
    echo "  - $script"
done

# --- Завершение ---
ok "done_ins "$DISTRO_ID $DISTRO_VER"

