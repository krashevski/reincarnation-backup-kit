#!/usr/bin/env bash
# =============================================================
# /scripts/lib/system_detect.sh
# Reincarnation Backup Kit
# System detection library
# -------------------------------------------------------------
# Использование system_detect.sh
:<<'DOC'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# --- Libraries ---
source "$LIB_DIR/system_detect.sh"

# --- Detect system ---
detect_system || exit 1

# Пример:
info system "$DISTRO_ID $DISTRO_VER"
DOC
# =============================================================

DISTRO_ID=""
DISTRO_VER=""

detect_system() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release

        DISTRO_ID="$ID"
        DISTRO_VER="$VERSION_ID"

        export DISTRO_ID
        export DISTRO_VER

        info detect_system "$DISTRO_ID" "$DISTRO_VER"
    else
        error not_system
        return 1
    fi
}