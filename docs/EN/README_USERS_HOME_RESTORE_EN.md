# README_USERS_HOME_RESTORE.md

[🇬🇧 English](README_USERS_HOME_RESTORE_EN.md) | [🇷🇺 Русский](../RU/RREADME_USERS_HOME_RESTORE_RU.md)

## TL;DR / Quick Check

If after reinstalling Ubuntu the user cannot log in
or does not have access to their `/home`:

1. Check the user's UID:
`getent passwd username`
2. Check the directory owner:
`ls -ld /home/username`
3. If the owner is `root` or the old UID, and you are sure of the data:
`sudo chown -R username:username /home/username`

⚠️ Never run `chown -R /home` without a thorough check.

## Purpose of this document

This document addresses a known Ubuntu/Linux issue that occurs after a system reinstall or manual restoration of the /home partition, and describes the canonical procedure for diagnosing and restoring user home directories.

The goal is not to blindly automate the problem, but to understand its cause, safely check the system, and deliberately fix it while preserving user data.

This document is intended for:
- Reinstalling Ubuntu while preserving /home
- Restoring the system from a backup
- Manually mounting the old /home
- Using it as part of the Reincarnation Backup Kit (REBK)

---

## The Problem

After reinstalling Ubuntu:

- User accounts are recreated
- Each user is assigned a **new UID**
- The /home/username directories may remain:
- Owned by root:root
- Owned by the old UID, which no longer exists

Example:
```bash
$ ls -ld /home/username
drwx------ root root /home/username
```

or:
```bash
drwx------ 1001 1001 /home/username
```

where UID 1001 is **not associated with the current user**.

### Important

This is **normal and intended behavior by Ubuntu**.

The system **does not have the right to automatically change the data owner** because:
- `/home` may have been mounted intentionally
- the data may belong to a different user
- automatic `chown -R` is potentially dangerous

---

## Symptoms of the problem

- user cannot log in
- blank desktop
- file access errors
- applications do not save settings
- in the terminal:
```bash
Permission denied
```
- REBK operation to restore user data failed

---

## Principle of the correct solution

❌ Incorrect:
- automatically change the owners of all directories
- run `chown -R /home` without checking

✅ Correct:
- **check first**
- **understand the user and directory mapping**
- **fix only the specific case**

---

## Stage 1. Diagnostics (audit)

### 1. Check for existence User

```bash
getent passwd username
```

Expected result:
```
username:x:1000:1000:...:/home/username:/bin/bash
```

Note:
- User UID
- Path to home directory

### 2. Checking directory ownership

```bash
ls -ld /home/username
```

or:
```bash
stat /home/username
```

Compare:
- Directory owner
- User UID

### 3. Common problem states

| State | Danger |
|---------|----------|
| `root:root` | User does not have access |
| Old UID | Hidden incompatibility |
| Directory is empty | Possible mount error or invalid /home |

## Stage 2. Informed Recovery

Before any changes:

- user **must exist**
- directory **must be valid** (`/home/username`)
- you are sure the data belongs to this user

### Fixing Owner

```bash
sudo chown -R username:username /home/username
```

⚠️ This command applies **only to a specific directory**, never to the entire `/home`.

## Protective Restrictions (Mandatory)

Any tools or scripts **must fail** if:

- username is `root`
- directory is not in `/home`
- user does not exist
- path is empty or suspicious

This is a safeguard against irreversible errors.

## Recommended Automation

Automation is allowed in **only two modes**:

1. **Audit** — audit and report (default)
2. **Fix** — fix by explicit flag and confirmation

Automatic fix without auditing is prohibited.

## Relationship with Reincarnation Backup Kit (REBK)

This document is the **canonical procedure for restoring user data** and is used as:

- the basis for REBK scripts
- a post-reinstallation checklist
- an explanation of Ubuntu's architectural behavior

## Philosophy

> Reinstalling a system is not about losing data,
> it's about verifying that we understand who owns it.

This document captures this knowledge so that the problem:
- doesn't recur
- isn't solved blindly
- doesn't destroy data

---

**Status:** Canonical / Stable
