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
# menu.sh
# Reincarnation Backup Kit — Text Menu Interface (draft)
# MIT License — Copyright (c) 2025 Vladislav Krashevsky support ChatGPT
# =============================================================

set -euo pipefail

# --- Подключаем файл с сообщениями (messages.sh) ---
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/messages.sh"

# --- Проверка root только для команд, где нужны права ---
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "$(say run_sudo)"
        return 1
    fi
}

REAL_HOME="${HOME:-/home/$USER}"
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_HOME="/home/$SUDO_USER"
fi

# --- Пути к скриптам ---
BIN_DIR="$REAL_HOME/bin"
SYS_BACKUP="$BIN_DIR/backup-system.sh"
SYS_RESTORE="$BIN_DIR/restore-system.sh"
USER_BACKUP="$BIN_DIR/backup-userdata.sh"
USER_RESTORE="$BIN_DIR/restore-userdata.sh"
CRON_BACKUP="$BIN_DIR/add-cron-backup.sh"
CLEAN_LOGS="$BIN_DIR/clean-backup-logs.sh"
REMOVE_CRON="$BIN_DIR/remove-cron-backup.sh"
MEDIA_FLATPAK="$BIN_DIR/install-mediatools-flatpak.sh"
SHOTCUT_GPU="$BIN_DIR/check-shotcut-gpu.sh"
NVIDIA_CUDA="$BIN_DIR/install-nvidia-cuda.sh"
MEDIA_APT="$BIN_DIR/install-mediatools-apt.sh"
LAST_ARCHIVE="$BIN_DIR/check-last-archive.sh"
SYSTEM_MOUNTS="$BIN_DIR/show-system-mounts.sh"
HDD_SETUP="$BIN_DIR/hdd-setup-profiles.sh"
CUDA_SCRIPT="$BIN_DIR/check-cuda-tools.sh"

# --- Дистрибутив ---
DISTRO_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
DISTRO_VER=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')


# === Функция просмотра логов ===
show_logs() {
    LOG_DIR="/mnt/backups/logs"

    if [ ! -d "$LOG_DIR" ]; then
        warn "$(say no_logs)"
        return
    fi

    if command -v ranger >/dev/null 2>&1; then
        ranger "$LOG_DIR"
    else
        info "$(say install_ranger)"
        require_root && sudo apt update && sudo apt install -y ranger || {
            warn "$(say failed_ranger)"
            ls -lh "$LOG_DIR"
            return
        }
        ranger "$LOG_DIR"
    fi
}

# --- Главное меню ---
main_menu() {
    while true; do
        clear
        echo "========================================="
        echo "   Reincarnation Backup Kit — $(say main_menu)"
        echo "========================================="
        echo " 1) $(say backup)"
        echo " 2) $(say restore)"
        echo " 3) Manage cron jobs"
        echo " 4) $(say media)"
        echo " 5) $(say tools)"
        echo " 6) $(say logs)"
        echo " 7) $(say settings)"
        echo " 0) $(say exit)"
        echo "-----------------------------------------"
        read -rp "$(say sel_opt)" choice
        case "$choice" in
            1) backup_menu ;;
            2) restore_menu ;;
            3) cron_menu ;;
            4) media_menu ;;
            5) tools_menu ;;
            6) logs_menu ;;
            7) settings_menu ;;
            0) ok "$(say exit)"; exit 0 ;;
            *) warn "$(say invalid_choice)" ;;
        esac
    done
}

# --- Подменю Backup ---
backup_menu() {
    while true; do
        clear
        echo "-----------------------------------------"
        echo "               BACKUP OPTIONS"
        echo "-----------------------------------------"
        info " System ("$DISTRO_ID" "$DISTRO_VER"):"
        echo "   1) Backup system packages, repos & keyrings"
        echo
        echo " Userdata:" 
        echo "   2) Incremental userdata backup"
        echo "   3) Full userdata backup (--fresh)"
        echo "   4) Incremental userdata backup via cron (scheduled)"
        echo
        echo "$(say back_main)"
        echo "-----------------------------------------"
        read -rp "$(say sel_opt)" choice
        case "$choice" in
            1) "$SYS_BACKUP" ;;
            2) "$USER_BACKUP" ;;
            3) "$USER_BACKUP" --fresh ;;
            4)
            read -rp "$(say enter_time)" CRON_TIME
            read -rp "$(say enter_user)" CRON_USER
            if [[ -n "$CRON_TIME" && -n "$CRON_USER" ]]; then
                info "${printf "$(say adding_cron)" "$CRON_TIME" "$CRON_USER"}"
                "$CRON_BACKUP" "$CRON_TIME" "$CRON_USER"
                ok "$(say cron_installed)"
            else
                error "$(say empty_entered)"
            fi
            read -rp "$(say press_continue)"
            ;;
            0) return ;;
            *) warn "$(say invalid_choice)" ;;
        esac
        read -rp "$(say press_return)"
    done
}

# --- Подменю Restore ---
restore_menu() {
    while true; do
        clear
        echo "-----------------------------------------"
        echo "               RESTORE OPTIONS"
        echo "-----------------------------------------"
        info " System ("$DISTRO_ID" "$DISTRO_VER"):"
        echo "   1) Restore packages (manual / full / none)"
        echo "   2) Restore APT sources & GPG keyrings"
        echo
        echo " Userdata:"
        echo "   3) Restore userdata backup"
        echo
        echo "$(say back_main)"
        echo "-----------------------------------------"
        read -rp "$(say sel_opt)" choice
        case "$choice" in
            1) RESTORE_PACKAGES=manual "$SYS_RESTORE" ;;
            2) "$SYS_RESTORE" ;;
            3) "$USER_RESTORE" ;;
            0) return ;;
            *) warn "$(say invalid_choice)" ;;
        esac
        read -rp "$(say press_return)"
    done
}

# --- Подменю Cron ---
cron_menu() {
    clear
    echo "-----------------------------------------"
    echo "        MANAGE CRON BACKUP JOBS"
    echo "-----------------------------------------"
    echo " 1) Incremental userdata backup via cron (scheduled)"
    echo " 2) Clean backup logs"
    echo " 3) Remove cron task"
    echo
    echo "$(say back_main)"
    echo "-----------------------------------------"
    read -rp "$(say sel_opt)" choice
    case "$choice" in
        1)
            read -rp "$(say enter_time)" CRON_TIME
            read -rp "$(say enter_user)" CRON_USER
            if [[ -n "$CRON_TIME" && -n "$CRON_USER" ]]; then
                info "Добавление cron-задачи: $CRON_TIME для $CRON_USER"
                "$CRON_BACKUP" "$CRON_TIME" "$CRON_USER"
                ok "$(say cron_installed)"
            else
                error "$(say empty_entered)"
            fi
            read -rp "$(say press_continue)"
            ;;
        2) "$CLEAN_LOGS" ;;
        3) "$REMOVE_CRON" ;;
        0) return ;;
        *) warn "$(say invalid_choice)" ;;
    esac
    echo
    read -rp "$(say press_return)"
}

# --- Подменю Media ---
media_menu() {
    clear
    echo "-----------------------------------------"
    echo "                Media"
    echo "-----------------------------------------"
    echo " 1) Installs NVIDIA and CUDA drivers."
    echo " 2) Checks GPU availability for Shotcut."
    echo " 3) Install media tools via Flatpak."
    echo " 4) Install media tools via APT."
    echo
    echo "$(say back_main)"
    echo "-----------------------------------------"
    read -rp "$(say sel_opt)" choice
    case "$choice" in     
        1) "$NVIDIA_CUDA" ;;
        2) "$SHOTCUT_GPU" ;;
        3) "$MEDIA_FLATPAK" ;;
        4) "$MEDIA_APT" ;;
        0) return ;;
        *) warn "$(say invalid_choice)" ;;
    esac
    echo
    read -rp "$(say press_return)"
}

# --- Подменю Tools ---
tools_menu() {
    clear
    echo "-----------------------------------------"
    echo "                TOOLS"
    echo "-----------------------------------------"
    echo " ARCHIVE:"
    echo "   1) Check last archive"
    echo
    echo " SYSTEM:"
    echo "   2) Show system mounts"
    echo "   3) HDD setup profiles"
    echo
    echo "$(say back_main)"
    echo "-----------------------------------------"
    read -rp "$(say sel_opt)" choice
    case "$choice" in
        1) "$LAST_ARCHIVE" --list "$USER";;
        2) "$SYSTEM_MOUNTS" ;;
        3) "$HDD_SETUP" ;;
        0) return ;;
        *) warn "S(say invalid_choice)" ;;
    esac
    echo
    read -rp "$(say press_return)"
}

# --- Подменю Logs ---
logs_menu() {
    clear
    echo "-----------------------------------------"
    echo "                LOG FILES"
    echo "-----------------------------------------"
    echo "$(say list_logs)"
    echo "$(say in_ranger)"
    echo "$(say sel_file)"
    echo "$(say exit_file)"
    echo "$(say exit_ranger)"
    echo "-----------------------------------------"
    read -rp "$(say run_return)" choice

    if [[ -z "$choice" ]]; then
        ranger /mnt/backups/logs || warn "$(no_logs)"
    else
        echo "$(say return_menu)"
        sleep 1
    fi
}

# --- Подменю SETTINGS ---
settings_menu() {
    while true; do
        clear
        echo "-----------------------------------------"
        echo "                SETTINGS"
        echo "-----------------------------------------"
        echo " 1) Change language (RU/EN) [TODO]"
        echo " 2) Set backup directories [TODO]"
        echo " 3) Manage CUDA Toolkit"
        echo
        echo "$(say back_main)"
        echo "-----------------------------------------"
        read -rp "$(say sel_opt)" choice
        case "$choice" in
            1)
                echo "$(say lang_not)"
                read -rp "$(say press_continue)"
                ;;
            2)
                echo "$(say backupdir_not)"
                read -rp "$(say press_continue)"
                ;;
            3)
                # Проверяем наличие скрипта
                if [[ -x "$CUDA_SCRIPT" ]]; then
                    "$CUDA_SCRIPT"
                else
                    warn "$(say checkcuda_not)"
                fi
                read -rp "$(say press_return)"
                ;;
            0) return ;;
            *) warn "$(say invalid_choice)" ;;
        esac
    done
}

# --- Запуск ---
main_menu

