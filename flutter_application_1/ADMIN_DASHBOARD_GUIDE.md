# Admin Dashboard Implementation Guide

## Overview
This guide provides a roadmap for building an admin dashboard to control and manage the AR Book Scanner application using the Firebase schema.

## Recommended Technology Stack

### Option 1: Flutter Web (Recommended)
- **Pros**: Same codebase, shared models, easy deployment
- **Cons**: Limited web-specific features
- **Best for**: Quick implementation, code reuse

### Option 2: React + TypeScript
- **Pros**: Rich ecosystem, better web UX, faster development
- **Cons**: Separate codebase, need to duplicate models
- **Best for**: Professional admin dashboard, complex features

### Option 3: Next.js + TypeScript
- **Pros**: Server-side rendering, SEO, modern framework
- **Cons**: More complex setup
- **Best for**: Production-ready admin panel

## Dashboard Structure

```
admin-dashboard/
├── pages/
│   ├── login/
│   ├── dashboard/          # Overview/Home
│   ├── libraries/          # Library management
│   ├── books/              # Book catalog
│   ├── shelves/            # Shelf management
│   ├── scans/              # Scan history
│   ├── corrections/        # Correction tracking
│   ├── users/              # User management
│   ├── analytics/          # Analytics & reports
│   └── settings/           # System settings
├── components/
│   ├── Layout/
│   ├── Charts/
│   ├── Tables/
│   └── Forms/
└── services/
    └── firebase-admin.ts
```

## Key Features to Implement

### 1. Authentication & Authorization
- Firebase Auth integration
- Role-based access control (Super Admin, Admin, Librarian)
- Permission checking
- Session management

### 2. Dashboard Overview
- Total libraries count
- Total books count
- Recent scans
- Shelf accuracy metrics
- Misplaced books count
- Active users
- Charts and graphs

### 3. Library Management
- List all libraries
- Create/Edit/Delete libraries
- View library details
- Manage library settings
- Library statistics

### 4. Book Management
- Search books
- Add/Edit/Delete books
- Bulk import (CSV/Excel)
- Book details view
- Book location tracking
- Cover image upload

### 5. Shelf Management
- View shelves by library/floor
- Create/Edit/Delete shelves
- Shelf capacity management
- Shelf accuracy monitoring
- Book position management

### 6. Scan History
- View all scans
- Filter by library, date, user
- Scan details
- Export scan data
- Scan analytics

### 7. Correction Tracking
- View correction sessions
- Track correction progress
- Correction history
- Performance metrics

### 8. User Management
- List users
- Create/Edit/Delete users
- Assign roles
- Manage permissions
- User activity logs

### 9. Analytics & Reports
- Dashboard metrics
- Shelf accuracy trends
- Scan frequency
- Most scanned books
- Misplaced books reports
- Export reports (PDF/Excel)

### 10. System Settings
- App configuration
- Feature flags
- Maintenance mode
- System logs

## Firebase Admin SDK Setup

### For Node.js/TypeScript:

```typescript
import * as admin from 'firebase-admin';
import serviceAccount from './service-account-key.json';

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://your-project.firebaseio.com'
});

export const db = admin.firestore();
export const auth = admin.auth();
```

### For Flutter Web:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Use same FirebaseService as mobile app
```

## Key Queries for Dashboard

### 1. Dashboard Overview Stats

```typescript
// Total libraries
const librariesCount = await db.collection('libraries')
  .where('isActive', '==', true)
  .count()
  .get();

// Total books
const booksCount = await db.collection('books')
  .where('isActive', '==', true)
  .count()
  .get();

// Recent scans (last 24 hours)
const recentScans = await db.collection('scans')
  .where('createdAt', '>=', yesterday)
  .orderBy('createdAt', 'desc')
  .limit(10)
  .get();

// Misplaced books
const misplacedBooks = await db.collection('bookLocations')
  .where('isCorrectOrder', '==', false)
  .count()
  .get();
```

### 2. Library Management

```typescript
// Get all libraries with stats
const libraries = await db.collection('libraries')
  .where('isActive', '==', true)
  .get();

// Get library with real-time updates
const libraryRef = db.collection('libraries').doc(libraryId);
libraryRef.onSnapshot((doc) => {
  // Update UI
});
```

### 3. Shelf Accuracy Monitoring

```typescript
// Get shelves with low accuracy
const lowAccuracyShelves = await db.collectionGroup('shelves')
  .where('accuracy', '<', 90)
  .orderBy('accuracy', 'asc')
  .limit(20)
  .get();
```

### 4. Book Search & Management

```typescript
// Search books (client-side filtering)
const allBooks = await db.collection('books')
  .where('isActive', '==', true)
  .limit(100)
  .get();

// Filter by category
const booksByCategory = await db.collection('books')
  .where('category', '==', category)
  .where('isActive', '==', true)
  .get();
```

### 5. Analytics Queries

```typescript
// Daily analytics
const dailyAnalytics = await db.collection('analytics')
  .where('date', '>=', startDate)
  .where('date', '<=', endDate)
  .orderBy('date', 'asc')
  .get();

// Library-specific analytics
const libraryAnalytics = await db.collection('analytics')
  .where('libraryId', '==', libraryId)
  .where('date', '>=', startDate)
  .orderBy('date', 'asc')
  .get();
```

## UI Components Recommendations

### 1. Data Tables
- Use libraries like:
  - **React**: `react-table`, `@tanstack/react-table`
  - **Flutter**: `data_table_2`, `pluto_grid`
- Features: Sorting, filtering, pagination, export

### 2. Charts
- Use libraries like:
  - **React**: `recharts`, `chart.js`, `victory`
  - **Flutter**: `fl_chart`, `syncfusion_flutter_charts`
- Charts needed:
  - Line charts (accuracy trends)
  - Bar charts (scan counts)
  - Pie charts (category distribution)
  - Area charts (activity over time)

### 3. Forms
- Use libraries like:
  - **React**: `react-hook-form`, `formik`
  - **Flutter**: `flutter_form_builder`
- Features: Validation, file upload, rich inputs

### 4. Layout
- Use component libraries:
  - **React**: `Material-UI`, `Ant Design`, `Chakra UI`
  - **Flutter**: `flutter_admin_scaffold`

## Security Considerations

### 1. Firebase Security Rules
- Implement strict rules (see FIREBASE_SCHEMA.md)
- Role-based access in rules
- Validate data on write

### 2. Admin Authentication
- Use Firebase Auth
- Implement 2FA for admins
- Session timeout
- IP whitelisting (optional)

### 3. Data Validation
- Validate all inputs
- Sanitize user data
- Rate limiting
- CSRF protection

## Deployment Options

### 1. Firebase Hosting (Recommended)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize
firebase init hosting

# Deploy
firebase deploy --only hosting
```

### 2. Vercel
- Connect GitHub repo
- Auto-deploy on push
- Free tier available

### 3. Netlify
- Drag & drop deployment
- Continuous deployment
- Free tier available

### 4. Self-hosted
- Docker container
- Nginx reverse proxy
- SSL certificate

## Quick Start: Flutter Web Admin Dashboard

### Step 1: Add Web Support
```bash
flutter create --platforms=web .
```

### Step 2: Create Admin Screens
```dart
// lib/admin/screens/admin_dashboard_screen.dart
class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: Row(
        children: [
          // Sidebar navigation
          AdminSidebar(),
          // Main content
          Expanded(
            child: AdminOverview(),
          ),
        ],
      ),
    );
  }
}
```

### Step 3: Use FirebaseService
```dart
final firebaseService = FirebaseService();

// Get libraries
final libraries = await firebaseService.getLibraries();

// Get analytics
final analytics = await firebaseService.getAnalytics();
```

## Quick Start: React Admin Dashboard

### Step 1: Create Next.js App
```bash
npx create-next-app@latest admin-dashboard --typescript
cd admin-dashboard
npm install firebase firebase-admin
```

### Step 2: Setup Firebase
```typescript
// lib/firebase.ts
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  // Your config
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
```

### Step 3: Create Admin Pages
```typescript
// pages/dashboard.tsx
export default function Dashboard() {
  const [libraries, setLibraries] = useState([]);
  
  useEffect(() => {
    // Fetch libraries
  }, []);
  
  return (
    <div>
      <h1>Admin Dashboard</h1>
      {/* Dashboard content */}
    </div>
  );
}
```

## Sample Admin Dashboard Features

### 1. Library Management Page
- Table of all libraries
- Add/Edit/Delete buttons
- Filter by city/wilaya
- View library details modal
- Statistics per library

### 2. Book Management Page
- Search bar
- Category filter
- Book table with cover images
- Add/Edit book form
- Bulk import button
- Export to CSV

### 3. Analytics Page
- Date range picker
- Library selector
- Charts:
  - Scans over time
  - Shelf accuracy
  - Most scanned books
  - Misplaced books by shelf
- Export reports

### 4. User Management Page
- User table
- Role assignment
- Permission management
- Activity logs
- Enable/Disable users

## Testing Strategy

1. **Unit Tests**: Test Firebase queries
2. **Integration Tests**: Test admin workflows
3. **E2E Tests**: Test complete admin operations
4. **Security Tests**: Test permission boundaries

## Monitoring & Logging

1. **Firebase Analytics**: Track admin actions
2. **Error Logging**: Sentry or Firebase Crashlytics
3. **Performance Monitoring**: Firebase Performance
4. **Audit Logs**: Track all admin changes

## Next Steps

1. Choose technology stack
2. Setup Firebase Admin SDK
3. Implement authentication
4. Create basic layout
5. Implement library management
6. Add book management
7. Implement analytics
8. Add user management
9. Deploy dashboard
10. Add monitoring

## Resources

- [Firebase Admin SDK Docs](https://firebase.google.com/docs/admin/setup)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Flutter Web](https://flutter.dev/web)
- [Next.js Docs](https://nextjs.org/docs)
- [React Admin](https://marmelab.com/react-admin/)


