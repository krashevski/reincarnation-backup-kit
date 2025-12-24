# 🌿 Working with Git and GitHub Branches

[![License: CC BY-SA 4.0](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

[🇬🇧 English](README_GIT_BRANCHES_EN.md) | [🇷🇺 Русский](../RU/README_GIT_BRANCHES_RU.md)

A quick guide to safely working with branches in the Reincarnation Backup Kit repository.

## Main Branches

| Branch | Purpose |
| --------------------------------------- | ----------------------------------------------------------------------- |
| `main` | The main protected branch. Contains the stable version of the project. |
| `local-working-version` | Branch for local work and experimentation. |
| `feature/...` | Branches for new features or changes (e.g. `feature/i18n-updates`). |
| `backup-before-*` | Backup branches before major changes. |

## 🆕 Create a new feature branch

### Switch to main and pull in the latest changes
```bash
git checkout main
git pull origin main
```

### Create a new branch for working on the task
```bash
git checkout -b feature/i18n-updates
```

> [I] It's best to make all commits in this branch.

To sync with GitHub:
```bash
git push -u origin feature/i18n-updates
```

## 🔀 Pull Request (merging changes into main)

1. On GitHub, open the repository → Pull requests tab → New pull request.
2. Set:
1. base: main
2. compare: your feature branch
3. In the form for existing changes, write a title and description of the changes.
4. Click Create pull request → Merge pull request (after review).
5. After merging, the feature branch can be deleted to keep the history clean.

## 💾 Create a backup branch before major changes

```bash
git checkout main
git branch backup-before-i18n
git push origin backup-before-i18n
```

> [I] This allows you to always save the current state before making major changes.

## 🔍 Checking Branch Status

### All local branches
```bash
git branch -vv
```

### All branches on GitHub
```bash
git fetch origin
git branch -r
```

## Best Practices

- Never push origin main if branch protection is enabled.
- Before merging, make sure to commit all local changes.
- Use feature branches for new tasks and experiments.
- Create backup branches before making breaking changes.

## 📝 Updating README via rebase in the feature/update-readme branch

### 1. Switch to the documentation branch

```bash
git checkout feature/update-readme

### 2. Pull the latest changes from GitHub
```bash
git fetch origin
git rebase origin/feature/update-readme
```

### See also
- Cheat Sheet: Safely Rebase README [README_GIT_REBASE_EN.md](README_GIT_REBASE_EN.md)

### 3. Rule for checking changes in README:
```bash
git status
git diff
```

Check that there are no:
* `<<<<<<<`
* `=======`
* `>>>>>>>`

### 4. Add Changes to README files:
```bash
nano docs/RU/README_GIT_REBASE_RU.md
nano docs/EN/README_GIT_REBASE_EN.md
```

### 5. Add changes to the index:
```bash
git add docs/RU/README_GIT_REBASE_RU.md
git add docs/EN/README_GIT_REBASE_EN.md
```

### 6. Create a commit:
```bash
git commit -m "docs: corrections and additions README_GIT_REBASE"
```

### 7. Submit changes:
```bash
git push --force-with-lease origin feature/update-readme
```

## 📝 Mini-sequence: Update main from a feature branch for README

> [!] Don't move to main; it's better to let the branch with the changes "rest":
> * All changes will remain in your working branch (feature/update-readme or feature/i18n-updates).
> * You can safely check in your working branch that everything is working correctly (i18n, documentation, scripts).
> * You can fix errors, conflicts, and test locally before merging with main.
> * After testing and verification, moving to main will be safe, and the history will remain clean.

1. Switch to the main branch and update to the latest changes:
```bash
git checkout main
git pull origin main
```

2. Merge the changes from the feature branch:
```bash
git merge feature/update-readme
```

3. Push the updated main branch to GitHub:
```bash
git push origin main
```

## 🌳 About the branching scheme

Visually:
```text
      main
       |
       | Pull / Merge
       |
backup-before-i18n   ← Backup branch before major changes
       |
       |
feature/i18n-updates  ← Branch for a new feature or change
       |
       | Work and commits
       |
feature/fix-bug       ← Другая feature-ветка
       |
       | Merge Pull Request
       |
      main
```

Explanation of the scheme:
1. main — the main protected branch, contains the stable version of the project.
2. backup-before-* — created before major changes, to allow for quick rollbacks.
3. feature/... — branches for working on a specific task or new feature.
4. Merge Pull Request — after completing work on the feature branch, changes are merged into main via a Pull Request.
5. After merging

## See also

- Deleting from GitHub Branches [README_GIT_BRANCHES_DELETE_EN.md](README_GIT_BRANCHES_DELETE_EN.md)
- Cheat Sheet: Safe Rebase [README_GIT_REBASE_EN.md](README_GIT_REBASE_EN.md)
- Mini Git Cheat Sheet [README_GIT_EN.md](README_GIT_EN.md)
