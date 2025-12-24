# 🔒 Working Safely with GitHub

[🇬🇧 English](README_GITHUB_SAFE_EN.md) | [🇷🇺 Русский](../RU/README_GITHUB_SAFE_RU.md)

Goal: To provide a safe method for working with local repositories and remote services, minimizing the risk of token leaks, accidental force pushes, and other errors.

## 1. Setting up a local repository

### Clone the repository
```bash
git clone https://github.com/username/repository.git
cd repository
```

### Check the default branch
```bash
git branch
git status
```

Recommendations:
- Never work with the root account.
- Always checkout the current branch before committing.
- Create feature branches for new changes:

```bash
git checkout -b feature/name
```

## 2. Safely storing your Git token

### Using an environment variable (current session only):
```bash
export GIT_TOKEN="your_token_here"
```

Recommendations:
- Never store your token in the repository (.env, .bashrc, README, etc.).
- When finished, delete the variable:
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

## 3. Secure backup git-recovery-codes

1. Download Recovery Codes from GitHub (to restore two-factor authentication).
2. Burn to secure media, such as a DVD:
```bash
# Example of burning an ISO to a DVD
wodim -v dev=/dev/sr0 -data git-recovery-codes.txt
```

3. Make sure the DVD is stored securely and access is restricted.

## 4. Check GnuPG directories

```bash
# Check permissions on keys and configuration
ls -l ~/.gnupg
gpg --list-keys
gpg --list-secret-keys
```

Recommendations:
- The permissions should be 700 for the directory and 600 for the key files.
```bash
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/*
```

## 5. Changing the SSH Key Passphrase

* Run:
```bash
ssh-keygen -p -f ~/.ssh/id_ed25519
```

* Next:
  1. Enter the old passphrase (if any)
  2. Enter the new passphrase
  3. Confirm
The private key will remain the same, only the security will change.

* Check key permissions:
```bash
ls -ld ~/.ssh
ls -l ~/.ssh
```

* Expected:
  - ~/.ssh → drwx------
  - id_ed25519 → -rw-------
  - id_ed25519.pub → -rw-r--r--
  - authorized_keys → -rw-------

* If suddenly it’s not right, fix it:
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/authorized_keys
```

* Check via ssh-agent (optional)
```bash
ssh-add ~/.ssh/id_ed25519
```

* View loaded keys:
```bash
ssh-add -l
```

## 6. Working with Branches

* View all local and remote branches:
```bash
git branch -a
```

* Merge changes:
```bash
git checkout main
git pull origin main # --rebase can be specified
git merge feature/name
```

* Revert changes to the last commit:
```bash
git restore <file>
git restore .
```

* Deleting local branches after merging:
```bash
git branch -d feature/name
```

## 7. Pushing and Security

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

## 8. Checking Changes and Integrity

- Checking Commit Hashes:
```bash
git log --oneline --graph --decorate
```

- Checking Local Integrity:
```bash
git fsck
```

## 9. Backing Up Local Repositories

* Creating a Local Archive
```bash
tar -czf ~/backup-repository.tar.gz repository/
```

* Verify archive:
```bash
ls -lh ~/backup-repository.tar.gz
```

## 8️⃣ Tips

* Use a separate GitHub account for testing.
* Don't push sensitive data.
* Set up .gitignore for temporary files and tokens.
* Enable two-factor authentication.
* Scan directories and logs before deleting.

## 🔑 Operating System Password

* Use a strong user password for your Linux account.
* The password must be unique, sufficiently long, more than 10 characters, and randomly complex.
* Never use the root password for everyday work with Git or scripts.
* If you need to run scripts with `sudo`, make sure the command is safe:
  - Trust only trusted sources.
  - Read the script and check which commands are executed with root privileges.
    - This is especially important for the following commands: `rm`, `dd`, `mkfs`, `ln -sf`.
  - Do not copy `sudo` commands from unknown sources.
  - For testing, you can first run the script without `sudo` to check the output and behavior.
  - Use `sudo -l` to find out which commands your account can execute with root privileges.
* If your password is compromised, it makes sense to back up the system or user profile only for the cleaned system.
