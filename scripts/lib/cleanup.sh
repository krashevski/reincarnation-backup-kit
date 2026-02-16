# =============================================================
# /lib/cleanup.sh - библиотека только функции
# -------------------------------------------------------------
# использование cleanup.sh
:<<'DOC'
source "$LIB_DIR/cleanup.sh"
register_cleanup "$WORKDIR"
trap 'cleanup_custom; cleanup_workdir' EXIT INT TERM
DOC
# =============================================================

register_cleanup() {
    local workdir="$1"
    CLEANUP_WORKDIR="$workdir"
}

cleanup_workdir() {
    [[ -n "$CLEANUP_WORKDIR" ]] || return 0
    safe_rm_rf "$CLEANUP_WORKDIR"
}

cleanup_custom() {
    :
}
