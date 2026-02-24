#!/usr/bin/env bash
# =============================================================
# /scripts/lib/guards-firefox.sh
# -------------------------------------------------------------
# Использование guards-inhibit.sh
:<<'DOC'
source "$LIB_DIR/guards-firefox.sh"
DOC
# =============================================================

set -o errexit
set -o pipefail

firefox_is_running() {
    pgrep -x firefox >/dev/null 2>&1
}