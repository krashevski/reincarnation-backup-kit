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
backup-restore-userdata.sh v1.6 (bilingual RU/EN)
Hybrid backup: rsync (mirror) + tar (changed files)
Part of Backup Kit — minimal restore script with logging
-------------------------------------------------------------
Features:
- Detects all users in /home
- Allows selecting users for backup/restore
- Rsync for fast mirror backups
- Tar for archiving changed files (long-term storage)
- pv shows progress of tar archiving
- Progress via rsync --info=progress2
- Logging with tee (stdout+stderr)
- Optional X-session warning
- Restore skips junk files and keeps newer files
- Handles spaces/Unicode in paths
=============================================================
DOC

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

# --- Выбор языка ---
determine_language() {
    # Сначала проверяем LANG_CHOICE
    if [[ -n "${LANG_CHOICE:-}" ]]; then
        echo "$LANG_CHOICE"
        return
    fi

    # Если через sudo — смотрим LANG оригинального пользователя
    if [[ -n "${SUDO_USER:-}" ]]; then
        local user_lang
        user_lang=$(sudo -u "$SUDO_USER" bash -c 'echo "${LANG:-}"')
        if [[ "$user_lang" == ru* ]]; then
            echo "ru"
        else
            echo "en"
        fi
        return
    fi

    # Иначе берем LANG текущего пользователя
    if [[ "${LANG:-}" == ru* ]]; then
        echo "ru"
    else
        echo "en"
    fi
}

LANG_CHOICE=$(determine_language)

# --- Messages ---
declare -A MSG

MSG[en.error_root]="Script must be run as root (sudo)"
MSG[ru.error_root]="Скрипт нужно запускать с правами root (sudo)"

MSG[en.x_warning]="Running in graphical X-session. Local console recommended for accurate progress."
MSG[ru.x_warning]="Запуск в графической X-сессии. Рекомендуется локальная консоль для точного прогресса."

MSG[en.usage]="Usage: sudo %s [backup|restore]"
MSG[ru.usage]="Использование: sudo %s [backup|restore]"

MSG[en.example_backup]="Example: sudo %s backup — for backup"
MSG[ru.example_backup]="Пример: sudo %s backup — для резервного копирования"

MSG[en.example_restore]="Example: sudo %s restore — for restore"
MSG[ru.example_restore]="Пример: sudo %s restore — для восстановления"

MSG[en.warn_time]="Operation may take a long time."
MSG[ru.warn_time]="Операция может занять длительное время."

MSG[en.not_mounted]="/mnt/backups not mounted! Connect the disk and retry."
MSG[ru.not_mounted]="/mnt/backups не смонтирован! Подключите диск и повторите."

MSG[en.not_mounted_storage]="/mnt/storage not mounted! Connect the disk and retry."
MSG[ru.not_mounted_storage]="/mnt/storage не смонтирован! Подключите диск и повторите."

MSG[en.no_users]="No users found in /home"
MSG[ru.no_users]="Не найдено пользователей в /home"

MSG[en.user_list]="Available users:"
MSG[ru.user_list]="Доступные пользователи:"

MSG[en.select_user]="Enter user numbers for %s (space-separated): "
MSG[ru.select_user]="Введите номер(а) пользователя для %s (через пробел): "

MSG[en.invalid_choice]="Invalid selection: %s"
MSG[ru.invalid_choice]="Неверный выбор: %s"

MSG[en.rs_backup]="Rsync backup: %s -> %s"
MSG[ru.rs_backup]="Rsync бэкап: %s -> %s"

MSG[en.rs_restore]="Rsync restore: %s -> %s"
MSG[ru.rs_restore]="Rsync восстановление: %s -> %s"

MSG[en.no_backup_found]="No rsync backup found for %s"
MSG[ru.no_backup_found]="Rsync бэкап не найден для %s"

MSG[en.no_new_files]="No new files to archive in %s"
MSG[ru.no_new_files]="Нет новых файлов для архивации в %s"

MSG[en.archive_created]="Archive created: %s"
MSG[ru.archive_created]="Архив создан: %s"

MSG[en.extracting_archive]="Extracting latest archive %s"
MSG[ru.extracting_archive]="Распаковка последнего архива %s"

MSG[en.user_not_found]="User %s not found, skipping restore."
MSG[ru.user_not_found]="Пользователь %s не найден, пропуск восстановления."

MSG[en.dir_missing]="Directory %s does not exist, skipping."
MSG[ru.dir_missing]="Каталог %s не существует, пропускаем."

MSG[en.fresh_remove]="--fresh: removing old backup %s"
MSG[ru.fresh_remove]="--fresh: удаляю старый архив %s"

MSG[en.backup_done_user]="Backup completed for %s"
MSG[ru.backup_done_user]="Бэкап завершён для %s"

MSG[en.restore_done_user]="Restore completed for %s"
MSG[ru.restore_done_user]="Восстановление завершено для %s"

MSG[en.all_done]="All %s operations completed successfully."
MSG[ru.all_done]="Все операции %s завершены успешно."

MSG[en.some_failed]="Some %s operations failed. See log: %s"
MSG[ru.some_failed]="Некоторые операции %s не были выполнены. См. лог: %s"

MSG[en.run_sudo]="Скрипт нужно запускать с правами root (sudo)"
MSG[ru.run_sudo]="The script must be run with root rights (sudo)"

# --- Wrapper for localized messages ---
msg() {
    local key="$1"; shift
    local lookup="${LANG_CHOICE}.${key}"
    local text="${MSG[$lookup]:-}"

    # fallback на английский
    if [[ -z "$text" ]]; then
        lookup="en.${key}"
        text="${MSG[$lookup]:-}"
    fi

    if [[ -n "$text" ]]; then
       if (( $# )); then
          # строка может содержать %s → подставляем аргументы
          printf -- "$text\n" "$@"
       else
          printf "%s\n" "$text"
       fi
    else
       printf "⚠ Unknown message key: %s\n" "$lookup" >&2
    fi
}

# --- Проверка root только для команд, где нужны права ---
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "$(say run_sudo)"
        return 1
    fi
}

# --- X-session warning ---
if [[ -n "${DISPLAY:-}" && -z "${X_WARNING_SHOWN:-}" ]]; then
    export X_WARNING_SHOWN=1
    warn "$(msg x_warning)"
fi

# --- Args check ---
if [[ "${1:-}" != "backup" && "${1:-}" != "restore" ]]; then
    warn "$(msg usage "$0")"
    info "$(msg example_backup "$0")"
    info "$(msg example_restore "$0")"
    exit 1
fi
OPERATION=""
FRESH_MODE=false
for arg in "$@"; do
    case $arg in
        backup|restore) OPERATION="$arg" ;;
        --fresh) FRESH_MODE=true ;;
        *) warn "Unknown argument: $arg" ;;
    esac
done

if [[ -z "$OPERATION" ]]; then
    warn "$(msg usage "$0")"
    exit 1
fi

warn "$(msg warn_time)"

# === Paths ===
CURRENT_USER="${SUDO_USER:-$USER}"
BACKUP_DIR="${BACKUP_DIR:-/mnt/backups}"
BR_WORKDIR="$BACKUP_DIR/br_workdir"
USERDATA_DIR="$BR_WORKDIR/user_data"
ARCHIVE_DIR="$BR_WORKDIR/tar_archive"
LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$BACKUP_DIR" "$BR_WORKDIR" "$USERDATA_DIR" "$ARCHIVE_DIR" "$LOG_DIR"
RUN_LOG="$LOG_DIR/br-$(date +%F-%H%M%S).log"

exec > >(tee -a "$RUN_LOG") 2>&1

# === Excludes ===
EXCLUDES=(
    ".cache" "Downloads" "Trash" ".thumbnails"
    ".mozilla/firefox/*/cache2"
    ".config/google-chrome/Default/Cache"
    ".var/app/*/cache" "Thumbs.db" ".DS_Store" ".gvfs/"
    ".local/share/baloo" ".local/share/tracker"
    ".thunderbird/*/Cache" ".thunderbird/*/OfflineCache"
)

rsync_exclude() {
    local args=()
    for e in "${EXCLUDES[@]}"; do
        args+=(--exclude="$e")
    done
    echo "${args[@]}"
}

# === Functions ===
run_rsync_backup() {
    local SRC="$1"
    local DST="$USERDATA_DIR/$2"
    mkdir -p "$DST"
    info "$(msg rs_backup "$SRC" "$DST")"
    rsync -aHAX --numeric-ids --info=progress2 --ignore-errors --update $(rsync_exclude) \
        "$SRC/" "$DST/"
}

fresh_backup_dir() {
    local user_backup_dir="$1"
    if [ -d "$user_backup_dir" ]; then
        warn "$(msg fresh_remove "$user_backup_dir")"
        rm -rf "$user_backup_dir"
    fi
    mkdir -p "$user_backup_dir"
}

run_tar_backup() {
    local SRC="$1"
    local NAME="$2"
    local ARCHIVE="$ARCHIVE_DIR/${NAME}_$(date +%F-%H%M%S).tar.gz"

    info "Archiving changed files from $SRC -> $ARCHIVE"
    LAST_BACKUP_TIME=$(stat -c %Y "$USERDATA_DIR/$NAME" 2>/dev/null || echo 0)

    mapfile -t changed_files < <(find "$SRC" -type f -newermt "@$LAST_BACKUP_TIME")
    if [ ${#changed_files[@]} -eq 0 ]; then
        warn "$(msg no_new_files "$SRC")"
        return 0
    fi

    printf '%s\n' "${changed_files[@]}" | tar --null -T - -czf - 2>/dev/null | \
        pv -s $(du -sb "$SRC" | awk '{print $1}') > "$ARCHIVE"

    ok "$(msg archive_created "$ARCHIVE")"
}

run_backup() {
    local NAME="$1"
    local SRC="/home/$NAME"
    if [ ! -d "$SRC" ]; then
        warn "$(msg dir_missing "$SRC")"
        return 0
    fi
    
    local DST="$USERDATA_DIR/$NAME"
    if $FRESH_MODE; then
        fresh_backup_dir "$DST"
    fi

    run_rsync_backup "$SRC" "$NAME"
    run_tar_backup "$SRC" "$NAME"
    ok "$(msg backup_done_user "$NAME")"
}

run_restore() {
    local NAME="$1"
    local DST="/home/$NAME"
    local LARGE_DIRS=("Videos" "Pictures" "Music" "Видео" "Изображения" "Музыка")

    if ! id "$NAME" &>/dev/null; then
        warn "$(msg user_not_found "$NAME")"
        return 1
    fi

    [ -d "$DST" ] || mkdir -p "$DST"
    HDD_MOUNT="/mnt/storage"
    mkdir -p "$HDD_MOUNT"

    SRC="$USERDATA_DIR/$NAME"
    if [ -d "$SRC" ]; then
        info "$(msg rs_restore "$SRC" "$DST")"
        while IFS= read -r -d '' item; do
            BASENAME=$(basename "$item")
            if [ -d "$item" ]; then
                DST_DIR="$DST/$BASENAME"
                [[ " ${LARGE_DIRS[*]} " == *" $BASENAME "* ]] && DST_DIR="$HDD_MOUNT/$BASENAME"
                rsync -aHAX --numeric-ids --info=progress2 --ignore-errors --update --ignore-existing $(rsync_exclude) \
                    "$item/" "$DST_DIR/"
            elif [ -f "$item" ]; then
                rsync -aHAX --numeric-ids --info=progress2 --ignore-errors --update --ignore-existing $(rsync_exclude) \
                    "$item" "$DST/"
            fi
        done < <(find "$SRC" -mindepth 1 -maxdepth 1 -print0)
    else
        warn "$(msg no_backup_found "$NAME")"
    fi
    
    # Last archive
    tarf=$(ls -t "$ARCHIVE_DIR/${NAME}"*.tar.gz 2>/dev/null | head -n1)
    if [[ -n "$tarf" ]]; then
        info "$(msg extracting_archive "$tarf")"
        pv "$tarf" | tar -xzv --keep-newer-files -C "$DST"
    fi

    ok "$(msg restore_done_user "$NAME")"
}

# === Parse flags ===
FRESH_MODE=false
for arg in "$@"; do
  case $arg in
    --fresh)
      FRESH_MODE=true
      ;;
  esac
done

# === Checks ===
if ! mountpoint -q /mnt/backups; then
    error "$(msg not_mounted)"
    exit 1
fi

if ! mountpoint -q /mnt/storage; then
    error "$(msg not_mounted_storage)"
    exit 1
fi

users=()
for d in /home/*; do
    [ -d "$d" ] && users+=("$(basename "$d")")
done
if [ ${#users[@]} -eq 0 ]; then
    error "$(msg no_users)"
    exit 1
fi

echo "$(msg user_list)"
for i in "${!users[@]}"; do
    printf "  %d) %s\n" "$((i+1))" "${users[$i]}"
done
printf "$(msg select_user "$OPERATION")"
read -r -a selections

status=0
for sel in "${selections[@]}"; do
    index=$((sel-1))
    if [[ $index -ge 0 && $index -lt ${#users[@]} ]]; then
        [[ "$OPERATION" == "backup" ]] && run_backup "${users[$index]}" || run_restore "${users[$index]}"
    else
        warn "$(msg invalid_choice "$sel")"
        status=1
    fi
done

if [ $status -eq 0 ]; then
    ok "$(msg all_done "$OPERATION")"
else
    error "$(msg some_failed "$OPERATION" "$RUN_LOG")"
fi

exit $status
