# 🚀 Quick Start Guide

Get your admin dashboard up and running in 5 minutes!

## Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

## Step 2: Login to Firebase

```bash
firebase login
```

## Step 3: Set Firebase Project

```bash
cd vite-app
firebase use spyware-7bfe6
```

## Step 4: Download Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **spyware-7bfe6**
3. Click ⚙️ (Settings) → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate new private key**
6. Save the JSON file as `firebase-service-account.json` in the `vite-app` directory

⚠️ **Important**: Add `firebase-service-account.json` to `.gitignore` (already added)

## Step 5: Create Admin User

```bash
npm run create-admin:cli admin@library.dz "YourPassword123!" super_admin "Admin Name"
```

**Note**: Use quotes around password if it contains special characters, and quotes around display name if it has spaces.

**Examples**:

```bash
# Simple password
npm run create-admin:cli admin@example.com Password123 super_admin "Super Admin"

# Password with special characters (use quotes)
npm run create-admin:cli admin@example.com "P@ssw0rd!" super_admin "Admin Name"

# Multiple words in display name (use quotes)
npm run create-admin:cli admin@example.com Password123 admin "Ahmed Ben Ali"
```

## Step 6: Start Development Server

```bash
npm run dev
```

## Step 7: Login

1. Open http://localhost:5173/login
2. Enter your admin credentials:
   - Email: `admin@library.dz` (or the email you used)
   - Password: The password you set

## That's it! 🎉

You're now logged in to the admin dashboard!

---

## Troubleshooting

### Service Account Key Not Found

Make sure you:
1. Downloaded the key from Firebase Console
2. Saved it as `firebase-service-account.json`
3. Placed it in the `vite-app` directory (same level as `package.json`)

### Admin User Creation Fails

Check:
- Firebase CLI is installed: `firebase --version`
- You're logged in: `firebase login`
- Service account key exists: `ls firebase-service-account.json`
- Project is set: `firebase use`

### Login Doesn't Work

Verify:
- User was created successfully (check terminal output)
- Email and password are correct
- User exists in Firebase Console → Authentication → Users
- User document exists in Firestore → `admin_users` collection

---

## Next Steps

- [Deploy to Production](./DEPLOYMENT_CHECKLIST.md)
- [Full Setup Guide](./ADMIN_SETUP_INSTRUCTIONS.md)
- [Firebase CLI Guide](./FIREBASE_CLI_GUIDE.md)

