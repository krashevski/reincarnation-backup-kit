#!/usr/bin/env bash
# check.sh - тест, используется в каталоге репозитория

SECURITY_ROOT="$HOME/.git-security"
STATE_DIR="$SECURITY_ROOT/state"
REAL_GIT="${REAL_GIT:-$(command -v git || true)}"
[[ -x "$REAL_GIT" ]] || { echo "[ERROR] git not found"; exit 1; }
LIB_DIR="/usr/local/lib/brandmauer"
GIT_DIR="$LIB_DIR/git"
COMMON="$GIT_DIR/common.sh"

[[ -f "$COMMON" ]] || { echo "[ERROR] common.sh missing"; exit 1; }
source "$COMMON"

REPO=$(basename "$($REAL_GIT rev-parse --show-toplevel 2>/dev/null || echo '')")
MODE_FILE=$(get_git_mode)

echo "Current directory: $(pwd)"
echo "Repo name detected: $REPO"
echo "Mode file: $MODE_FILE"

if [[ -f "$MODE_FILE" ]]; then
    MODE=$(<"$MODE_FILE")
else
    MODE="SAFE"
fi

echo "Mode detected: $MODE"

# Тестируем команды
for TEST_CMD in push pull merge fetch; do
    echo -n "Testing $TEST_CMD: "
    if "$REAL_GIT" --no-pager log >/dev/null 2>&1; then
        # Обёртка для проверки политики без выхода
        if enforce_git_policy "$TEST_CMD" 2>/dev/null; then
            echo "ALLOWED"
        else
            echo "BLOCKED"
        fi
    else
        echo "BLOCKED"
    fi
done