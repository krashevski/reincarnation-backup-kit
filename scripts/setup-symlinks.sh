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
# ==============================================================
# setup-symlinks.sh — configures custom symbolic links
# Reincarnation Backup Kit — Messages Library
# MIT License — Copyright (c) 2025 Vladislav Krashevsky support ChatGPT
# --------------------------------------------------------------
# Creates directories on /mnt/storage and gracefully recreates symbolic links
# Log: ~/setup-symlinks.log
# ==============================================================

# --- Подключаем файл с сообщениями (messages.sh) ---
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/messages.sh"

# --- systemd-inhibit ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="Running restore" "$0" "$@"
fi

# --- Настройки ---
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/restore_workdir"
LOG_DIR="$BACKUP_DIR/logs"
BACKUP_NAME="$BACKUP_DIR/backup-ubuntu-22.04.tar.gz"
mkdir -p "$WORKDIR" "$LOG_DIR"
RUN_LOG="$LOG_DIR/setup-symlinks.log"
SYMLINKS=("$(say musik)" "$(say images)" "(say video)")
EXTRA_SYMLINKS=("shotcut:/mnt/shotcut" "backups:/mnt/backups")

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$RUN_LOG"
}

setup_link() {
    local name="$1"
    local target="$2"
    local link="$HOME/$name"

    # создаём каталог назначения
    if [ ! -d "$target" ]; then
        mkdir -p "$target"
        log "$(printf "${SG[${L}_create_catalog}" "$target")"
    fi

    # если уже есть правильная ссылка
    if [ -L "$link" ] && [ "$(readlink -f "$link")" = "$target" ]; then
        log "$(printf "$(say link_exists)" "$CRON_TIME" "$CRON_USER")"
        return
    fi

    # если каталог пустой
    if [ -d "$link" ] && [ -z "$(ls -A "$link")" ]; then
        rm -r "$link"
        ln -s "$target" "$link"
        log "$(printf "$(say replaced_empty)" "$CRON_TIME" "$CRON_USER")"
        return
    fi

    # если каталог не пустой — спросить
    if [ -d "$link" ] && [ -n "$(ls -A "$link")" ]; then
        read -p "${printf "$(say not_empty)" "$link"}" ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            rm -r "$link"
            ln -s "$target" "$link"
            log "${printf "$(say user_replace)" "$link" "$target"}"
        else
            log "$(printf "${MSG[${L}_user_refused}" "$link")"
        fi
        return
    fi

    # если ничего нет — просто создать ссылку
    if [ ! -e "$link" ]; then
        ln -s "$target" "$link"
        log "$(printf "$(say link_created)" "$link" "$target")"
    fi
}

# --- Основные ссылки ---
for dir in "${SYMLINKS[@]}"; do
    setup_link "$dir" "/mnt/storage/$dir"
done

# --- Дополнительные ссылки ---
for pair in "${EXTRA_SYMLINKS[@]}"; do
    name="${pair%%:*}"
    target="${pair##*:}"
    setup_link "$name" "$target"
done

log "$(say script_termination)"

