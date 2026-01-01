# Admin Setup Instructions

This guide will help you set up the admin dashboard and create your first admin user.

## Prerequisites

- Node.js installed (v18 or higher)
- Firebase project created
- Firebase configuration added to the project

## Step 1: Install Dependencies

```bash
cd vite-app
npm install
```

## Step 2: Configure Firebase

1. Create a `.env` file in the `vite-app` directory with your Firebase credentials:

```env
VITE_FIREBASE_API_KEY=AIzaSyB5jl-Ex0BdOsXa5cCDGgY4tGOEzhUrUtU
VITE_FIREBASE_AUTH_DOMAIN=spyware-7bfe6.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=spyware-7bfe6
VITE_FIREBASE_STORAGE_BUCKET=spyware-7bfe6.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=53191143209
VITE_FIREBASE_APP_ID=1:53191143209:web:e81eeb2352e35e9abed138
```

2. Download your Firebase service account key:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project: **spyware-7bfe6**
   - Click the gear icon (⚙️) → **Project Settings**
   - Go to **Service Accounts** tab
   - Click **Generate new private key**
   - Save as `firebase-service-account.json` in the `vite-app` directory

## Step 3: Create Admin User

Use the Firebase Admin script to create your first admin user:

```bash
npm run create-admin admin@library.dz YourSecurePassword123! super_admin "Super Admin"
```

**Parameters:**
- `email`: Admin email address
- `password`: Strong password (min 6 characters)
- `role`: User role (`super_admin`, `admin`, or `librarian`)
- `displayName`: Full name of the admin

**Example outputs:**

```bash
# Create super admin
npm run create-admin admin@library.dz Admin123! super_admin "Super Admin"

# Create regular admin
npm run create-admin manager@library.dz Manager456! admin "Library Manager"

# Create librarian for specific library
npm run create-admin librarian@library.dz Lib789! librarian "Ahmed Ben Ali"
```

## Step 4: Start the Development Server

```bash
npm run dev
```

The application will be available at `http://localhost:5173`

## Step 5: Login

1. Navigate to `http://localhost:5173/login`
2. Enter your admin credentials
3. You'll be redirected to the admin dashboard

## Features Overview

### Authentication
- **Login/Logout**: Secure authentication with Firebase Auth
- **Role-based Access**: Different permissions for super_admin, admin, and librarian
- **Protected Routes**: Automatic redirect to login if not authenticated

### Dashboard Features

#### 1. Library Management
- View all libraries
- Add new libraries
- Edit library details
- Upload library logos
- Filter by wilaya (region)

#### 2. Books Management
- View all books
- Add new books
- Edit book details
- Upload book covers
- Filter by category
- Search books

#### 3. Floor Management
- View floors by library
- Add new floors
- Edit floor details
- Upload floor maps
- Set floor dimensions

#### 4. Shelf Management
- View shelves by floor
- Add new shelves
- Edit shelf details
- Set 3D positions
- Track shelf capacity and accuracy
- View books on each shelf

#### 5. Analytics Dashboard
- View scan statistics
- Track correction activities
- Monitor accuracy trends
- Identify top misplaced shelves
- See most scanned books
- Date range filtering
- Interactive charts (Recharts)

#### 6. User Management (Super Admin Only)
- View all admin users
- Create new admin accounts
- Edit user roles
- Manage permissions
- Assign libraries to librarians

### Real-time Updates
All data is synchronized in real-time using Firestore listeners:
- Libraries list updates automatically
- Books list updates automatically
- Scan activities appear instantly
- Correction progress updates live
- Misplaced books list updates in real-time

### File Uploads
Upload and manage files with automatic optimization:
- **Library Logos**: Compressed to 512x512px
- **Floor Maps**: Compressed to 2048x2048px
- **Book Covers**: Compressed to 800x1200px
- Automatic image compression
- Progress indicators
- Error handling

## User Roles

### Super Admin
- Full access to all features
- Can create and manage admin users
- Can manage all libraries
- Access to system configuration

### Admin
- Can manage libraries, books, floors, and shelves
- Can view analytics
- Cannot manage users
- Cannot access system configuration

### Librarian
- Limited to assigned library
- Can manage books and shelves in their library
- Can view analytics for their library
- Cannot create new libraries
- Cannot manage users

## Troubleshooting

### Cannot login
- Verify your email and password are correct
- Check that the user exists in Firebase Authentication
- Ensure the user has an entry in the `admin_users` collection in Firestore
- Check browser console for errors

### Firebase not connecting
- Verify `.env` file has correct Firebase credentials
- Check Firebase project is active
- Ensure Firestore and Authentication are enabled in Firebase Console

### Admin script fails
- Verify `firebase-service-account.json` exists and is valid
- Check you have proper permissions in Firebase
- Ensure the email is not already in use

### File upload fails
- Check Firebase Storage is enabled
- Verify storage rules allow uploads
- Ensure file size is under 5MB
- Check internet connection

## Security Best Practices

1. **Never commit sensitive files**:
   - `.env` file
   - `firebase-service-account.json`
   - These are already in `.gitignore`

2. **Use strong passwords**:
   - Minimum 8 characters
   - Mix of uppercase, lowercase, numbers, and symbols

3. **Limit super admin accounts**:
   - Create only necessary super admin accounts
   - Use regular admin accounts for daily operations

4. **Regular backups**:
   - Export Firestore data regularly
   - Keep backups of service account keys

5. **Monitor access**:
   - Check Firebase Authentication logs
   - Review Firestore audit logs
   - Monitor for suspicious activity

## Support

For issues or questions:
1. Check the `TROUBLESHOOTING.md` file
2. Review Firebase Console logs
3. Check browser developer console
4. Review the `IMPLEMENTATION_GUIDE.md` for technical details

## Next Steps

After setting up your admin account:

1. **Add Libraries**: Start by adding your libraries
2. **Add Books**: Import or add books to the system
3. **Configure Floors**: Set up floors for each library
4. **Add Shelves**: Configure shelves on each floor
5. **Create Users**: Add librarians and other admins as needed
6. **Monitor Analytics**: Track system usage and book organization

---

**Important**: Keep your Firebase credentials and service account key secure. Never share them publicly or commit them to version control.

