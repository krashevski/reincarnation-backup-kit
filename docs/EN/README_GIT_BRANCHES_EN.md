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

## Recommendations

- Never push directly to main if branch protection is enabled.
- Make sure all local changes are committed before merging.
- Use feature branches for new tasks and experiments.
- Create backup branches before breaking changes.

## 📝 Mini-sequence for working with README via the feature/update-readme branch
1. Go to the documentation branch:
```bash
git checkout feature/update-readme
```

2. Pull the latest changes from GitHub
```bash
git fetch origin
git rebase origin/feature/update-readme
```

### See also
- Cheat Sheet: Safely Rebase README [README_GIT_REBASE_RU.md](README_GIT_REBASE_RU.md)

3. Make changes to local README files:
- docs/RU/README_GIT_REBASE_RU.md
- docs/EN/README_GIT_REBASE_EN.md

4. Add changes to the index:
```bash
git add docs/RU/README_GIT_REBASE_RU.md
git add docs/EN/README_GIT_REBASE_EN.md
```

5. Create a commit:
```bash
git commit -m "Update README_GIT_REBASE: fixes and additions"
```

6. Push changes to GitHub:
```bash
git push origin feature/update-readme
```

> ⚠️ The git push command doesn't create a PR (Pull Request) itself, but it ensures that the server has an up-to-date version of the branch for the PR.

## 📝 Mini-sequence for updating main from a feature branch for README

1. Go to main and update from GitHub:
```bash
git checkout main
git pull origin main
```

2. Merge changes from the feature branch:
```bash
git merge feature/update-readme
```

3. Resolve any conflicts (if you see <<<<<<<, =======, >>>>>>> in the file that opens, leave the relevant text and save the file).

4. Push the updated main to GitHub:
```bash
git push origin main
```.

## 🌳 About the branching scheme

Visually:
```text
      main
       |
       | Pull / Merge
       |
backup-before-i18n   ← Резервная ветка перед крупными изменениями
       |
       |
feature/i18n-updates  ← Ветка для новой функции или изменения
       |
       | Работа и коммиты
       |
feature/fix-bug       ← Другая feature-ветка
       |
       | Merge Pull Request
       |
      main
```

Explanation of the scheme:
1. main — the primary protected branch, contains the stable version of the project.
2. backup-before-* — created before major changes, to allow for quick reversion.
3. feature/... — branches for working on a specific task or new feature.
4. Merge Pull Request — after completing work on the feature branch, changes are merged into main via a pull request.
5. After the merge, the feature branch can be deleted, but main remains protected.

## See also

- Cheat Sheet: Safe Rebase README file [README_GIT_REBASE_EN.md](README_GIT_REBASE_EN.md)
- Mini Git Cheat Sheet file [README_GIT_EN.md](README_GIT_EN.md)
