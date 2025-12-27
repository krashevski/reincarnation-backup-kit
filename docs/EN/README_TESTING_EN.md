# 🧪 README_TESTING — Testing Reincarnation Backup Kit

This document describes how to test the **Reincarnation Backup Kit** distribution after changes, merges, or restoring the repository.

This document is intended for:

* self-testing before a git push
* regression testing after a merge/rebase
* confirming that main remains a stable branch

## 🎯 Testing Goals

* Ensure that backup/restore work correctly
* Check that i18n isn't broken (menus, messages)
* Confirm that scripts are idempotent
* Eliminate errors after Git conflicts

## 📦 Environment Preparation

Recommended Environment:

* Ubuntu 24.04 LTS (clean system or VM)
* Debian 12 (optional)
* Run as user with sudo

Before testing:

```bash
sudo apt update
sudo apt install -y bash coreutils util-linux
```

## 🧩 Project Structure Check

```bash
tree -L 2
```

### Check execute permissions

```bash
ls -l scripts/install.sh
ls -l scripts/menu.sh
```
If needed:
```bash
chmod +x install.sh menu.sh scripts/*.sh
```

### Check menu.sh
```bash
./scripts/menu.sh
```

Expected:

* menu displays correctly
* no `command not found`
* no bash errors

### Check idempotency

Run twice in a row:
```bash
scripts/setup-symlinks.sh
scripts/setup-symlinks.sh
```

Expected:
- link is correct
- nothing breaks
- no ln: access denied

### Check show-system-mounts.sh

```bash
scripts/show-system-mounts.sh
```

Should:
- show drives
- mounts
- symlinks in $HOME
- crontab (or empty)

### Check HDD setup

```bash
sudo scripts/hdd-setup-profiles.sh
```

See:
- warnings are clear
- no silent errors
- the menu does not crash

## 🌍 i18n Testing

Check:

* presence of the `i18n/` directory
* correct loading of language files

### Check default language

```bash
./scripts/menu.sh
```

* messages are readable
* no "blank" lines

### Check language switching (if supported)

* language switching
* correctness of messages

## 💾 Testing Backup

### System Backup

```bash
./scripts/backup-system.sh
```

Check:

* archive is created
* package lists are saved
* no critical errors

### User Backup

```bash
./scripts/backup-userdata.sh
```

Check:

* paths are correct
* access rights

## 🔄 Testing Restore (dry-run)

> ⚠️ VM recommended

```bash
./scripts/system-restore.sh --dry-run
```

Expected:

* output without errors
* warnings are clear

## 🧪 Regression checks after Git operations

After:

* `git merge`
* `git rebase`
* file restoration

Check:

* no conflict markers `<<<<<<< >>>>>>>`
* README correctness
* `menu.sh` functionality

```bash
grep -R "<<<<" .
```

## 📄 Documentation Check

* `cat README.md` is up-to-date
* links work
* badges are correct

## ✅ Success Test Criteria

* Scripts run without errors
* Menu and i18n work
* Backup is created
* Restore does not crash the system (dry-run)
* Repository is clean:

```bash
git status
```

## 🚀 Ready for publication

Before publication:

```bash
git diff origin/main..main
```

If changes are expected:

```bash
git push origin main
```

## 📝 Note

`main` — **stable branch**
`i18n` — working branch for localizations and documentation

All changes to `main` must pass this checklist.

🛡️ Reincarnation Backup Kit — first restore your system, then trust Git.
