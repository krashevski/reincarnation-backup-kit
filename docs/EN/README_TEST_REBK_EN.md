# ✅ Correct procedure for local REBK testing

[🇬🇧 English](README_TEST_REBK_EN.md) | [🇷🇺 Русский](../RU/README_TEST_REBK_RU.md)

## 1️⃣ Clone the repository again (clean checkout)

Important: not from the current working copy.
```bash
cd ~
git clone https://github.com/<username>/backup-kit.git rebk-test
cd rebk-test
```

## 2️⃣ Check that the version is really the latest

```bash
git log --oneline -5
```

Compare:
- last commit
- date
- message (images: add corrected Ubuntu screenshot... etc.)

## 3️⃣ Check project structure

```bash
tree -L 2
```

Note:
* scripts/
* scripts/i18n/
* menu.sh
* install.sh
* missing TEST_FORCE.md ✅

## 4️⃣ Check execution permissions

```bash
ls -l scripts/*.sh menu.sh install.sh
```

If needed:
```bash
chmod +x install.sh menu.sh scripts/*.sh
```

## 5️⃣ Run without sudo (important)

```bash
./scripts/menu.sh
```

Check:
- Russian / English language
- no link_xxx
- correct messages
- no MSG, L, or say errors

## 6️⃣ Check show-system-mounts.sh

```bash
scripts/show-system-mounts.sh
```

Should:
- show drives
- mounts
- symlinks in $HOME
- crontab (or empty)

## 7️⃣ Check idempotency (key)

Run twice in a row:
```bash
scripts/setup-symlinks.sh
scripts/setup-symlinks.sh
```

Expected:
- the link is correct
- nothing breaks
- no ln: access denied

## 8️⃣ Check root-only parts (deliberately)

```bash
sudo scripts/hdd-setup-profiles.sh
```

See:
- warnings are clear
- no "silent" errors
- the menu doesn't break

## 🧪 What's especially important to check

* multi-user (SUDO_USER, $HOME)
* i18n (RU / EN)
* no paths like /link_music
* correct logs in /mnt/backups/logs
* safe to restart

> ⚠️ Important: Running scripts directly from a cloned repository
may result in incorrect behavior.
Use install.sh before performing full testing.

## 🟢 If Everything went smoothly.

The next logical step.
