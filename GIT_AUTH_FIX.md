# Fix GitHub Authentication Issue

## Problem
GitHub no longer accepts password authentication for HTTPS. You need to use either:
1. **Personal Access Token (PAT)** - Recommended for HTTPS
2. **SSH Keys** - Alternative option

## Solution 1: Use Personal Access Token (PAT)

### Step 1: Create a Personal Access Token
1. Go to GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a name (e.g., "book-app-access")
4. Select scopes: `repo` (full control of private repositories)
5. Click "Generate token"
6. **Copy the token immediately** (you won't see it again!)

### Step 2: Update Git Remote with Token

**Option A: Update remote URL with token embedded**
```bash
cd flutter_application_1
git remote set-url origin https://YOUR_TOKEN@github.com/rehza97/book-app.git
```

**Option B: Use Git Credential Manager (Recommended)**
```bash
cd flutter_application_1
# When prompted for password, paste your token instead
git pull origin main
```

**Option C: Store credentials in Git config**
```bash
cd flutter_application_1
git config credential.helper store
git pull origin main
# Enter your username and paste token as password
```

## Solution 2: Switch to SSH (Alternative)

### Step 1: Generate SSH Key (if you don't have one)
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
# Press Enter to accept default location
# Optionally set a passphrase
```

### Step 2: Add SSH Key to GitHub
```bash
# Copy your public key
cat ~/.ssh/id_ed25519.pub
# Copy the output
```

1. Go to GitHub.com → Settings → SSH and GPG keys
2. Click "New SSH key"
3. Paste your public key
4. Click "Add SSH key"

### Step 3: Change Remote to SSH
```bash
cd flutter_application_1
git remote set-url origin git@github.com:rehza97/book-app.git
git pull origin main
```

## Quick Fix (Using PAT)

If you already have a token, run:
```bash
cd flutter_application_1
git remote set-url origin https://YOUR_TOKEN@github.com/rehza97/book-app.git
git pull origin main
```

Replace `YOUR_TOKEN` with your actual Personal Access Token.

## Verify
```bash
cd flutter_application_1
git remote -v
git pull origin main
```


