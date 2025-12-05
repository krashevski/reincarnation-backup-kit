# 🧩 Cheat Sheet: How to finish git rebase when conflicts occur

[![License: CC BY-SA 4.0](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

[🇬🇧 English](README_GIT_REBASE_EN.md) | [🇷🇺 Русский](../RU/README_GIT_REBASE_RU.md)

This document explains how to safely resolve merge conflicts during git rebase. It is designed for beginners and used inside the Reincarnation Backup Kit project.

## 1. 📌 Check which files are in conflict

Git lists them automatically, but you can check manually:
```bash
git status # check that the working directory is clean
```

You will see files marked as:
```bash
both modified: docs/RU/...  
both modified: docs/EN/...
```

## 2. 📌 Open the conflicting file and remove conflict markers

Open the file:
```bash
nano docs/EN/README_...
```

Look for blocks like:
```bash
<<<<<<< HEAD
Your version of the text
=======
Text from the other branch
>>>>>>> feature/update-readme
```

🎯 Do this steps:
Steps:
1. Open the file in an editor (e.g., nano):
```bash
nano docs/EN/README_GIT_BRANCHES_EN.md
```

2. Remove the markers <<<<<<<, =======, >>>>>>>.
3. Leave the final text you want.
4. Save and exit (Ctrl+O → Enter → Ctrl+X in nano).

## 3. 📌 Mark the conflict as resolved

```bash
git add docs/EN/README_GIT_BRANCHES_EN.md
git add docs/RU/README_GIT_BRANCHES_RU.md
```

## 4. 📌 Continue the rebase

```bash
git rebase --continue
```

- If there are more conflicts, repeat steps 1-4 for them.
- When there are no more conflicts, the rebase will complete.

## 5. 📌 Useful commands

❗ Abort rebase:
If you want to cancel the rebase, use:
```bash
git rebase --abort
```

❗ Skip the problematic commit:
```bash
git rebase --skip
```

## 6. 📌 Checking the status

```bash
git status
git log --oneline --graph --decorate -5
```

- Make sure the branch is clean and all commits are applied.
- All your README commits are applied.

## 7. 📌 Final step: push your updated branch to publishing on GitHub

```bash
git push --force-with-lease origin feature/update-readme
```

> --force-with-lease is if history is rewritten (due to a rebase), it's safe to use.

## Tips

- Always pull/fetch first to minimize conflicts.
- Keep a backup of your local changes (git stash) if you're unsure.
- For text files (README, docs), it's easier to manually merge versions if there's a conflict.
- Use a consistent commit style and message for easy navigation.

## See also

- Working with Git and GitHub Branches README file [README_GIT_BRANCHES_EN.md](README_GIT_BRANCHES_EN.md)
- Mini Git Cheat Sheet file [README_GIT_EN.md](README_GIT_EN.md)
