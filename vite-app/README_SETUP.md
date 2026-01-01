# Quick Setup Guide

## 🚀 Get Started in 5 Minutes

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Firebase
Create `.env` file:
```env
VITE_FIREBASE_API_KEY=AIzaSyB5jl-Ex0BdOsXa5cCDGgY4tGOEzhUrUtU
VITE_FIREBASE_AUTH_DOMAIN=spyware-7bfe6.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=spyware-7bfe6
VITE_FIREBASE_STORAGE_BUCKET=spyware-7bfe6.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=53191143209
VITE_FIREBASE_APP_ID=1:53191143209:web:e81eeb2352e35e9abed138
```

### 3. Download Service Account Key
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Project Settings → Service Accounts
3. Generate new private key
4. Save as `firebase-service-account.json`

### 4. Create Admin User
```bash
npm run create-admin admin@library.dz YourPassword123! super_admin "Admin Name"
```

### 5. Start Development Server
```bash
npm run dev
```

### 6. Login
Visit http://localhost:5173/login

---

For detailed instructions, see [ADMIN_SETUP_INSTRUCTIONS.md](./ADMIN_SETUP_INSTRUCTIONS.md)
