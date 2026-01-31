#!/usr/bin/env bash
# =============================================================
# scripts/lib/directories.sh — пути и переменные
# =============================================================
# Использование cleanup.sh
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# LIB_DIR="$SCRIPT_DIR/lib"
:<<'DOC'
=============================================================
source "$LIB_DIR/directories.sh"
=============================================================
DOC

# --- Пользователь ---
RUN_USER="${SUDO_USER:-$USER}"

# --- Домашний каталог пользователя ---
USER_HOME="$(getent passwd "$RUN_USER" | cut -d: -f6)"

# --- Shell ---
BASHRC="$USER_HOME/.bashrc"
PROFILE="$USER_HOME/.profile"
EXPORT_LINE='export PATH="$HOME/bin:$PATH"'

# --- Корень резервных копий ---
BACKUP_DIR="${BACKUP_DIR:-/mnt/backups/REBK}"

# --- Пользовательские данные ---
USERDATA_DIR="$BACKUP_DIR/userdata/user_data"
ARCHIVE_DIR="$BACKUP_DIR/userdata/tar_archive"

# --- Система ---
SYSTEM_DIR="$BACKUP_DIR/packages/system"
SYSTEM_MANUAL_DIR="$SYSTEM_DIR/manual"
SYSTEM_FULL_DIR="$SYSTEM_DIR/full"

# --- Firefox ---
FIREFOX_DIR="$BACKUP_DIR/packages/firefox"

# --- Рабочие каталоги ---
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"

# --- Бинарники ---
TARGET_DIR="$USER_HOME/bin"

# --- Архивы ---
BACKUP_NAME="$SYSTEM_DIR/backup-ubuntu-24.04.tar.gz"

# --- Пути проекта ---
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$LIB_DIR/.." && pwd)"
I18N_DIR="$SCRIPT_DIR/i18n"

# LOG_FILE="$LOG_DIR/install-nvidia-cuda.log"
# RUN_LOG="$LOG_DIR/backres-$(date +%F-%H%M%S).log"
# BACKUP_LOG="$LOG_DIR/backup-$(date +%F-%H%M%S).log"
# RESTORE_LOG="$LOG_DIR/restore-$(date +%F-%H%M%S).log"

RUN_USER="${SUDO_USER:-$USER}"


