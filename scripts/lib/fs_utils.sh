#!/usr/bin/env bash
# =============================================================
# /scripts/lib/fs_utils.sh - 
# -------------------------------------------------------------

safe_rm_rf() {
    local path="$1"

    [[ -n "$path" ]] || return 0
    [[ "$path" != "/" ]] || return 1

    rm -rf --one-file-system "$path"
}