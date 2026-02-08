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

#!/usr/bin/env bash

source "$(dirname "$0")/lib/init.sh"

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
SEIUP_SYMLINKS="$BIN_DIR/setup-symlinks.sh"
CUDA_SCRIPT="$BIN_DIR/check-cuda-tools.sh"

# --- Дистрибутив ---
DISTRO_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
DISTRO_VER=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

# === Функция просмотра логов ===
show_logs() {
    LOG_DIR="/mnt/backups/logs"

    if [ ! -d "$LOG_DIR" ]; then
        warn no_logs
        return
    fi

    if command -v ranger >/dev/null 2>&1; then
        ranger "$LOG_DIR"
    else
        info install_ranger
        require_root && sudo apt update && sudo apt install -y ranger || {
            warn failed_ranger
            ls -lh "$LOG_DIR"
            return
        }
        ranger "$LOG_DIR"
    fi
}

# Переключатель языка
change_language() {
    clear
    echo "Choose language:"
    echo "1) English"
    echo "2) Русский"
    echo "3) 日本語"

    read -r choice

    case "$choice" in
        1) APP_LANG="en" ;;
        2) APP_LANG="ru" ;;
        3) APP_LANG="ja" ;;
    esac

    export APP_LANG
    load_messages   # <-- обязательно, чтобы новые сообщения подхватились
}


# --- Главное меню ---
main_menu() {
    while true; do
        clear
        echo "========================================="
        echo "   Reincarnation Backup Kit — $(echo_msg main_menu)"
        echo "========================================="
        echo " 1) $(say backup)"
        echo " 2) $(say restore)"
        echo " 3) $(say cron_jobs)"
        echo " 4) $(say media)"
        echo " 5) $(say tools)"
        echo " 6) $(say logs)"
        echo " 7) $(say settings)"
        echo " 0) $(say exit)"
        echo "-----------------------------------------"
        read -rp "$(echo_msg sel_opt)" choice
        case "$choice" in
            1) backup_menu ;;
            2) restore_menu ;;
            3) cron_menu ;;
            4) media_menu ;;
            5) tools_menu ;;
            6) logs_menu ;;
            7) settings_menu ;;
            0) echo_msg exit; exit 0 ;;
            *) warn invalid_choice ;;
        esac
    done
}

# --- Подменю Backup ---
backup_menu() {
    while true; do
        clear
        echo "-----------------------------------------"
        echo_msg backup_options
        echo "-----------------------------------------"
        info system "$DISTRO_ID $DISTRO_VER"
        echo_msg backup_system_full
        echo_msg backup_system_manual
        echo
        echo_msg userdata 
        echo_msg userdata_backup
        echo_msg full_backup
        echo
        echo_msg back_main
        echo "-----------------------------------------"
        read -rp "$(echo_msg sel_opt)" choice
        case "$choice" in
            1) bash "$SYS_BACKUP" full ;;      # Создаём full backup
            2) bash "$SYS_BACKUP" manual ;;    # Создаём manual backup
            3) bash "$USER_BACKUP" ;;
            4) bash "$USER_BACKUP" --fresh ;;
            0) return ;;
            *) warn invalid_choice ;;
        esac
        read -rp "$(echo_msg press_return)"
    done
}


# --- Подменю Restore ---
restore_menu() {
    while true; do
        clear
        echo "-----------------------------------------"
        echo_msg restore_options
        echo "-----------------------------------------"
        info system "$DISTRO_ID $DISTRO_VER"
        echo_msg restore_system_full
        echo_msg restore_system_manual
        echo
        echo_msg userdata
        echo_msg restore_userdata
        echo
        echo_msg back_main
        echo "-----------------------------------------"
        read -rp "$(echo_msg sel_opt)" choice
        case "$choice" in
            1) bash "$SYS_RESTORE" ;;              # default
            2) bash "$SYS_RESTORE" manual ;;       # ручной режим
            3) bash "$USER_RESTORE" ;;             # restore userdata
            0) return ;;
            *) warn invalid_choice ;;
        esac
        read -rp "$(echo_msg press_return)"
    done
}

# --- Подменю Cron ---
cron_menu() {
    clear
    echo "-----------------------------------------"
    echo "$(say manage_cron)"
    echo "-----------------------------------------"
    echo "$(say menu_cron)"
    echo "$(say clean_backup_logs)"
    echo "$(say remove_cron_task)"
    echo
    echo "$(say back_main)"
    echo "-----------------------------------------"
    read -rp "$(echo_msg sel_opt)" choice
    case "$choice" in
        1)
            read -rp "$(echo_msg enter_time)" CRON_TIME
            read -rp "$(echo_msg enter_user)" CRON_USER
            if [[ -n "$CRON_TIME" && -n "$CRON_USER" ]]; then
                info adding_cron "$CRON_TIME" "$CRON_USER"
                bash "$CRON_BACKUP" "$CRON_TIME" "$CRON_USER"
                echo_msg cron_job_installed
            else
                error empty_entered
            fi
            read -rp "$(echo_msg press_continue)"
            ;;        
        2) bash "$CLEAN_LOGS" ;;
        3) bash "$REMOVE_CRON" ;;
        0) return ;;
        *) warn invalid_choice ;;
    esac
    echo
    read -rp "$(echo_msg press_return)"
}

# --- Подменю Media ---
media_menu() {
    clear
    echo "-----------------------------------------"
    echo "$(say menu_media)"
    echo "-----------------------------------------"
    echo "$(say install_flatpak)"
    echo "$(say install_nvidia)"
    echo "$(say checks_gpu)"
    echo "$(say install_apt)"
    echo
    echo "$(say back_main)"
    echo "-----------------------------------------"
    read -rp "$(echo_msg sel_opt)" choice
    case "$choice" in     
        1) "$MEDIA_FLATPAK" ;;
        2) sudo bash "$NVIDIA_CUDA" ;;
        3) "$SHOTCUT_GPU" ;;
        4)
           set +e
           "$MEDIA_APT"
           status=$?
           set -e

           case "$status" in
              0)
                 info apt_installed
              ;;
              10)
                 warn apt_busy
                 info returned_main_menu
              ;;
              *)
                 error installation_error "$status"
                 info returned_menu
              ;;
          esac
        ;;
        0) return ;;
        *) warn invalid_choice ;;
    esac
    echo
    read -rp "$(echo_msg press_return)"
}

# --- Подменю Tools ---
tools_menu() {
    clear
    echo "-----------------------------------------"
    echo "$(say menu_tools)"
    echo "-----------------------------------------"
    echo "$(say menu_archive)"
    echo "$(say last_archive)"
    echo
    echo "$(say menu_system)"
    echo "$(say system_mounts)"
    echo "$(say hdd_setup)"
    echo "$(say setup_symlinks)"
    echo
    echo "$(say back_main)"
    echo "-----------------------------------------"
    read -rp "$(say sel_opt)" choice
    case "$choice" in
        1) "$LAST_ARCHIVE" --list "$USER";;
        2) "$SYSTEM_MOUNTS" ;;
        3) "$HDD_SETUP" ;;
        4) "$SEIUP_SYMLINKS" ;;
        0) return ;;
        *) warn invalid_choice ;;
    esac
    echo
    read -rp "$(echo_msg press_return)"
}

logs_menu() {
    clear
    echo "-----------------------------------------"
    echo "$(say log_files)"
    echo "-----------------------------------------"
    echo "$(say list_logs)"
    echo "$(say in_ranger)"
    echo "$(say sel_file)"
    echo "$(say exit_file)"
    echo "$(say exit_ranger)"
    echo "-----------------------------------------"

    read -rp "$(echo_msg run_return) " choice

    case "$choice" in
        "" )
            ranger /mnt/backups/logs || warn no_logs
            ;;
        q|Q )
            return
            ;;
        * )
            echo_msg return_menu
            sleep 1
            ;;
    esac
}


# --- Подменю SETTINGS ---
settings_menu() {
    while true; do
        clear
        echo "-----------------------------------------"
        echo "$(say menu_settings)"
        echo "-----------------------------------------"
        echo "$(say change_language)"
        echo "$(say backup_directories)"
        echo "$(say manage_cuda)"
        echo
        echo "$(say back_main)"
        echo "-----------------------------------------"
        read -rp "$(echo_msg sel_opt)" choice
        case "$choice" in
            1)
                change_language # <-- здесь вызываем функцию переключения языка
                export LANG_CODE
                read -rp "$(echo_msg press_continue)"
                ;;
            2)
                echo_msg backupdir_not
                read -rp "$(echo_msg press_continue)"
                ;;
            3)
                if [[ ! -x "$CUDA_SCRIPT" ]]; then
                   warn checkcuda_not
                   read -rp "$(echo_msg press_continue)"
                   break
                fi

                while true; do
                   clear
                   echo "-----------------------------------------"
                   echo "$(say menu_cuda_choice)"
                   echo "-----------------------------------------"
                   echo "1) Проверить CUDA tools"
                   echo "2) Установить CUDA tools"
                   echo "3) Удалить CUDA tools"
                   echo "0) Назад"
                   echo
                   echo "-----------------------------------------"
                   read -rp "$(echo_msg choose_option) " cuda_choice
                   case "$cuda_choice" in
                   1)
                        if "$CUDA_SCRIPT" check; then
                           :
                        else
                           :
                        fi
                        ;;
                   2)

                        "$CUDA_SCRIPT" install
                        ;;
                   3)
                        "$CUDA_SCRIPT" remove
                        ;;
                   0) 
                        break
                        ;;                     

                   *)
                        warn invalid_choice
                        ;;
                   esac

                   read -rp "$(echo_msg press_continue)"
                   done
                   ;;
            0) return ;;
            *) warn invalid_choice ;;
        esac
    done
}

# --- Запуск ---
main_menu

exit 0