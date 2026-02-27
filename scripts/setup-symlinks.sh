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
# setup-symlinks.sh — Idempotent (Ansible-style)
# Reincarnation Backup Kit — Messages Library
# Unified messages for all scripts in english
# MIT License — Copyright (c) 2025 Vladislav Krashevsky support ChatGPT
# ==============================================================

set -euo pipefail

# --- Пути к библиотекам ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$BIN_DIR/lib"

# --- Подключение библиотек ---
source "$LIB_DIR/i18n.sh"
init_app_lang   # обязательно!

source "$LIB_DIR/logging.sh"
source "$LIB_DIR/user_home.sh"
source "$LIB_DIR/real_user.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/context.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

# root / inhibit здесь не используем
# require_root || return 1
# inhibit_run "$0" "$@"

# -------------------------------------------------------------
# 11. Paths
# -------------------------------------------------------------
BASE_DIR="/mnt/storage"
EXTRA_SYMLINKS=("shotcut:/mnt/shotcut" "backups:/mnt/backups")

# if [[ -n "${USER_HOME:-}" ]]; then
#     TARGET_HOME="$USER_HOME"
# elif [[ -n "${SUDO_USER:-}" ]]; then
#     TARGET_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
# else
#     TARGET_HOME="$HOME"
# fi

# [[ -z "$TARGET_HOME" || "$TARGET_HOME" == "/" ]] && {
#     error invalid_home "$TARGET_HOME"
#     exit 1
# }

# -------------------------------------------------------------
# 12. Data (NO say here!)
# -------------------------------------------------------------
declare -A TARGET_DIRS=(
    [music]="Music"
    [pictures]="Pictures"
    [videos]="Videos"
)

declare -A LINK_NAMES_ru=(
    [music]="Музыка"
    [pictures]="Изображения"
    [videos]="Видео"
)

declare -A LINK_NAMES_en=(
    [music]="Music"
    [pictures]="Pictures"
    [videos]="Videos"
)

declare -A LINK_NAMES_ja=(
    [music]="音楽"
    [pictures]="画像"
    [videos]="動画"
)

get_link_name() {
    local key="$1"
    case "$APP_LANG" in
        ru) echo "${LINK_NAMES_ru[$key]}" ;;
        ja) echo "${LINK_NAMES_ja[$key]}" ;;
        en|*) echo "${LINK_NAMES_en[$key]}" ;;
    esac
}

get_link_name() {
    local key="$1"
    case "$APP_LANG" in
        ru) echo "${LINK_NAMES_ru[$key]}" ;;
        en|*) echo "${LINK_NAMES_en[$key]}" ;;
    esac
}

# -------------------------------------------------------------
# 13. Idempotent FS helpers
# -------------------------------------------------------------

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        info slinks_dir_created "$dir"
    fi
}

ensure_symlink() {
    local link="$1"
    local target="$2"

    # already correct
#    if [[ -L "$link" && "$(readlink -f "$link")" == "$target" ]]; then
    if [[ -L "$link" && "$(realpath -m "$link")" == "$(realpath -m "$target")" ]]; then
        info slinks_ok "$link" "$target"
        return
    fi

    # empty dir → replace silently
#    if [[ -d "$link" && -z "$(ls -A "$link")" ]]; then
    if [[ -d "$link" && -z "$(find "$link" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
#        rm -r "$link"
        rm -rf -- "$link"
        ln -s "$target" "$link"
        info slinks_replaced "$link" "$target"
        return
    fi

    # non-empty dir → ask
    if [[ -d "$link" ]]; then
        read -rp "$(say slinks_confirm_replace "$link") [y/N]: " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            rm -r "$link"
            ln -s "$target" "$link"
            info slinks_replaced "$link" "$target"
        else
            warn slinks_skipped "$link"
        fi
        return
    fi

    # exists but not dir or symlink
    if [[ -e "$link" ]]; then
        warn slinks_conflict "$link"
        return
    fi

    # create
    ln -s "$target" "$link"
    info slinks_created "$link" "$target"
}

# -------------------------------------------------------------
# 14. Main logic (pure declarative)
# -------------------------------------------------------------

info slinks_start

for key in "${!TARGET_DIRS[@]}"; do
    target="$BASE_DIR/${TARGET_DIRS[$key]}"
    link_name="$(get_link_name "$key")"
    link_path="$TARGET_HOME/$link_name"

    ensure_dir "$target"
    ensure_symlink "$link_path" "$target"
done

for pair in "${EXTRA_SYMLINKS[@]}"; do
    [[ "$pair" == *:* ]] || {
        warn slinks_invalid_symlink "$pair"
        continue
    }

    name="${pair%%:*}"
    target="${pair##*:}"

    link_path="${TARGET_HOME}/${name}"
    ensure_dir "$target"
    ensure_symlink "$link_path" "$target"
done

info slinks_done

exit 0