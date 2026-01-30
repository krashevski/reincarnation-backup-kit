# REBK Lib — Mini-README

[🇬🇧 English](README_REBK_LIB_EN.md) | [🇷🇺 Русский](../RU/README_REBK_LIB_RU.md)

## 📂 Lib Folder Structure

```text
lib/
├── logging.sh        # logging + i18n + colors
├── deps.sh           # dependency check and installation
└── additional/       # utils, guards, locks, etc.
```

## 1️⃣ Including in a REBK script

```bash
#!/usr/bin/env bash
```

```bash
# path to lib
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd)"
```

```bash
# enabling logging and i18n
source "$LIB_DIR/logging.sh"
```

```bash
# enabling dependency checking
source "$LIB_DIR/deps.sh"
```

> After this, all functions are available:
> `ok`/`info`/`warn`/`error`/`die`
> `say(key, ...)`
> `check_and_install_deps(...)`

## 2️⃣ Using logging with i18n

### 2.1 Setting the language
```bash
# default ru
LANG_CODE="${LANG_CODE:-ru}"
load_messages "$LANG_CODE"
```

### 2.2 Logging examples
```bash
ok deps_ok # [OK] Message from MSG['deps_ok']
info deps_install_try # [INFO] Trying to install dependencies...
warn deps_missing_list "rsync tar gzip"
error no_script "$DISTRO" "$VERSION" "$TARGET"
die 2 "fatal_error_occurred"
```

> All messages are taken from MSG[] in `i18n/messages_ru.sh` or `messages_en.sh`.

### 3️⃣ The say() function
- Format: `say <key> [args...]`
- Substitutes arguments into an `i18n` template via `printf`

Example in messages_ru.sh:
```bas
MSG[no_script]='%s %s — script %s not found or not executable'
```

Call:
```bas
say no_script "$DISTRO" "$VERSION" "$TARGET"
```

Output:
```bash
Ubuntu 22.04 — script backup-system.sh not found or not executable
```

## 4️⃣ Dependency Checker

```bash
# Checks commands and attempts to install missing ones
check_and_install_deps rsync tar gzip pv
```

- Checks commands via `command -v`
- Supported package managers: `apt-get`, `dnf`, `yum`, `pacman`, `zypper`
- Missing packages are logged via warn
- `[OK]` is printed upon successful verification

## 5️⃣ Colors and Streams

| Function | Color  | Stream | Return Code |
| ---------|--------|--------|------------ |
| ok       | green  | stdout | 0           |
| info     | blue   | stdout | 0           |
| warn     | yellow | stderr | 0           |
| error    | red    | stderr | 1           |
| die      | red    | stderr | script exit with code 1 or specified |

- Colors are automatically disabled if `stdout` is not `tty` or `FORCE_COLOR=0`
- Logs are saved in `RUN_LOG` if the variable is set

## 6️⃣ Example of a complete script

```bash
#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd)"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/deps.sh"

# language
LANG_CODE=ru
load_messages "$LANG_CODE"

# dependency check
check_and_install_deps rsync tar gzip pv

# logging
ok "Script started successfully"
info "Starting backup..."
warn "Old package versions found"
error "Could not find script"
die 1 "Fatal error"
```