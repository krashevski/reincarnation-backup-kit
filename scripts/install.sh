#!/usr/bin/env bash
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
install.sh — универсальный установщик Backup Kit (RU/EN)
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
DOC

set -euo pipefail

# -------------------------------------------------------------
# BOOTSTRAP (no external libs)
# -------------------------------------------------------------
log()  { echo "[INFO]  $*" | tee -a "$RUN_LOG"; }
warn() { echo "[WARN]  $*" | tee -a "$RUN_LOG" >&2; }
error(){ echo "[ERROR] $*" | tee -a "$RUN_LOG" >&2; }
die()  { error "$*"; exit 1; }
ok()   { echo "[ OK ]  $*" | tee -a "$RUN_LOG"; }

[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }

# -------------------------------------------------------------
# REQUIRED ENV / DEFAULTS (safe with -u)
# -------------------------------------------------------------
REAL_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(eval echo "~$REAL_USER")"

BACKUP_DIR="/mnt/backups/REBK"
TARGET_DIR="$TARGET_HOME/bin/REBK"
readonly LOG_DIR="$BACKUP_DIR/logs"
readonly WORKDIR="$BACKUP_DIR/workdir"
readonly RUN_LOG="$LOG_DIR/REBK_install.log"

readonly BASHRC="$TARGET_HOME/.bashrc"
readonly PROFILE="$TARGET_HOME/.profile"

mkdir -p "$TARGET_HOME" "$TARGET_DIR" "$BACKUP_DIR" "$LOG_DIR" "$WORKDIR"
touch "$RUN_LOG"

# --- PATH ---
EXPORT_LINE='export PATH="$HOME/bin/REBK:$PATH"'

# Добавляем только если нет в PATH
if [[ ":$PATH:" != *":$HOME/bin/REBK:"* ]]; then
    # Добавляем в .bashrc если есть права
    [[ -w "$HOME/.bashrc" ]] && echo "$EXPORT_LINE" >> "$HOME/.bashrc"
    # Добавляем в .profile если есть права
    [[ -w "$HOME/.profile" ]] && echo "$EXPORT_LINE" >> "$HOME/.profile"
fi

# --- Проверка и создание BACKUP_DIR ---
if [[ ! -d "$BACKUP_DIR" ]]; then
    info install_dir_not "$BACKUP_DIR"
    mkdir -p "$BACKUP_DIR" || {
        error install_failed_dir "$BACKUP_DIR"
        exit 1
    }
fi

chmod 700 "$BACKUP_DIR" 2>/dev/null || true
chown -R "$REAL_USER:$REAL_USER" "$BACKUP_DIR" 2>/dev/null || true

rm -rf "$WORKDIR" 2>/dev/null || true
mkdir -p "$WORKDIR"

log "Cleaning workdir: $WORKDIR"
log "Workdir ready"

# --- Detect system ---
. /etc/os-release || exit 1
DISTRO_ID="$ID"
DISTRO_VER="$VERSION_ID"

# --- Списки скриптов ---
SCRIPTS_SYSTEM=("backup-system.sh" "restore-system.sh" "backup-restore-firefox.sh")
SCRIPTS_OS=(
  backup-ubuntu-22.04.sh
  restore-ubuntu-22.04.sh
  backup-ubuntu-24.04.sh
  restore-ubuntu-24.04.sh
  backup-debian-12.sh
  restore-debian-12.sh
)
SCRIPTS_USERDATA=("backup-restore-userdata.sh" "backup-userdata.sh" "restore-userdata.sh" "check-last-archive.sh")
SCRIPTS_MEDIA=("install-nvidia-cuda.sh" "install-mediatools-flatpak.sh" "check-shotcut-gpu.sh" "install-mediatools-apt.sh")
SCRIPTS_CRON=("add-cron-backup.sh" "cron-backup-userdata.sh" "clean-backup-logs.sh" "remove-cron-backup.sh")
HDD_SETUP=("menu.sh" "hdd-setup-profiles.sh" "show-system-mounts.sh" "check-cuda-tools.sh" "setup-symlinks.sh")
SCRIPTS_I18N=(
  "i18n/messages_ru.sh"
  "i18n/messages_en.sh"
  "i18n/messages_ja.sh"
)
SCRIPTS_LIB=("lib/i18n.sh" "lib/logging.sh" "lib/runner.sh" "lib/user_home.sh" "lib/real_user.sh" "lib/privileges.sh" "lib/context.sh" "lib/guards-inhibit.sh" "lib/cleanup.sh" "lib/fs_utils.sh" "lib/system_detect.sh" "lib/init.sh" "lib/guards-firefox.sh" "lib/select_user.sh" "lib/deps.sh" "maintenance/cleanup.sh" "maintenance/install-man.sh")

# --- OS-specific ---
if [[ "$DISTRO_ID" == "ubuntu" ]]; then
    if [[ "$DISTRO_VER" == "22.04" ]]; then
        SCRIPTS_OS=("backup-ubuntu-22.04.sh" "restore-ubuntu-22.04.sh")
    elif [[ "$DISTRO_VER" == "24.04" ]]; then
        SCRIPTS_OS=("backup-ubuntu-24.04.sh" "restore-ubuntu-24.04.sh")
    else
        error install_ubuntu_not "$DISTRO_VER"
        exit 1
    fi
elif [[ "$DISTRO_ID" == "debian" ]]; then
    SCRIPTS_OS=("backup-debian-12.sh" "restore-debian-12.sh")
else
    error install_distro_not "$DISTRO_ID"
    exit 1
fi

mkdir -p \
  "$TARGET_DIR/i18n" \
  "$TARGET_DIR/lib" \
  "$TARGET_DIR/maintenance"

# -------------------------------------------------------------
# Функция установки файлов i18n
# -------------------------------------------------------------
install_i18n() {
  for file in "${SCRIPTS_I18N[@]}"; do
     install -Dm644 "$file" "$TARGET_DIR/$file"
  done
}

# -------------------------------------------------------------
# Функция установки файлов библиотеки lib
# -------------------------------------------------------------
install_lib() {
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
        warn install_script_skipped "$script" "$SCRIPT_DIR"
    fi
done

# --- Установка i18n и lib ----
install_i18n
install_lib

# --- Исправление владельца пользовательских файлов ---
# info install_fixing_owner "$TARGET_DIR"
chown -R "$REAL_USER:$REAL_USER" "$TARGET_DIR"
ok install_owner "$REAL_USER" "$REAL_USER"

# --- Каталоги ---
install -d -m 755 -o "$REAL_USER" -g "$REAL_USER" "$WORKDIR"
install -d -m 755 -o "$REAL_USER" -g "$REAL_USER" "$LOG_DIR"
ok "install_dirs: $WORKDIR, $LOG_DIR"

check_and_install_deps() {
    local REQUIRED_PKGS=("$@")
    local MISSING_PKGS=()

    for pkg in "${REQUIRED_PKGS[@]}"; do
        command -v "$pkg" >/dev/null 2>&1 || MISSING_PKGS+=("$pkg")
    done

    if [ "${#MISSING_PKGS[@]}" -gt 0 ]; then
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y "${MISSING_PKGS[@]}" || true
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y "${MISSING_PKGS[@]}" || true
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y "${MISSING_PKGS[@]}" || true
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -Sy --noconfirm "${MISSING_PKGS[@]}" || true
        elif command -v zypper >/dev/null 2>&1; then
            sudo zypper install -y "${MISSING_PKGS[@]}" || true
        fi
    fi
}

check_and_install_deps rsync tar gzip pv

# --- Копирование backup_kit ---
SRC_DIR="$TARGET_HOME/scripts/REBK"
DEST_DIR="$BACKUP_DIR/REBK"

if [[ -d "$SRC_DIR" && ! -d "$DEST_DIR" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$SRC_DIR" "$DEST_DIR"
fi

if [[ -x "$TARGET_DIR/menu.sh" ]]; then
    "$TARGET_DIR/menu.sh" || true
fi

# --- Итоговый вывод скриптов для запуска пользователем ---
echo
echo "Installed scripts:"
for script in "${SCRIPTS_SYSTEM[@]}" "${SCRIPTS_OS[@]}" "${SCRIPTS_USERDATA[@]}" \
              "${HDD_SETUP[@]}" "${SCRIPTS_MEDIA[@]}" "${SCRIPTS_CRON[@]}"; do
    # пропускаем служебные скрипты, которые не нужны пользователю
    if [[ "$script" == "backup-restore-userdata.sh" || "$script" == "cron-backup-userdata.sh" ]]; then
        continue
    fi
    echo "  - $script"
done