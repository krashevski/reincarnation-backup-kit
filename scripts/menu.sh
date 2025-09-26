#!/bin/bash
# =============================================================
# Reincarnation Backup Kit — Text Menu Interface (draft)
# MIT License — Copyright (c) 2025 Vladislav Krashevsky
# =============================================================

set -euo pipefail

# --- Цвета ---
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# === Язык ===
LANG_CHOICE="${LANG_CHOICE:-ru}"  # можно менять извне
declare -A MSG_RU MSG_EN
MSG_RU=(
    [main_menu]="Главное меню"
    [backup]="Резервное копирование"
    [restore]="Восстановление"
    [logs]="Просмотр логов"
    [exit]="Выход"
    [incorrect_choice]="Неверный выбор, попробуйте снова"
    [run_sudo]="Скрипт нужно запускать с правами root (sudo)"
    [no_logs]="Логи не найдены."
    [install_ranger]="Ranger не найден, установка..."
    [failed_ranger]="Не удалось установить Ranger, возвращаемся к ls"
    [sel_opt]=" Выберите вариант: "
    [invalid_choice]="Неверный выбор, попробуйте еще раз."
    [back_main]=" 0) Вернуться в главное меню"
    [enter_time]="Введите время (ЧЧ:ММ): "
    [enter_user]="Введите имя пользователя: "
    [cron_installed]="Cron backup установлен."
    [empty_entered]="Введены пустые параметры!"
    [press_continue]="Нажмите Enter для продолжения..."
    [press_return]="Нажмите Enter, чтобы вернуться..."
    [list_logs]=" Вы увидите список log-файлов"
    [in_ranger]=" в консольном браузере ranger."
    [sel_file]=" - Выберите файл и нажмите Enter для просмотра файла."
    [exit_file]=" - Нажмите CTRL+X для выхода из файла."
    [exit_ranger]=" - Нажмите q для выхода из ranger."
    [run_return]=" Нажмите Enter для запуска ranger... или введите q для возврата: "
    [return_menu]="Возврат в меню..."
    [lang_not]="Выбор языка пока не реализован"
    [backupdir_not]="Настройка каталогов бэкапов пока не реализована"
    [checkcuda_not]="Скрипт check-cuda-tools.sh не найден или не исполняемый."
    [adding_cron]="Добавление cron-задачи: %s для %s"
)
MSG_EN=(
    [main_menu]="Main Menu"
    [backup]="Backup"
    [restore]="Restore"
    [logs]="View Logs"
    [exit]="Exit"
    [incorrect_choice]="Incorrect choice, please try again"
    [run_sudo]="The script must be run with root rights (sudo)"
    [no_logs]="No logs found."
    [install_ranger]="Ranger not found, installing..."
    [failed_ranger]="Failed to install ranger, falling back to ls"
    [sel_opt]=" Select an option: "
    [invalid_choice]="Invalid choice, try again."
    [back_main]=" 0) Back to main menu"
    [enter_time]="Enter time (HH:MM): "
    [enter_user]="Enter username: "
    [cron_installed]="Cron backup installed."
    [empty_entered]="Empty parameters entered!"
    [press_continue]="Press Enter to continue..."
    [press_return]="Press Enter to return..."
    [list_logs]="You will see a list of log files"
    [in_ranger]=" in the ranger console browser."
    [sel_file]=" - Select a file and press Enter to view the file."
    [exit_file]=" - Press CTRL+X to exit the file."
    [exit_ranger]=" - Press q to exit ranger."
    [run_return]=" Press Enter to run ranger... or type q to return: "
    [return_menu]="Return to menu..."
    [lang_not]="Language selection is not yet implemented"
    [backupdir_not]="Backup directory configuration is not yet implemented"
    [checkcuda_not]="Script check-cuda-tools.sh not found or not executable."
    [adding_cron]="Adding cron job: %s for %s"
)
say() {
    local key="$1"
    case "$LANG_CHOICE" in
        ru) echo "${MSG_RU[$key]}" ;;
        en) echo "${MSG_EN[$key]}" ;;
        *) echo "${MSG_EN[$key]}" ;; # по умолчанию EN
    esac
}

# --- Проверка root только для команд, где нужны права ---
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "$(say run_sudo)"
        return 1
    fi
}

# === Главное меню ===
main_menu() {
    while true; do
        clear
        echo "===================================="
        echo "       $(say main_menu)"
        echo "===================================="
        echo "1) $(say backup)"
        echo "2) $(say restore)"
        echo "3) $(say logs)"
        echo "0) $(say exit)"
        echo "------------------------------------"
        read -rp "Select an option: " choice
        case "$choice" in
            1) info "Выбрано: $(say backup)" ;;
            2) info "Выбрано: $(say restore)" ;;
            3) info "Выбрано: $(say logs)" ;;
            0) ok "$(say exit)"; exit 0 ;;
            *) error "$(say incorrect_choice)" ;;
        esac
        read -rp "Press Enter to continue..."
    done
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
        echo "   Reincarnation Backup Kit — Main Menu"
        echo "========================================="
        echo " 1) Backup"
        echo " 2) Restore"
        echo " 3) Manage cron jobs"
        echo " 4) Media"
        echo " 5) Tools"
        echo " 6) Logs"
        echo " 7) Settings"
        echo " 0) Exit"
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
        1) "$LAST_ARCHIVE" ;;
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
        ranger /mnt/backups/logs || warn "No logs found."
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
                read -rp "Press Enter to continue..."
                ;;
            2)
                echo "$(say backupdir_not)"
                read -rp "Press Enter to continue..."
                ;;
            3)
                # Проверяем наличие скрипта
                CUDA_SCRIPT="$BIN_DIR/check-shotcut-gpu.sh"
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

