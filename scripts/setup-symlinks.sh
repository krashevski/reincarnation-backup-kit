#!/bin/bash
set -euo pipefail

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

# -------------------------------------------------------------
# 1. Определяем директорию скрипта
# -------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -------------------------------------------------------------
# 2. Объявляем ассоциативный массив MSG (будет расширяться при source)
# -------------------------------------------------------------
declare -A MSG

# -------------------------------------------------------------
# 3. Функция загрузки сообщений
# -------------------------------------------------------------
load_messages() {
    local lang="$1"
    # очищаем предыдущие ключи
    MSG=()

    case "$lang" in
        ru)
            source "$SCRIPT_DIR/i18n/messages_ru.sh"
            ;;
        en)
            source "$SCRIPT_DIR/i18n/messages_en.sh"
            ;;
        *)
            echo "Unknown language: $lang" >&2
            return 1
            ;;
    esac
}

# -------------------------------------------------------------
# 4. Безопасный say
# -------------------------------------------------------------
say() {
    local key="$1"; shift
    local msg="${MSG[${key}]:-$key}"

    if [[ $# -gt 0 ]]; then
        printf "$msg\n" "$@"
    else
        printf '%s\n' "$msg"
    fi
}

# -------------------------------------------------------------
# 5. Функция info для логирования
# -------------------------------------------------------------
info() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b" "$(printf "$fmt" "$@")"
    printf "\n"
}


# -------------------------------------------------------------
# 6. Функция warn для логирования
# -------------------------------------------------------------
warn() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "[WARN] %b\n" "$(printf "$fmt" "$@")" >&2
}

# -------------------------------------------------------------
# 7. Функция error для логирования
# -------------------------------------------------------------
error() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "[ERROR] %b\n" "$(printf "$fmt" "$@")" >&2
}


# -------------------------------------------------------------
# 8. Функция echo_msg для логирования
# -------------------------------------------------------------
echo_msg() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b\n" "$(printf "$fmt" "$@")"
}

# -------------------------------------------------------------
# 9. Функция die для логирования
# -------------------------------------------------------------
die() {
    error "$@"
    exit 1
}

# -------------------------------------------------------------
# 10. Устанавливаем язык по умолчанию и загружаем переводы
# -------------------------------------------------------------
LANG_CODE="${LANG_CODE:-ru}"
load_messages "$LANG_CODE"

# -------------------------------------------------------------
# 11. Paths
# -------------------------------------------------------------
BASE_DIR="/mnt/storage"
EXTRA_SYMLINKS=("shotcut:/mnt/shotcut" "backups:/mnt/backups")

if [[ -n "${USER_HOME:-}" ]]; then
    TARGET_HOME="$USER_HOME"
elif [[ -n "${SUDO_USER:-}" ]]; then
    TARGET_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
    TARGET_HOME="$HOME"
fi

[[ -z "$TARGET_HOME" || "$TARGET_HOME" == "/" ]] && {
    error invalid_home "$TARGET_HOME"
    exit 1
}

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

get_link_name() {
    local key="$1"
    case "$LANG_CODE" in
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
        info dir_created "$dir"
    fi
}

ensure_symlink() {
    local link="$1"
    local target="$2"

    # already correct
    if [[ -L "$link" && "$(readlink -f "$link")" == "$target" ]]; then
        info link_ok "$link" "$target"
        return
    fi

    # empty dir → replace silently
    if [[ -d "$link" && -z "$(ls -A "$link")" ]]; then
        rm -r "$link"
        ln -s "$target" "$link"
        info link_replaced "$link" "$target"
        return
    fi

    # non-empty dir → ask
    if [[ -d "$link" ]]; then
        read -rp "$(say confirm_replace "$link") [y/N]: " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            rm -r "$link"
            ln -s "$target" "$link"
            info link_replaced "$link" "$target"
        else
            warn link_skipped "$link"
        fi
        return
    fi

    # exists but not link (file, etc)
    if [[ -e "$link" ]]; then
        warn link_conflict "$link"
        return
    fi

    # create
    ln -s "$target" "$link"
    info link_created "$link" "$target"
}

# -------------------------------------------------------------
# 14. Main logic (pure declarative)
# -------------------------------------------------------------

info start_symlinks

for key in "${!TARGET_DIRS[@]}"; do
    target="$BASE_DIR/${TARGET_DIRS[$key]}"
    link_name="$(get_link_name "$key")"
    link_path="$TARGET_HOME/$link_name"

    ensure_dir "$target"
    ensure_symlink "$link_path" "$target"
done

for pair in "${EXTRA_SYMLINKS[@]}"; do
    name="${pair%%:*}"
    target="${pair##*:}"
    link_path="$TARGET_HOME/$name"

    ensure_dir "$target"
    ensure_symlink "$link_path" "$target"
done

info done_symlinks


