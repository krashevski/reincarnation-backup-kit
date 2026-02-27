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
menu.sh — text menu interface
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
DOC

[[ -t 0 ]] || exec </dev/tty
set -uo pipefail  # НЕ ставим -e

# --- Пути к библиотекам ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$BIN_DIR/lib"

# --- Подключение библиотек ---
source "$LIB_DIR/i18n.sh"
init_app_lang

source "$LIB_DIR/logging.sh"
source "$LIB_DIR/user_home.sh"
source "$LIB_DIR/real_user.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/context.sh"
source "$LIB_DIR/select_user.sh"
source "$LIB_DIR/system_detect.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

# root / inhibit здесь не используем
# require_root || return 1
# inhibit_run "$0" "$@"

# --- Пути к скриптам ---
BIN_DIR="$TARGET_HOME/bin/REBK"
SYS_BACKUP="$BIN_DIR/backup-system.sh"
FIREFOX_BACKUP_RESTORE="$BIN_DIR/backup-restore-firefox.sh"
USER_BACKUP="$BIN_DIR/backup-userdata.sh"
SYS_RESTORE="$BIN_DIR/restore-system.sh"
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

# --- Detect system ---
detect_system || exit 1
# echo "[DEBUG] DISTRO_ID=$DISTRO_ID, DISTRO_VER=$DISTRO_VER"

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

# =============================================================
# Функция смены языка (поддержка ru/en/ja)
# =============================================================
change_language() {
    clear
    echo "-----------------------------------------"
    echo "$(echo_msg menu_lang)"
    echo "-----------------------------------------"
    echo " 1) English"
    echo " 2) Русский"
    echo " 3) 日本語"
    echo
    echo "-----------------------------------------"

    read -rp "$(echo_msg sel_opt) " choice

    case "$choice" in
        1) APP_LANG="en" ;;
        2) APP_LANG="ru" ;;
        3) APP_LANG="ja" ;;
        *)
            warn menu_invalid_choice
            return
            ;;
    esac

    export APP_LANG       # теперь APP_LANG доступен всем скриптам
    load_messages        # подгружаем новые сообщения под выбранный язык
    echo "-----------------------------------------"
    info menu_language_set "$APP_LANG"
    echo
}


# --- Главное меню ---
main_menu() {
    while true; do
        clear
        echo "========================================="
        echo "   Reincarnation Backup Kit — $(echo_msg menu_main)"
        echo "========================================="
        echo " 1) $(say menu_backup)"
        echo " 2) $(say menu_restore)"
        echo " 3) $(say menu_cron_jobs)"
        echo " 4) $(say menu_media)"
        echo " 5) $(say menu_tools)"
        echo " 6) $(say menu_logs)"
        echo " 7) $(say menu_settings)"
        echo
        echo " 0) $(say menu_exit)"
        echo "-----------------------------------------"
        read -rp "$(echo_msg menu_sel_opt)" choice
        case "$choice" in
            1) backup_menu ;;
            2) restore_menu ;;
            3) cron_menu ;;
            4) media_menu ;;
            5) tools_menu ;;
            6) logs_menu ;;
            7) settings_menu ;;
            0) echo_msg menu_exit; exit 0 ;;
            *) warn menu_invalid_choice ;;
        esac
    done
}

# --- Подменю Backup ---
backup_menu() {
    while true; do
        clear
        echo "-----------------------------------------"
        echo_msg menu_backup_options
        echo "-----------------------------------------"
        info system "$DISTRO_ID $DISTRO_VER"
        echo "$(say menu_backup_system_full)"
        echo "$(say menu_backup_system_manual)"
        echo
        echo "$(say menu_userdata)" 
        echo "$(say menu_backup_firefox)"
        echo "$(say menu_backup_userdata)"
        echo "$(say menu_backup_full)"
        echo
        echo "$(say menu_back_main)"
        echo "-----------------------------------------"
        read -rp "$(echo_msg menu_sel_opt)" choice
        case "$choice" in
            1) bash "$SYS_BACKUP" full ;;      # Создаём full backup
            2) bash "$SYS_BACKUP" manual ;;    # Создаём manual backup
            3)
               if [[ -f "$FIREFOX_BACKUP_RESTORE" ]]; then
                   # Запускаем backup_firefox_profile из внешнего скрипта в отдельном процессе
                   "$FIREFOX_BACKUP_RESTORE" backup_firefox_profile
               else
                   error menu_firefox_script_not_found "$FIREFOX_BACKUP_RESTORE"
               fi
               ;;
            4) bash "$USER_BACKUP" ;;
            5) bash "$USER_BACKUP" --fresh ;;
            0) return ;;
            *) warn menu_invalid_choice ;;
        esac
        read -rp "$(echo_msg menu_press_return)"
    done
}


# --- Подменю Restore ---
restore_menu() {
    while true; do
        clear
        echo "-----------------------------------------"
        echo_msg menu_restore_options
        echo "-----------------------------------------"
        info menu_system "$DISTRO_ID $DISTRO_VER"
        echo
        echo "$(say menu_recover_acconts)"     # Restore user accounts
        echo "$(say menu_restore_system_full)"      # Incremental restore of system packages
        echo "$(say menu_restore_system_manual)"    # Manual restore of system       
        echo
        echo "$(say menu_userdata)" 
        echo "$(say menu_restore_firefox)"          # Restore Firefox profile
        echo "$(say menu_restore_userdata)"         # Restore userdata
        echo
        echo "$(say menu_back_main)"                # Back to main menu
        echo "-----------------------------------------"
        read -rp "$(echo_msg menu_sel_opt)" choice

        case "$choice" in
            1)  
               MAINT_DIR="$(dirname "$0")/maintenance"
               bash "$MAINT_DIR/install-man.sh"
               ;;
            2) bash "$SYS_RESTORE" full ;;              # default
            3) bash "$SYS_RESTORE" manual ;;       # ручной режим
            4)
               if [[ -f "$FIREFOX_BACKUP_RESTORE" ]]; then
                   # Запускаем backup_firefox_profile из внешнего скрипта в отдельном процессе
                   "$FIREFOX_BACKUP_RESTORE" restore_firefox_profile
               else
                   error menu_firefox_script_not_found "$FIREFOX_BACKUP_RESTORE"
               fi
               ;;
            5) bash "$USER_RESTORE" ;;             # restore userdata
            0) return ;;
            *) warn menu_invalid_choice ;;
        esac
        read -rp "$(echo_msg menu_press_return)"
    done
}

# --- Подменю Cron ---
cron_menu() {
    clear
    echo "-----------------------------------------"
    echo "$(say menu_manage_cron)"
    echo "-----------------------------------------"
    echo "$(say menu_cron)"
    echo "$(say menu_clean_backup_logs)"
    echo "$(say menu_remove_cron_task)"
    echo
    echo "$(say menu_back_main)"
    echo "-----------------------------------------"
    read -rp "$(echo_msg menu_sel_opt)" choice
    case "$choice" in
        1)
            # Ввод времени для CRON
            read -rp "$(echo_msg menu_enter_time)" CRON_TIME

            # Выбор пользователя через библиотеку
            if select_user "$(say menu_cron_shedule)"; then
                # Для CRON берём первого выбранного пользователя
                CRON_USER="${SELECTED_USERS[0]}"

                if [[ -n "$CRON_TIME" && -n "$CRON_USER" ]]; then
                    info menu_adding_cron "$CRON_TIME" "$CRON_USER"
                    bash "$CRON_BACKUP" "$CRON_TIME" "$CRON_USER"
                    echo_msg menu_cron_job_installed
                else
                    error menu_empty_entered
                fi
            else
                # Если пользователь не выбран
                error menu_empty_entered
            fi

            read -rp "$(echo_msg menu_press_continue)"
            ;;
      
        2) bash "$CLEAN_LOGS" ;;
        3) bash "$REMOVE_CRON" ;;
        0) return ;;
        *) warn menu_invalid_choice ;;
    esac
    echo
    read -rp "$(echo_msg menu_press_return)"
}

# --- Подменю Media ---
media_menu() {
    clear
    echo "-----------------------------------------"
    echo "$(say menu_media)"
    echo "-----------------------------------------"
    echo "$(say menu_install_flatpak)"
    echo "$(say menu_install_nvidia)"
    echo "$(say menu_checks_gpu)"
    echo "$(say menu_install_apt)"
    echo
    echo "$(say menu_back_main)"
    echo "-----------------------------------------"
    read -rp "$(echo_msg menu_sel_opt)" choice
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
                 info menu_apt_installed
              ;;
              10)
                 warn menu_apt_busy
                 info menu_returned_main_menu
              ;;
              *)
                 error menu_installation_error "$status"
                 info menu_returned_menu
              ;;
          esac
        ;;
        0) return ;;
        *) warn menu_invalid_choice ;;
    esac
    echo
    read -rp "$(echo_msg menu_press_return)"
}

# --- Подменю Tools ---
tools_menu() {
    clear
    echo "-----------------------------------------"
    echo "$(say menu_tools)"
    echo "-----------------------------------------"
    echo "$(say menu_archive)"
    echo "$(say menu_last_archive)"
    echo
    echo "$(say menu_system)"
    echo "$(say menu_system_mounts)"
    echo "$(say menu_hdd_setup)"
    echo "$(say menu_setup_symlinks)"
    echo
    echo "$(say menu_back_main)"
    echo "-----------------------------------------"
    read -rp "$(say menu_sel_opt)" choice
    case "$choice" in
        1)
           if select_user "$(say menu_check_archive)"; then
               for user in "${SELECTED_USERS[@]}"; do
                   sudo "$LAST_ARCHIVE" "$user"
               done
           fi
           ;;
        2) "$SYSTEM_MOUNTS" ;;
        3) "$HDD_SETUP" ;;
        4) "$SEIUP_SYMLINKS" ;;
        0) return ;;
        *) warn menu_invalid_choice ;;
    esac
    echo
    read -rp "$(echo_msg menu_press_return)"
}

logs_menu() {
    clear
    echo "-----------------------------------------"
    echo "$(say menu_log_files)"
    echo "-----------------------------------------"
    echo "$(say menu_list_logs)"
    echo "$(say menu_in_ranger)"
    echo "$(say mrnu_sel_file)"
    echo "$(say menu_exit_file)"
    echo "$(say menu_exit_ranger)"
    echo "-----------------------------------------"

    read -rp "$(echo_msg menu_run_return) " choice

    case "$choice" in
        "" )
            ranger /mnt/backups/logs || warn no_logs
            ;;
        q|Q )
            return
            ;;
        * )
            echo_msg menu_return_menu
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
        echo "$(say menu_change_language)"
        echo "$(say menu_backup_directories)"
        echo "$(say menu_manage_cuda)"
        echo
        echo "$(say menu_back_main)"
        echo "-----------------------------------------"
        read -rp "$(echo_msg menu_sel_opt)" choice
        case "$choice" in
            1)
                change_language # <-- здесь вызываем функцию переключения языка
                read -rp "$(echo_msg menu_press_continue)"
                ;;
            2)
                echo_msg menu_backupdir_not
                read -rp "$(echo_msg menu_press_continue)"
                ;;
            3)
                if [[ ! -x "$CUDA_SCRIPT" ]]; then
                   warn menu_checkcuda_not
                   read -rp "$(echo_msg menu_press_continue)"
                   break
                fi

                while true; do
                   clear
                   echo "-----------------------------------------"
                   echo "$(say menu_cuda_choice)"
                   echo "-----------------------------------------"
                   echo "$(say menu_cuda_check)"
                   echo "$(say menu_cuda_install)"
                   echo "$(say menu_cuda_uninstall)"
                   echo
                   echo "$(say menu_return)"
                   echo
                   echo "-----------------------------------------"
                   read -rp "$(echo_msg menu_choose_option) " cuda_choice
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
                        warn menu_invalid_choice
                        ;;
                   esac
                   echo
                   read -rp "$(echo_msg menu_press_continue)"
                   done
                   ;;
            0) return ;;
            *) warn menu_invalid_choice ;;
        esac
    done
}

# --- Запуск ---
main_menu

exit 0