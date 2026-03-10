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
source "$LIB_DIR/guards-inhibit.sh"
source "$LIB_DIR/system_detect.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

require_root || return 1
# inhibit_run "$0" "$@"

# --- Args parsing ---
OPERATION=""
FRESH_MODE=false

for arg in "$@"; do
    case "$arg" in
        backup|restore) OPERATION="$arg" ;;
        --fresh) FRESH_MODE=true ;;
        *) warn unknown_arg "$arg" ;;
    esac
done

if [[ -z "$OPERATION" ]]; then
    warn baresud_usage "$0"
    info baresud_example_backup "$0"
    info baresud_example_restore "$0"
    exit 1
fi

warn baresud_warn_time

# === Paths ===
BACKUP_DIR="${BACKUP_DIR:-/mnt/backups/REBK}"
BR_WORKDIR="$BACKUP_DIR/bares_workdir"
USERDATA_DIR="$BR_WORKDIR/user_data"
ARCHIVE_DIR="$BR_WORKDIR/tar_archive"
LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$BACKUP_DIR" "$BR_WORKDIR" "$USERDATA_DIR" "$ARCHIVE_DIR" "$LOG_DIR"
RUN_LOG="$LOG_DIR/bares-userdata-$(date +%F-%H%M%S).log"

exec > >(tee -a "$RUN_LOG") 2>&1

# === Excludes ===
EXCLUDES=(
    ".cache" "Downloads" "Trash" ".thumbnails"
    ".mozilla/firefox/*/cache2"
    ".config/google-chrome/Default/Cache"
    ".var/app/*/cache" "Thumbs.db" ".DS_Store" ".gvfs/"
    ".local/share/baloo" ".local/share/tracker"
    ".thunderbird/*/Cache" ".thunderbird/*/OfflineCache"
    "lost+found"
)

RSYNC_EXCLUDES=()
for e in "${EXCLUDES[@]}"; do
    RSYNC_EXCLUDES+=(--exclude="$e")
done

# === Functions ===
run_rsync_backup() {
    local SRC="$1"
    local DST="$USERDATA_DIR/$2"
    mkdir -p "$DST"
    info baresud_rsync_backup "$SRC" "$DST"
    rsync -aHAX --numeric-ids --info=progress2 --ignore-errors --update "${RSYNC_EXCLUDES[@]}" \
        "$SRC/" "$DST/"
}

fresh_backup_dir() {
    local user_backup_dir="$1"

    
    # --- Защита: путь должен быть внутри USERDATA_DIR ---
    if [[ "$user_backup_dir" != "$USERDATA_DIR/"* ]]; then
        error "Refusing to delete '$user_backup_dir': outside USERDATA_DIR!"
        return 1
    fi

    if [ -d "$user_backup_dir" ]; then
        warn baresud_fresh_remove "$user_backup_dir"
        rm -rf "$user_backup_dir"
    fi
    mkdir -p "$user_backup_dir"
}

run_tar_backup() {
    local SRC="$1"      # /home/$NAME
    local NAME="$2"     # имя пользователя
    local ARCHIVE="$ARCHIVE_DIR/${NAME}_$(date +%F-%H%M%S).tar.gz"

    info baresud_changed_files "$SRC" "$ARCHIVE"

    # получаем список изменившихся файлов с путями относительно $SRC
    mapfile -t changed_files < <(
        cd "$SRC" && find . -type f -newermt "@$(stat -c %Y "$USERDATA_DIR/$NAME" 2>/dev/null || echo 0)"
    )

    if [ ${#changed_files[@]} -eq 0 ]; then
        warn baresud_no_new_files "$SRC"
        return 0
    fi

    # архивируем с сохранением структуры относительно имени пользователя
    cd "$SRC"
    printf '%s\n' "${changed_files[@]}" | tar --null -T - -czf "$ARCHIVE"

    ok baresud_archive_created "$ARCHIVE"
}

run_backup() {
    local NAME="$1"
    local SRC="/home/$NAME"
    if [ ! -d "$SRC" ]; then
        warn baresud_dir_missing "$SRC"
        return 0
    fi
    
    local DST="$USERDATA_DIR/$NAME"
    if $FRESH_MODE; then
        fresh_backup_dir "$DST"
    fi

    run_rsync_backup "$SRC" "$NAME"
    run_tar_backup "$SRC" "$NAME"
    ok baresud_backup_done "$NAME"
}

run_restore() {
    local NAME="$1"
    local DST="/home/$NAME"

    if ! id "$NAME" &>/dev/null; then
        warn baresud_user_not "$NAME"
        return 1
    fi
    [ -d "$DST" ] || mkdir -p "$DST"

    local HDD_MOUNT="/mnt/storage"
    mkdir -p "$HDD_MOUNT"

    local SRC="$USERDATA_DIR/$NAME"
    if [ ! -d "$SRC" ]; then
        warn baresud_no_backup "$NAME"
        return 1
    fi

    # --- соответствия: имя каталога в домашней папке -> рабочий каталог на /mnt/storage
    # Можно добавлять любые языки, например японский
    local LARGE_DIRS_MAP=(
        "Видео:Videos"
        "Музыка:Music"
        "Изображения:Pictures"
        "Videos:Videos"
        "Music:Music"
        "Pictures:Pictures"
        "ビデオ:Videos"
        "音楽:Music"
        "画像:Pictures"
    )

    # Создаём хэш для быстрого поиска
    declare -A LARGE_DIRS_HASH
    for mapping in "${LARGE_DIRS_MAP[@]}"; do
        IFS=":" read -r USER_NAME TARGET_NAME <<< "$mapping"
        LARGE_DIRS_HASH["$USER_NAME"]="$TARGET_NAME"
    done

    info baresud_rsync_restore "$SRC" "$DST"

    # --- восстанавливаем директории
    while IFS= read -r -d '' item; do
        BASENAME=$(basename "$item")

        # Определяем куда восстанавливать
        if [[ -n "${LARGE_DIRS_HASH[$BASENAME]:-}" ]]; then
            # большой каталог → HDD
            DST_DIR="$HDD_MOUNT/${LARGE_DIRS_HASH[$BASENAME]}"
            mkdir -p "$DST_DIR"
        else
            # всё остальное → домашняя папка
            DST_DIR="$DST/$BASENAME"
            mkdir -p "$DST_DIR"
        fi

        # rsync: каталоги и файлы
        if [ -d "$item" ]; then
            rsync -aHAX --numeric-ids --info=progress2 --ignore-errors --update --ignore-existing \
                "${RSYNC_EXCLUDES[@]}" \
                "$item/" "$DST_DIR/"
        elif [ -f "$item" ]; then
            rsync -aHAX --numeric-ids --info=progress2 --ignore-errors --update --ignore-existing \
                "${RSYNC_EXCLUDES[@]}" \
                "$item" "$DST_DIR/"
        fi
    done < <(find "$SRC" -mindepth 1 -maxdepth 1 -print0)

    # --- восстановление последнего tar-архива без больших каталогов
    if [[ -n "$tarf" ]]; then
        info baresud_extracting_archive "$tarf"
        # создаём временный список файлов для извлечения
        TMP_LIST=$(mktemp)
        tar -tzf "$tarf" | while read -r f; do
            BASENAME=$(echo "$f" | cut -d/ -f1)
            if [[ -z "${LARGE_DIRS_HASH[$BASENAME]:-}" ]]; then
                echo "$f"
            fi
        done > "$TMP_LIST"

       # извлекаем только "малые" файлы/каталоги
       pv "$tarf" |  tar -xvz -C "$DST" --keep-newer-files -T "$TMP_LIST" -f "$tarf"
       rm -f "$TMP_LIST"
    fi
    
    ok baresud_restore_done "$NAME"
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
    error baresud_not_mounted
    exit 1
fi

if ! mountpoint -q /mnt/storage; then
    error baresud_not_storage
    exit 1
fi

users=()
for d in /home/*; do
    [ -d "$d" ] && users+=("$(basename "$d")")
done
if [ ${#users[@]} -eq 0 ]; then
    error baresud_no_users
    exit 1
fi

echo_msg baresud_user_list
for i in "${!users[@]}"; do
    printf "  %d) %s\n" "$((i+1))" "${users[$i]}"
done
echo -n "$(echo_msg baresud_select_user "$OPERATION") "
read -r -a selections

status=0
for sel in "${selections[@]}"; do
    index=$((sel-1))
    if [[ $index -ge 0 && $index -lt ${#users[@]} ]]; then
        [[ "$OPERATION" == "backup" ]] && run_backup "${users[$index]}" || run_restore "${users[$index]}"
    else
        warn baresud_invalid_choice "$sel"
        status=1
    fi
done

if [ $status -eq 0 ]; then
    ok baresud_done "$OPERATION"
else
    error baresud_some_failed "$OPERATION" "$RUN_LOG"
fi

echo "=============================================================" | tee -a "$RUN_LOG"

exit $status