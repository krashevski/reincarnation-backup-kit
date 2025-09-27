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
# messages.sh
# Reincarnation Backup Kit — Messages Library
# Унифицированные сообщения для всех скриптов
# MIT License — Copyright (c) 2025 Vladislav Krashevsky support ChatGPT
# ==============================================================
# В каждом скрипте подключать:
# ----------------------------
# #!/bin/bash
# # 
# info "$(say backup_start)"
# # ...
# # С подставновкой одного значения
# warn "$(printf "${MSG[${L}_user_size]}" "$EXISTING_USER")"
# #
# # Интерактивный ввод с подставновкой значения
# read -rp "$(printf "${MSG[${L}_user_size]}" "$EXISTING_USER")" SIZE1
# # 
# # Подставновка двух значений
# info "${printf "$(say adding_cron)" "$CRON_TIME" "$CRON_USER"}"
# #
# ok "$(say backup_done)"
#
# # Подключаем файл с сообщениями (messages.sh)
# SCRIPT_DIR="$(dirname "$(realpath "$0")")"
# source "$SCRIPT_DIR/messages.sh"#
# =============================================================

# --- Colors ---
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARNING]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Language autodetect ---
L=${LANG_CHOICE:-ru}

declare -A MSG=(
    # ========== Русский ==========
    [ru_hello]="Привет, мир!"
    [ru_start]="Запуск"
    # hdd-setup-profiles.sh
    [ru_hdd_start]="Запуск разметки HDD и создания пользователей..."
    [ru_prompt_disk]="Введите имя HDD (например, sdb): "
    [ru_error_no_disk]="Устройство не найдено!"
    [ru_warn_delete]="⚠️ ВНИМАНИЕ: Все данные на диске будут удалены! Продолжить? (y/n): "
    [ru_prompt_user2]="Введите имя второго пользователя: "
    [ru_prompt_user3]="Введите имя третьего пользователя: "
    [ru_disk_size]="Размер выбранного диска: "
    [ru_user_size]="Сколько GB выделить для %s: "
    [ru_remaining]="Остаток: "
    [ru_error_size]="Сумма указанных размеров превышает размер диска!"
    [ru_creating_partitions]="Создание таблицы разделов..."
    [ru_formatting]="Форматирование разделов..."
    [ru_creating_user]="Создаю пользователя "
    [ru_user_exists]="Пользователь уже существует."
    [ru_fstab_exists]="fstab: запись уже существует, пропускаю."
    [ru_fstab_added]="fstab: добавлена запись для "
    [ru_done_disks_users]="Операция завершена. Диски смонтированы, пользователи настроены."
    [ru_restore_hint]="Для восстановления пользовательских данных используйте rsync-restore-userdata.sh"
    # menu.sh
    [ru_main_menu]="Главное меню"
    [ru_backup]="Резервное копирование"
    [ru_restore]="Восстановление"
    [ru_media]="Медиа"
    [ru_tools]="Инструменты"
    [ru_logs]="Просмотр логов"
    [ru_settings]="Настройки"
    [ru_exit]="Выход"
    [ru_selected]="Выбрано:"
    [ru_no_logs]="Логи не найдены."
    [ru_install_ranger]="Ranger не найден, установка..."
    [ru_failed_ranger]="Не удалось установить Ranger, возвращаемся к ls"
    [ru_sel_opt]=" Выберите вариант: "
    [ru_invalid_choice]="Неверный выбор, попробуйте еще раз."
    [ru_back_main]=" 0) Вернуться в главное меню"
    [ru_enter_time]="Введите время (ЧЧ:ММ): "
    [ru_enter_user]="Введите имя пользователя: "
    [ru_cron_installed]="Cron backup установлен."
    [ru_empty_entered]="Введены пустые параметры!"
    [ru_press_continue]="Нажмите Enter для продолжения..."
    [ru_press_return]="Нажмите Enter, чтобы вернуться..."
    [ru_list_logs]=" Вы увидите список log-файлов"
    [ru_in_ranger]=" в консольном браузере ranger."
    [ru_sel_file]=" - Выберите файл и нажмите Enter для просмотра файла."
    [ru_exit_file]=" - Нажмите CTRL+X для выхода из файла."
    [ru_exit_ranger]=" - Нажмите q для выхода из ranger."
    [ru_run_return]=" Нажмите Enter для запуска ranger... или введите q для возврата: "
    [ru_return_menu]="Возврат в меню..."
    [ru_lang_not]="Выбор языка пока не реализован"
    [ru_backupdir_not]="Настройка каталогов бэкапов пока не реализована"
    [ru_checkcuda_not]="Скрипт check-cuda-tools.sh не найден или не исполняемый."
    [ru_adding_cron]="Добавление cron-задачи: %s для %s"
    # common
    [ru_backup_start]="Запуск резервного копирования..."
    [ru_backup_pkgs]="Резервное копирование пакетов и репозиториев..."
    [ru_backup_done]="Резервное копирование завершено успешно!"
    [ru_pkgs_done]="Системные пакеты сохранены."
    [ru_create_archive]="Создание архива"
    [ru_archive_exists]="Архив уже существует. Переименовываю в .old"
    [ru_archive_done]="Архив создан"
    [ru_archive_fail]="Ошибка при создании архива"
    [ru_done]="Завершено успешно!"
    [ru_run_sudo]="Скрипт нужно запускать с правами root (sudo)"
    [ru_change_owner]="Меняю владельца каталога на"
    [ru_no_dir]="Каталог не существует, проверьте монтирование."
    [ru_dir_missing]="Каталог не найден. Смонтируйте диск!"
    [ru_clean_tmp]="Очистка временных файлов..."
    [ru_tmp_cleaned]="Временные файлы очищены."
    [ru_sel_opt]="Выберите опцию: "
    [ru_enter_time]="Введите время для cron-задачи: "
    [ru_enter_user]="Введите имя пользователя: "
    [ru_cron_installed]="Cron-задача установлена."
    [ru_extracting]="Извлечение архива..."
    [ru_extract_ok]="Архив успешно извлечён."
    [ru_extract_fail]="Ошибка при извлечении архива."
    [ru_archive_restored]="Архив восстановлен."
    [ru_restore_start]="Запуск восстановления..."
    [ru_restore_done]="Восстановление завершено успешно!"
    [ru_restore_fail]="Ошибка восстановления."
    [ru_cuda_not_found]="CUDA не найдена."
    [ru_cuda_ok]="CUDA установлена и доступна."
    [ru_gpu_not_found]="GPU не найдено."
    [ru_gpu_ok]="GPU доступен."
    [ru_media_install_start]="Установка мультимедиа инструментов..."
    [ru_media_install_done]="Мультимедиа инструменты установлены."
    [ru_cron_removed]="Cron-задача удалена."
    [ru_log_enabled]="Логирование включено. Подробный лог: "
    [ru_logs_cleaned]="Логи резервного копирования очищены."
    [ru_install_start]="Установка..."
    [ru_install_done]="Установка завершена."

    # ========== English ==========
    [en_hello]="Hello, world!"
    [en_start]="Starting"
    # hdd-setup-profiles.sh 
    [en_hdd_start]="Starting HDD setup and user creation..."
    [en_prompt_disk]="Enter HDD name (e.g., sdb): "
    [en_error_no_disk]="Device not found!"
    [en_warn_delete]="⚠️ WARNING: All data on the disk will be erased! Continue? (y/n): "
    [en_prompt_user2]="Enter name of second user: "
    [en_prompt_user3]="Enter name of third user: "
    [en_disk_size]="Selected disk size: "
    [en_user_size]="How many GB to allocate for %s: "
    [en_remaining]="Remaining: "
    [en_error_size]="Sum of specified sizes exceeds disk size!"
    [en_creating_partitions]="Creating partition table..."
    [en_formatting]="Formatting partitions..."
    [en_creating_user]="Creating user "
    [en_user_exists]="User already exists."
    [en_fstab_exists]="fstab entry already exists, skipping."
    [en_fstab_added]="fstab: added entry for "
    [en_done_disks_users]="Operation completed. Disks mounted, users configured."
    [en_restore_hint]="To restore user data, use rsync-restore-userdata.sh"
    # menu.sh
    [en_main_menu]="Main Menu"
    [en_backup]="Backup"
    [en_restore]="Restore"
    [en_media]="Media"
    [en_tools]="Tools"
    [en_logs]="View Logs"
    [en_settings]="Settings"
    [en_exit]="Exit"
    [en_selected]="Selected:"
    [en_incorrect_choice]="Incorrect choice, please try again"
    [en_no_logs]="No logs found."
    [en_install_ranger]="Ranger not found, installing..."
    [en_failed_ranger]="Failed to install ranger, falling back to ls"
    [en_sel_opt]=" Select an option: "
    [en_invalid_choice]="Invalid choice, try again."
    [en_back_main]=" 0) Back to main menu"
    [en_enter_time]="Enter time (HH:MM): "
    [en_enter_user]="Enter username: "
    [en_cron_installed]="Cron backup installed."
    [en_empty_entered]="Empty values entered."
    [en_press_continue]="Press Enter to continue"
    [en_press_return]="Press Enter to return to menu"
    [en_invalid_choice]="Invalid choice, try again"
    [en_list_logs]="You will see a list of log files"
    [en_in_ranger]=" in the ranger console browser."
    [en_sel_file]=" - Select a file and press Enter to view the file."
    [en_exit_file]=" - Press CTRL+X to exit the file."
    [en_exit_ranger]=" - Press q to exit ranger."
    [en_run_return]=" Press Enter to run ranger... or type q to return: "
    [en_return_menu]="Return to menu..."
    [en_lang_not]="Language selection is not yet implemented"
    [en_backupdir_not]="Backup directory configuration is not yet implemented"
    [en_checkcuda_not]="Script check-cuda-tools.sh not found or not executable."
    [en_adding_cron]="Adding cron job: %s for %s"
    # common
    [en_backup_start]="Starting backup..."
    [en_backup_done]="Backup completed successfully!"
    [en_backup_pkgs]="Backing up packages and repositories..."
    [en_pkgs_done]="System packages saved."
    [en_create_archive]="Creating archive"
    [en_archive_exists]="Archive already exists. Renaming to .old"
    [en_archive_done]="Archive created"
    [en_archive_fail]="Archive creation failed"
    [en_done]="Completed successfully!"
    [en_run_sudo]="The script must be run with root rights (sudo)"
    [en_change_owner]="Changing owner of directory to"
    [en_no_dir]="Directory does not exist, check mount point."
    [en_dir_missing]="Directory not found. Please mount the disk!"
    [en_clean_tmp]="Cleaning temporary files..."
    [en_tmp_cleaned]="Temporary files cleaned."
    [en_sel_opt]="Select option: "
    [en_enter_time]="Enter time for cron job: "
    [en_enter_user]="Enter username: "
    [en_cron_installed]="Cron job installed."
    [en_invalid_choice]="Invalid choice, try again"
    [en_extracting]="Extracting archive..."
    [en_extract_ok]="Archive extracted successfully."
    [en_extract_fail]="Archive extraction failed."
    [en_archive_restored]="Archive restored."
    [en_restore_start]="Starting restore..."
    [en_restore_done]="Restore completed successfully!"
    [en_restore_fail]="Restore failed."
    [en_cuda_not_found]="CUDA not found."
    [en_cuda_ok]="CUDA installed and available."
    [en_gpu_not_found]="GPU not found."
    [en_gpu_ok]="GPU available."
    [en_media_install_start]="Installing media tools..."
    [en_media_install_done]="Media tools installed."
    [en_cron_removed]="Cron job removed."
    [en_log_enabled]="Logging enabled. Detailed log: "
    [en_logs_cleaned]="Backup logs cleaned."
    [en_install_start]="Installing..."
    [en_install_done]="Installation completed."
)

# --- say function ---
say() {
    local key="$1"; shift
    local msg="${MSG[${L}_${key}]:-$key}"
    if [[ $# -gt 0 ]]; then
        printf "$msg" "$@"
    else
        echo "$msg"
    fi
}

