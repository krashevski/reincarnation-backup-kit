#!/usr/bin/env bash 
# =============================================================
# /maintenance/cleanup.sh — служебная CLI-утилита.
# -------------------------------------------------------------
# Использование maintenance/cleanup.sh
:<<'DOC'

DOC
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/directories.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/safety.sh"
source "$LIB_DIR/cleanup.sh"

require_root

WORKDIR="$(mktemp -d)"
register_cleanup "$WORKDIR"

trap 'cleanup_custom; cleanup_workdir' EXIT INT TERM

main() {
    init_system_dirs
    info "Running cleanup maintenance"
}

main "$@"
