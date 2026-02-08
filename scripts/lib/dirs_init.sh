#!/usr/bin/env bash
# =============================================================
# init_directories — инициализация каталогов

# -------------------------------------------------------------
# Использование init_directories
#
# source "$LIB_DIR/directories.sh"
# source "$LIB_DIR/logging.sh"
# source "$LIB_DIR/privileges.sh"
# source "$LIB_DIR/init.sh"
#
# init_user_dirs || exit 1
# init_system_dirs || exit 1
#
# if ! init_directories; then
#     error init_failed
#     exit 1
# fi
#
# assert_safe_path "$TARGET_DIR" || return 1
# rm -rf "$TARGET_DIR"
# =============================================================

# --- Защита от пустых путей ---
_safe_mkdir() {
    local dir="$1"

    if [[ -z "$dir" || "$dir" == "/" ]]; then
        error unsafe_path "$dir"
        return 1
    fi

    if [[ ! -d "$dir" ]]; then
        if mkdir -p "$dir"; then
            ok dir_created "$dir"
        else
            error dir_create_failed "$dir"
            return 1
        fi
    else
        info dir_exists "$dir"
    fi
}

# -------------------------------------------------------------
# Инициализация пользовательских каталогов
# -------------------------------------------------------------
init_user_dirs() {

    info init_user_dirs

    local dirs=(
        "$USERDATA_DIR"
        "$ARCHIVE_DIR"
        "$LOG_DIR"
        "$TARGET_DIR"
    )

    for dir in "${dirs[@]}"; do
        _safe_mkdir "$dir" || return 1
        chown "$RUN_USER:$RUN_USER" "$dir" 2>/dev/null || true
    done
}

# -------------------------------------------------------------
# Инициализация системных каталогов
# -------------------------------------------------------------
init_system_dirs() {

    require_root || return 1
    info init_system_dirs

    local dirs=(
        "$BACKUP_DIR"
        "$SYSTEM_DIR"
        "$SYSTEM_MANUAL_DIR"
        "$SYSTEM_FULL_DIR"
        "$FIREFOX_DIR"
        "$WORKDIR"
    )

    for dir in "${dirs[@]}"; do
        _safe_mkdir "$dir" || return 1
    done
}

# -------------------------------------------------------------
# Защита от rm -rf "" и rm -rf /
# -------------------------------------------------------------
assert_safe_path() {
    local path="$1"

    case "$path" in
        ""|"/"|"/home"|"/root"|"/usr"|"/etc"|"/var")
            error unsafe_path "$path"
            return 1
            ;;
    esac

    return 0
}

