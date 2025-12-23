# 🔒 Working Safely with GitHub

[🇬🇧 English](README_GITHUB_SAFE_EN.md) | [🇷🇺 Русский](../RU/README_GITHUB_SAFE_RU.md)

Goal: To provide a safe method for working with local repositories and remote services, minimizing the risk of token leaks, accidental force pushes, and other errors.

## 1️⃣ Setting up a local repository

### Clone the repository
```bash
git clone https://github.com/username/repository.git
cd repository
```

### Check out the default branch
```bash
git branch
git status
```

Recommendations:
- Never work with the root account.
- Always check out the current branch before committing.
- Create feature branches for new changes:

```bash
git checkout -b feature/name
```

## 2️⃣ Safely storing your Git token

### Using an environment variable (current session only):
```bash
export GIT_TOKEN="your_token_here"
```

* Never store your token in the repository (.env, .bashrc, README, etc.).
* When finished, delete the variable:
```bash
unset GIT_TOKEN
```

### Never save the token in the repository:
```bash
# ❌ DO NOT
echo "GIT_TOKEN=..." >> .env
```

### Using a .git-credentials file with restricted access rights:
```bash
git config --global credential.helper store
chmod 600 ~/.git-credentials
```

> [i] In this case, the token will be stored locally, protected by user permissions.

## 3️⃣ Secure backup of git-recovery-codes

1. Download Recovery Codes from GitHub (to restore two-factor authentication).
2. Burn to secure media, such as a DVD:
```bash
# Example of burning an ISO to a DVD
wodim -v dev=/dev/sr0 -data git-recovery-codes.txt
```

3. Make sure the DVD is stored securely and access is restricted.

## 4️⃣ Checking GnuPG Directories

```bash
# Checking key and configuration permissions
ls -l ~/.gnupg
gpg --list-keys
gpg --list-secret-keys
```

Recommendations:
The directory permissions should be 700 and the key files 600.
```bash
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/*
```

## 5️⃣ Working with Branches

* View all local and remote branches:
```bash
git branch -a
```

* Merge changes:
```bash
git checkout main
git pull origin main # you can specify --rebase
git merge feature/name
```

* Revert changes to the last commit:
```bash
git restore <file>
git restore .
```

* Removing local branches after merging:
```bash
git branch -d feature/name
```

## 6️⃣ Push and Security

* Before pushing, ensure the branch is up-to-date:
```bash
git fetch origin
git status
git diff
```

* ⚠️ Don't use --force unless absolutely necessary
```bash
git push origin main
```

* If you need to force (very carefully):
```bash
git push --force-with-lease
```

## 5️⃣ Checking changes and integrity

- Checking commit hashes:
```bash
git log --oneline --graph --decorate
```

- Checking local integrity:
```bash
git fsck
```

## 7️⃣ Backing up local repositories

* Creating a local archive
```bash
tar -czf ~/backup-repository.tar.gz repository/
```

* Verifying the archive:
```bash
ls -lh ~/backup-repository.tar.gz
```

## 8️⃣ Tips

* Use a separate GitHub account for testing.
* Don't push sensitive data.
* Set up .gitignore for temporary files and tokens.
* Enable two-factor authentication.
* Scan directories and logs before deleting.

## 🔑 Operating system password

* Use a **strong user password** for your Linux account.
* The password must be unique, long, and complex enough.
* Never use the root password for everyday work with Git or scripts.
* If you need to run scripts with `sudo`, make sure the command is safe:
   - Trust only trusted sources.
   - Read the script and check which commands are executed with root privileges.
      - This is especially important for the following commands: `rm`, `dd`, `mkfs`, `ln -sf`.
   - Do not copy `sudo` commands from unknown sources.
   - For testing, you can first run the script without `sudo` to check the output and behavior.
   - Use `sudo -l` to find out which commands your account can execute with root privileges.
