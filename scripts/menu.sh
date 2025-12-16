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

# --- Inhibit recursion via systemd-inhibit ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="Backup in progress" "$0" "$@"
fi

# --- Colors ---
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

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

# подгружаем язык ДО использования MSG и say
LANG_CODE="${LANG_CODE:-ru}"
load_messages "$LANG_CODE"

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
SEIUP_SYMLINKS="$BIN_DIR/setup-symlinks.sh"
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

# Переключатель языка
change_language() {
    clear
    echo "Choose language / Выберите язык:"
    echo "1) Русский"
    echo "2) English"
    read -p "> " choice

    case "$choice" in
        1) LANG_CODE="ru" ;;
        2) LANG_CODE="en" ;;
    esac

    # перезагружаем переводы
    load_messages "$LANG_CODE"
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
        echo " 3) $(say cron_jobs)"
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
        echo "$(say backup_options)"
        echo "-----------------------------------------"
        info "system" "$DISTRO_ID $DISTRO_VER"
        echo "$(say backup_system)"
        echo
        echo "$(say userdata)" 
        echo "$(say userdata_backup)"
        echo "$(say full_backup)"
        echo "$(say cron_backup_menu)"
        echo
        echo "$(say back_main)"
        echo "-----------------------------------------"
        read -rp "$(say sel_opt)" choice
        case "$choice" in
            1) bash "$SYS_BACKUP" ;;
            2) bash "$USER_BACKUP" ;;
            3) bash "$USER_BACKUP" --fresh ;;
            4)
            read -rp "$(say enter_time)" CRON_TIME
            read -rp "$(say enter_user)" CRON_USER
            
            if [[ -n "$CRON_TIME" && -n "$CRON_USER" ]]; then

                info "$(printf "${MSG[adding_cron]}" $CRON_TIME $CRON_USER)"
                bash "$CRON_BACKUP" "$CRON_TIME" "$CRON_USER"
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
        echo "$(say restore_options)"
        echo "-----------------------------------------"
        info "system" "$DISTRO_ID $DISTRO_VER"
        echo "$(say restore_packeages)"
        echo "$(say restore_manual)"
        echo
        echo "$(say userdata)"
        echo "$(say restore_userdata)"
        echo
        echo "$(say back_main)"
        echo "-----------------------------------------"
        read -rp "$(say sel_opt)" choice
        case "$choice" in
            1) RESTORE_PACKAGES=manual "$SYS_RESTORE" ;;
            2) bash "$SYS_RESTORE" ;;
            3) bash "$USER_RESTORE" ;;
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
    echo "$(say manage_cron)"
    echo "-----------------------------------------"
    echo "$(say menu_cron)"
    echo "$(say clean_backup_logs)"
    echo "$(say remove_cron_task)"
    echo
    echo "$(say back_main)"
    echo "-----------------------------------------"
    read -rp "$(say sel_opt)" choice
    case "$choice" in
        1)
            read -rp "$(say enter_time)" CRON_TIME
            read -rp "$(say enter_user)" CRON_USER
            if [[ -n "$CRON_TIME" && -n "$CRON_USER" ]]; then
                info "$(printf "${MSG[adding_cron]}" $CRON_TIME $CRON_USER)"
                bash "$CRON_BACKUP" "$CRON_TIME" "$CRON_USER"
                ok "$(say cron_job_installed)"
            else
                error "$(say empty_entered)"
            fi
            read -rp "$(say press_continue)"
            ;;
        2) bash "$CLEAN_LOGS" ;;
        3) bash "$REMOVE_CRON" ;;
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
    echo "$(say menu_media)"
    echo "-----------------------------------------"
    echo "$(say install_nvidia)"
    echo "$(say checks_gpu)"
    echo "$(say install_flatpak)"
    echo "$(say install_apt)"
    echo
    echo "$(say back_main)"
    echo "-----------------------------------------"
    read -rp "$(say sel_opt)" choice
    case "$choice" in     
        1) sudo bash "$NVIDIA_CUDA" ;;
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
        *) warn "$(say invalid_choice)" ;;
    esac
    echo
    read -rp "$(say press_return)"
}

# --- Подменю Logs ---
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
    read -rp "$(say run_return)" choice

    if [[ -z "$choice" ]]; then
        ranger /mnt/backups/logs || warn "$(say no_logs)"
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
        echo "$(say menu_settings)"
        echo "-----------------------------------------"
        echo "$(say change_language)"
        echo "$(say backup_directories)"
        echo "$(say manage_cuda)"
        echo
        echo "$(say back_main)"
        echo "-----------------------------------------"
        read -rp "$(say sel_opt)" choice
        case "$choice" in
            1)
                change_language # <-- здесь вызываем функцию переключения языка
                export LANG_CODE
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

