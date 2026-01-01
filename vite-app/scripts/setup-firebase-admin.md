# Firebase Admin Setup Guide

This guide explains how to set up Firebase Admin SDK to create admin users.

## Prerequisites

- Firebase project created
- Node.js installed
- Firebase Admin SDK package installed

## Steps

### 1. Install Firebase Admin SDK

```bash
cd vite-app
npm install firebase-admin --save-dev
```

### 2. Download Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **spyware-7bfe6**
3. Click the gear icon (⚙️) next to "Project Overview"
4. Go to **Project Settings**
5. Navigate to **Service Accounts** tab
6. Click **Generate new private key**
7. Save the downloaded JSON file as `firebase-service-account.json` in the `vite-app` directory

⚠️ **Important**: Add `firebase-service-account.json` to `.gitignore` to keep it secure!

### 3. Add to .gitignore

Make sure your `.gitignore` includes:

```
firebase-service-account.json
```

### 4. Create Admin User

Run the script to create an admin user:

```bash
node scripts/create-admin.js <email> <password> [role] [displayName]
```

**Examples:**

```bash
# Create super admin
node scripts/create-admin.js admin@library.dz Admin123! super_admin "Super Admin"

# Create regular admin
node scripts/create-admin.js admin@example.com MyPassword123 admin "Admin User"

# Create librarian
node scripts/create-admin.js librarian@example.com LibPass456 librarian "Librarian Name"
```

**Available Roles:**
- `super_admin` - Full access to all features
- `admin` - Can manage libraries, books, shelves, etc.
- `librarian` - Limited access to specific library

### 5. Verify Admin User

After creating the admin user, you can verify it in Firebase Console:

1. Go to **Authentication** > **Users**
2. You should see the created user
3. The user should have email verification enabled

You can also check Firestore:

1. Go to **Firestore Database**
2. Open the `admin_users` collection
3. You should see a document with the user's UID

### 6. Login

Visit your application at `http://localhost:5173/login` and use the credentials:

- **Email**: The email you provided
- **Password**: The password you provided

## Troubleshooting

### Error: Service account key not found

Make sure you downloaded the service account key and saved it as `firebase-service-account.json` in the `vite-app` directory.

### Error: Permission denied

Make sure your Firebase project has Firestore enabled and the service account has proper permissions.

### Error: Email already exists

If the user already exists, the script will update the password and ensure the Firestore document is created.

## Security Notes

- Never commit `firebase-service-account.json` to version control
- Use strong passwords for admin users
- Regularly rotate service account keys
- Limit service account permissions to only what's needed
- Consider using Firebase Authentication with email verification for additional security

