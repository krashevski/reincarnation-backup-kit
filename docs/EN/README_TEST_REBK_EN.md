# ✅ Correct procedure for local REBK testing

[🇬🇧 English](README_TEST_REBK_EN.md) | [🇷🇺 Русский](../RU/README_TEST_REBK_RU.md)

## 1️⃣ Clone the repository again (clean checkout)

Important: not from the current working copy.
```bash
cd ~
git clone https://github.com/krashevski/reincarnation-backup-kit rebk-test
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
- languages
- correct messages


