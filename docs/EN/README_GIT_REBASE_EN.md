# 🌿 Cheat Sheet: Safe Rebase README

[![License: CC BY-SA 4.0](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

[🇬🇧 English](README_GIT_REBASE_EN.md) | [🇷🇺 Русский](../RU/README_GIT_REBASE_RU.md)

A short and safe sequence of steps for completing a rebase and publishing a README

## Preparation

Before rebasing, make sure your local changes are saved:
```bash
git status # check that the working directory is clean
git add . # or git stash to temporarily save changes
```

## Running rebase

```bash
git fetch origin
git rebase origin/main
```

> [I] Git will attempt to apply your commits on top of main:
> [I] If there are no conflicts, the rebase will proceed automatically.

## Conflicts during rebase

If you see conflicting markers:
```bash
<<<<<<< HEAD
(your version)
=======
(version from main)
>>>>>>> commit_hash
```

> **HEAD** — your local version
> **commit_hash** — version from the `main` branch

Steps:
1. Open the file in an editor (e.g., nano):
```bash
nano docs/EN/README_GIT_BRANCHES_EN.md
```

2. Remove the markers <<<<<<<, =======, >>>>>>>.
3. Leave the final text you want.
4. Save and exit (Ctrl+O → Enter → Ctrl+X in nano).

## Mark files as resolved

```bash
git add docs/EN/README_GIT_BRANCHES_EN.md
git add docs/RU/README_GIT_BRANCHES_RU.md
```

## Continue the rebase

```bash
git rebase --continue
```

- If there are more conflicts, repeat steps 3-5 for them.
- When there are no more conflicts, the rebase will complete.

If you want to cancel the rebase, use:
```bash
git rebase --abort
```

## Checking the status

```bash
git status
git log --oneline --graph --decorate -5
```

- Make sure the branch is clean and all commits are applied.
- All your README commits are applied.

## Publishing on GitHub

```bash
git push origin feature/i18n-updates
```

If history is rewritten (due to a rebase), it's safe to use:
```bash
git push --force-with-lease origin feature/i18n-updates
```

> [I] Always use --force-with-lease to avoid overwriting someone else's changes on the server.

## Tips

- Always pull/fetch first to minimize conflicts.
- Keep a backup of your local changes (git stash) if you're unsure.
- For text files (README, docs), it's easier to manually merge versions if there's a conflict.
- Use a consistent commit style and message for easy navigation.


## See also

- Working with Git and GitHub Branches README file [README_GIT_BRANCHES_EN.md](README_GIT_BRANCHES_EN.md)
- Mini Git Cheat Sheet file [README_GIT_EN.md](README_GIT_EN.md)
