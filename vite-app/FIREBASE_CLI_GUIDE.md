# Firebase CLI Setup Guide

This guide explains how to use Firebase CLI for managing your Firebase project, deploying rules, hosting, and creating admin users.

## Prerequisites

- Node.js installed (v18 or higher)
- Firebase account
- Firebase project created

## Installation

### 1. Install Firebase CLI

```bash
npm install -g firebase-tools
```

Verify installation:

```bash
firebase --version
```

### 2. Login to Firebase

```bash
firebase login
```

This will open a browser window to authenticate with your Google account.

### 3. Initialize Firebase Project

```bash
firebase init
```

Or use the npm script:

```bash
npm run firebase:init
```

Select the services you want to initialize:

- ✅ Firestore
- ✅ Hosting
- ✅ Storage
- ✅ Emulators

## Configuration Files

The following files are already configured:

### `firebase.json`

Main Firebase configuration file defining:

- Firestore rules and indexes
- Hosting settings
- Storage rules
- Emulator configuration

### `.firebaserc`

Project configuration with default project ID: `spyware-7bfe6`

### `firestore.rules`

Security rules for Firestore database

### `storage.rules`

Security rules for Firebase Storage

### `firestore.indexes.json`

Composite indexes for Firestore queries

## Common Commands

### Project Management

```bash
# List available projects
firebase projects:list

# Set active project
firebase use spyware-7bfe6

# Or use npm script
npm run firebase:use
```

### Firestore

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Deploy both
firebase deploy --only firestore
```

### Storage

```bash
# Deploy Storage rules
firebase deploy --only storage
```

### Hosting

```bash
# Build and deploy hosting
npm run build
firebase deploy --only hosting

# Or use npm script
npm run firebase:deploy:hosting
```

### Deploy Everything

```bash
# Deploy all services (builds first)
npm run firebase:deploy

# Or manually
npm run build
firebase deploy
```

## Creating Admin Users

### Method 1: Using Firebase CLI Script (Recommended)

```bash
# Using npm script
npm run create-admin:cli admin@library.dz Password123! super_admin "Super Admin"

# Or directly
./scripts/create-admin-firebase-cli.sh admin@library.dz Password123! super_admin "Super Admin"
```

This script:

1. Checks if Firebase CLI is installed
2. Verifies you're logged in
3. Uses the service account key
4. Creates the admin user via Admin SDK

### Method 2: Using Node.js Script Directly

```bash
npm run create-admin admin@library.dz Password123! super_admin "Super Admin"
```

## Using Emulators

Start Firebase emulators for local development:

```bash
npm run firebase:emulators
```

Or directly:

```bash
firebase emulators:start
```

This starts:

- Auth Emulator: `http://localhost:9099`
- Firestore Emulator: `http://localhost:8080`
- Storage Emulator: `http://localhost:9199`
- Emulator UI: `http://localhost:4000`

### Configure App to Use Emulators

In your `.env` file:

```env
VITE_USE_FIREBASE_EMULATOR=true
```

## Data Management

### Export Firestore Data

```bash
# Export to default location
firebase firestore:export

# Export to specific directory
firebase firestore:export ./backups/firestore-$(date +%Y%m%d)
```

### Import Firestore Data

```bash
firebase firestore:import ./backups/firestore-20250115
```

## Security Rules

### View Current Rules

```bash
# Firestore rules
firebase firestore:rules

# Storage rules
firebase storage:rules
```

### Deploy Rules

```bash
# Deploy all rules
npm run firebase:deploy:rules

# Or individually
firebase deploy --only firestore:rules
firebase deploy --only storage
```

### Test Rules Locally

```bash
# Start emulators with rules
firebase emulators:start --only firestore,storage
```

## Helper Script

Use the helper script for common operations:

```bash
# Source the script
source scripts/firebase-cli-utils.sh

# Use functions
firebase_login
deploy_all
start_emulators
export_firestore
show_project_info
```

## NPM Scripts Reference

| Script                    | Command                | Description           |
| ------------------------- | ---------------------- | --------------------- |
| `firebase:login`          | `firebase login`       | Login to Firebase     |
| `firebase:init`           | `firebase init`        | Initialize Firebase   |
| `firebase:use`            | `firebase use`         | Set active project    |
| `firebase:deploy`         | Build + Deploy         | Deploy everything     |
| `firebase:deploy:hosting` | Build + Deploy hosting | Deploy web app        |
| `firebase:deploy:rules`   | Deploy rules           | Deploy security rules |
| `firebase:emulators`      | Start emulators        | Local development     |
| `firebase:export`         | Export data            | Export Firestore      |
| `firebase:import`         | Import data            | Import Firestore      |
| `create-admin:cli`        | Create admin           | Create admin user     |

## Troubleshooting

### Not Logged In

```bash
firebase login
```

### Wrong Project

```bash
firebase use spyware-7bfe6
```

### Permission Denied

Make sure you have the correct permissions in Firebase Console:

1. Go to Firebase Console
2. Select your project
3. Go to Project Settings > Users and permissions
4. Verify your account has Owner or Editor role

### Rules Not Deploying

Check if rules file exists and has correct syntax:

```bash
# Validate Firestore rules
firebase deploy --only firestore:rules --dry-run
```

### Build Fails Before Deploy

```bash
# Build manually first
npm run build

# Check for errors
npm run lint
```

## Best Practices

1. **Always test rules locally** before deploying:

   ```bash
   firebase emulators:start --only firestore,storage
   ```

2. **Export data regularly**:

   ```bash
   firebase firestore:export ./backups/$(date +%Y%m%d)
   ```

3. **Use version control** for rules:

   - Commit `firestore.rules`
   - Commit `storage.rules`
   - Commit `firestore.indexes.json`

4. **Deploy rules separately** from hosting:

   ```bash
   npm run firebase:deploy:rules
   ```

5. **Use emulators for development**:
   ```bash
   npm run firebase:emulators
   ```

## Production Deployment Workflow

1. **Test locally**:

   ```bash
   npm run dev
   npm run firebase:emulators
   ```

2. **Build for production**:

   ```bash
   npm run build
   ```

3. **Preview build**:

   ```bash
   npm run preview
   ```

4. **Deploy rules first**:

   ```bash
   npm run firebase:deploy:rules
   ```

5. **Deploy hosting**:
   ```bash
   npm run firebase:deploy:hosting
   ```

## Additional Resources

- [Firebase CLI Documentation](https://firebase.google.com/docs/cli)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Storage Security Rules](https://firebase.google.com/docs/storage/security)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)

---

**Quick Start**:

```bash
# 1. Install and login
npm install -g firebase-tools
firebase login

# 2. Set project
firebase use spyware-7bfe6

# 3. Create admin
npm run create-admin:cli admin@library.dz Password123! super_admin "Admin"

# 4. Deploy
npm run firebase:deploy
```
