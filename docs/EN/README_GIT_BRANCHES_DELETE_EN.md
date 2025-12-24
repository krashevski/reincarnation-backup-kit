# 🌿 Deleting Branches on GitHub

[![License: CC BY-SA 4.0](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

[🇬🇧 English](README_GIT_BRANCHES_DELETE_EN.md) | [🇷🇺 Русский](../RU/README_GIT_BRANCHES_DELETE_RU.md)

A quick guide to deleting branches in a GiHub repository

## 🧭 1. First, make sure you're in the right branch.

> [!] Never delete branches in which you are located.
```bash
git branch
```

Switch to main (or the one you want to keep as main):
```bash
git checkout main
git pull origin main
```

## 🧹 2. View all branches

### Local on your machine:
```bash
git branch
```

### Remote (GitHub):
```bash
git branch -r
```

### All at once:
```bash
git branch -a
```

## 🗑 3. Delete local branches

### Safe delete (recommended)
Deletes only if the branch has already been merged:
```bash
git branch -d feature/i18n-updates
git branch -d add-readme-image
```

### Forced (⚠ only if sure)
```bash
git branch -D backup-broken-main
```

## 🌐 4. Delete branches on GitHub (origin)

```bash
git push origin --delete feature/i18n-updates
git push origin --delete add-readme-image
git push origin --delete backup-broken-main
```

> [!] You only need to specify the branch name, without origin/.
> [I]📌 After this, the branch will disappear from GitHub.

## 🔄 5. Clean up references to remote branches

Git sometimes stores "ghosts":
```bash
git fetch --prune
```

Check:
```bash
git branch -r
```

## 🧼 6. Verification checklist

✔ main — remains
✔ unnecessary feature/* branches are gone
✔ git branch -a looks clean
✔ GitHub → Branches — tidy

## 🧠 Recommended policy for the future

Neat history:
- feature branch → merge/rebase → delete
- documentation branches → disposable
- long-lived branches — ❌ not needed

## 💡 Tip (optional)

On GitHub, you can enable automatic branch deletion after merge:
Settings → General → Pull Requests → Automatically delete head branches

## See also

- Working with Git and GitHub Branches [README_GIT_BRANCHES_EN.md](README_GIT_BRANCHES_EN.md)
