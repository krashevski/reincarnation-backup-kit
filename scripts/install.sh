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
install.sh v2.8 — универсальный установщик Backup Kit (RU/EN)
Part of Backup Kit — minimal restore script with simple logging
   Author: Vladislav Krashevsky with support from ChatGPT
   License: MIT
=============================================================
DOC

set -euo pipefail

# === Цвета ===
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARNING]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# === Определение языка ===
if [[ "${LANG:-}" == ru* ]]; then
    LANG_MODE="ru"
else
    LANG_MODE="en"
fi

# === Сообщения ===
declare -A MSG

if [[ $LANG_MODE == "ru" ]]; then
    MSG[installer]="=== Установщик Backup Kit ==="
    MSG[distro_found]="Обнаружен дистрибутив"
    MSG[dir_created]="Каталог создан или уже существует"
    MSG[workdir_clean]="Очищаем временный рабочий каталог"
    MSG[workdir_cleaned]="Рабочий каталог очищен"
    MSG[backup_owner_fix]="Меняю владельца каталога"
    MSG[backup_not_exist]="Каталог /mnt/backups не существует, проверьте монтирование"
    MSG[path_added_bashrc]="В ~/.bashrc добавлен экспорт PATH. Чтобы PATH обновился, выполните: source ~/.bashrc"
    MSG[path_added_profile]="В ~/.profile добавлен экспорт PATH. Перелогиньтесь или выполните: source ~/.profile"
    MSG[deps_missing]="Пакет не установлен. Установите его"
    MSG[deps_ok]="Все зависимости установлены"
    MSG[copy_skip]="backup_kit уже существует, копирование пропущено"
    MSG[copy_done]="Пакет backup_kit скопирован"
    MSG[copy_missing]="Исходный каталог не найден, копирование пропущено"
    MSG[done]="Backup Kit установлен"
    MSG[path_update]="Обновите окружение (source ~/.bashrc или source ~/.profile) или перелогиньтесь"
else
    MSG[installer]="=== Backup Kit Installer ==="
    MSG[distro_found]="Detected distribution"
    MSG[dir_created]="Directory created or already exists"
    MSG[workdir_clean]="Cleaning temporary workdir"
    MSG[workdir_cleaned]="Workdir cleaned"
    MSG[backup_owner_fix]="Changing owner of directory"
    MSG[backup_not_exist]="Directory /mnt/backups does not exist, please check mount"
    MSG[path_added_bashrc]="Export PATH added to ~/.bashrc. To update PATH, run: source ~/.bashrc"
    MSG[path_added_profile]="Export PATH added to ~/.profile. Relogin or run: source ~/.profile"
    MSG[deps_missing]="Package not installed. Please install it"
    MSG[deps_ok]="All dependencies are installed"
    MSG[copy_skip]="backup_kit already exists, skipping copy"
    MSG[copy_done]="backup_kit package copied"
    MSG[copy_missing]="Source directory not found, skipping copy"
    MSG[done]="Backup Kit installed"
    MSG[path_update]="Update environment (source ~/.bashrc or source ~/.profile) or relogin"
fi

# === Настройки ===
TARGET_DIR="$HOME/bin"
BASHRC="$HOME/.bashrc"
PROFILE="$HOME/.profile"
EXPORT_LINE='export PATH="$HOME/bin:$PATH"'
RUN_USER="${SUDO_USER:-$USER}"
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"

# --- Проверка каталога BACKUP_DIR ---
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

# --- Очистка workdir ---
if [[ -d "$WORKDIR" ]]; then
    info "${MSG[workdir_clean]} $WORKDIR"
    rm -rf "$WORKDIR"/*
    ok "${MSG[workdir_cleaned]}"
fi

# --- Символическая ссылка ---
ln -sfn /mnt/backups "$HOME/backups"

echo "${MSG[installer]}"

# --- Дистрибутив ---
DISTRO_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
DISTRO_VER=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
info "${MSG[distro_found]}: $DISTRO_ID $DISTRO_VER"

# --- ~/bin ---
mkdir -p "$TARGET_DIR"
ok "$TARGET_DIR — ${MSG[dir_created]}"

# --- Списки скриптов ---
SCRIPTS_USERDATA=("backup-restore-userdata.sh" "safe-restore-userdata.sh" "check-last-archive.sh")
SCRIPTS_MEDIA=("install-nvidia-cuda.sh" "install-mediatools-flatpak.sh" "check-shotcut-gpu.sh" "install-mediatools-apt.sh")
declare -a SCRIPTS_OS=()

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

SCRIPTS=("install.sh" "-" "${SCRIPTS_OS[@]}" "restore.sh" "-" "${SCRIPTS_USERDATA[@]}" "-" "hdd-setup-profiles.sh" "-" "${SCRIPTS_MEDIA[@]}")

# --- Копирование скриптов ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for script in "${SCRIPTS[@]}"; do
    if [[ "$script" == "-" ]]; then
        continue
    fi
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        cp "$SCRIPT_DIR/$script" "$TARGET_DIR/"
        chmod +x "$TARGET_DIR/$script"
        ok "$script → $TARGET_DIR"
    else
        warn "$script not found in $SCRIPT_DIR, skipped"
    fi
done

# --- PATH ---
PATH_ADDED=false
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    if [ -w "$BASHRC" ]; then
        if ! grep -Fxq "$EXPORT_LINE" "$BASHRC"; then
            echo "$EXPORT_LINE" >> "$BASHRC"
            PATH_ADDED=true
            warn "${MSG[path_added_bashrc]}"
        fi
    fi
    if [ -w "$PROFILE" ]; then
        if ! grep -Fxq "$EXPORT_LINE" "$PROFILE"; then
            echo "$EXPORT_LINE" >> "$PROFILE"
            PATH_ADDED=true
            warn "${MSG[path_added_profile]}"
        fi
    fi
else
    ok "~/bin already in PATH"
fi

# --- Каталоги ---
mkdir -p "$WORKDIR" "$LOG_DIR"
ok "Created: $WORKDIR, $LOG_DIR"

# --- Зависимости ---
REQUIRED_PKGS=("rsync" "tar" "gzip")
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        error "'$pkg' ${MSG[deps_missing]}"
        exit 1
    fi
done
ok "${MSG[deps_ok]}"

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
        info "cd $DEST_DIR/scripts && ./restore.sh"
    fi
else
    warn "${MSG[copy_missing]} ($SRC_DIR)"
fi

# --- Итог ---
info "============================================================="
ok "${MSG[done]}: $DISTRO_ID $DISTRO_VER"
echo "Scripts installed in $TARGET_DIR:"
for script in "${SCRIPTS[@]}"; do
    if [[ "$script" != "-" ]]; then
        echo "   $script"
    fi
done
if [ "$PATH_ADDED" = true ]; then
    warn "${MSG[path_update]}"
fi
info "============================================================="

exit 0

