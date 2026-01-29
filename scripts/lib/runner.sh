#!/usr/bin/env bash
# =============================================================
# /scripts/lib/runner.sh — step orchestration helpers
# Requires: logging.sh
# -------------------------------------------------------------
# Использование runner.sh
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# LIB_DIR="$SCRIPT_DIR/lib"
#
# source "$LIB_DIR/logging.sh"
# source "$LIB_DIR/runner.sh"
#
# run_step "$(say step_extract)" extract_archive
# run_step "$(say step_repos)" restore_repos_and_keys
# run_step "$(say step_packages)" restore_packages
# run_step "$(say step_logs)" restore_logs
# =============================================================

set -o errexit
set -o pipefail

# -------------------------------------------------------------
# Защита от повторного подключения
# -------------------------------------------------------------
[[ -n "${_REBK_RUNNER_LOADED:-}" ]] && return 0
_REBK_RUNNER_LOADED=1

# -------------------------------------------------------------
# runtime-проверка зависимоси от logging.sh
# -------------------------------------------------------------
type ok >/dev/null 2>&1 || {
    echo "runner.sh requires logging.sh" >&2
    return 1
}

run_step() {
    local step_name="$1"
    local func="$2"

    declare -F "$func" >/dev/null || die not_function "$func"

    if "$func"; then
        ok step_ok "$step_name"
    else
        error step_fail "$step_name" "$RUN_LOG" || true
        return 1
    fi
}

# -------------------------------------------------------------
# Экспорт say как readonly API
# -------------------------------------------------------------
readonly -f say ok info warn error die