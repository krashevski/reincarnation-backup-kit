# 📝 Mini Git Cheat Sheet

[![License: CC BY-SA 4.0](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

[🇬🇧 English](README_GIT_EN.md) | [🇷🇺 Русский](../RU/README_GIT_RU.md)

A short set of commands for convenient work with Git and GitHub.
These commands are sufficient for everyday project work.

## 🔄 Adding and saving changes
### Check the status (what changed)
```bash
git status
```

### Add all changed files
```bash
git add .
```

### Commit with message
- New feature:
```bash
git commit -m "feat: description of changes"
```

- Tranlations
```bash
git commit -m "feat(i18n): add translations for RU/EN messages in menu.sh"
```

```bash
git commit -m "i18n: Added translations for installation and recovery scripts"
```

- Documentation:
```bash
git commit -m "docs: description of changes"
```

```bash
git commit -m "docs: added translation string to README_GIT"
```

- Update documentation
```bash
git commit -m "docs: update README_GIT with commit message guidelines"
```

- Bug fixes:
```bash
git commit -m "fix: typos in ..."
```

- Case-specific fix:
```bash
git commit -m "fix: robust printf in msg() to handle --fresh and similar arguments"
```

- Security fix:
```bash
git commit -m "fix(security): exclude archive disk from formatting" -m "Added a safety check to prevent accidental formatting of the archive disk.
The selected backup disk is now excluded from the list of disks available for formatting.

The limitation on the maximum number of users is still pending and will be added in a future update."
```

- Fixing image links
```bash
git commit -m "fix: image links in README files"
```

- Minor technical fixes without changing content
```bash
git commit -m "chore: normalize file state"
```

## 🚀 Pushing changes to GitHub
### Push changes to the main branch
```bash
git push origin main
```

## 📥 Getting updates from GitHub
### Pull the latest changes from main
```bash
git pull origin main
```

## 📝 Useful checks
### View commit history
```bash
git log --oneline --graph --decorate --all
```

### Check remote repository connection
```bash
git remote -v
```

## 📌 Recommended workflow
```bash
git status
git add .
git commit -m "..."
git push origin main
```

