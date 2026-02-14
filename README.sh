#!/usr/bin/env bash
# Reincarnation Backup Kit — README
# This script is informational only. It makes no system changes.

set -euo pipefail

VERSION="0.1.0"
PROJECT_NAME="Reincarnation Backup Kit"
PROJECT_ID="REBK"

print_header() {
cat <<'EOF'
==================================================
   Reincarnation Backup Kit (REBK)
==================================================
EOF
}

print_short() {
cat <<EOF
$PROJECT_NAME — system backup & recovery toolkit.

Shell-based, modular, transparent.
EOF
}

print_about() {
    sed 's/^/  /' docs/EN/about.txt
}

print_usage() {
cat <<'EOF'

USAGE:
  ./menu.sh              Launch interactive menu
  ./README.sh            Show full project description
  ./README.sh --short    Show brief description
  ./README.sh --license  Show license information
  ./README.sh --paths    Show project structure

EOF
}

print_license() {
cat <<'EOF'
LICENSE NOTICE:

REBK is free software.

It does NOT include, link, or distribute any proprietary
software or proprietary source code.

REBK:
  • does not modify third-party code
  • does not bypass licensing mechanisms
  • invokes external programs as independent processes
  • operates exclusively on user-owned data

License: GNU GPL v3 (or later)
EOF
}

print_paths() {
cat <<'EOF'
PROJECT STRUCTURE (simplified):

  menu.sh        — main interactive entry point
  install.sh     — installation helper
  README.sh      — terminal-based project description
  lib/           — internal libraries
  docs/          — extended documentation

EOF
}

print_footer() {
cat <<EOF
Version: $VERSION
EOF
}

main() {
print_header

case "${1:-}" in
  --short)
    print_short
    ;;
  --license)
    print_license
    ;;
  --paths)
    print_paths
    ;;
  *)
    print_about
    print_usage
    print_license
    ;;
esac

print_footer
}

main "$@"
