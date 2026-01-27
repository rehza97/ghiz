# Firebase Firestore Database Schema

## Overview
This document describes the complete Firestore database schema for the AR Book Scanner application, optimized for both mobile app usage and admin dashboard management.

## Collection Structure

```
firestore/
├── libraries/                    # Main libraries collection
│   └── {libraryId}/
│       ├── floors/               # Subcollection: Floors
│       │   └── {floorId}/
│       │       ├── shelves/      # Subcollection: Shelves
│       │       │   └── {shelfId}/
│       │       │       └── books/ # Subcollection: Books on shelf
│       │       └── beacons/      # Subcollection: IPS Beacons
│       └── settings/             # Library-specific settings
├── books/                        # Global books catalog (ISBN as document ID)
├── bookLocations/                 # Book location tracking
├── scans/                        # Scan history
├── corrections/                   # Correction sessions
├── users/                        # User accounts
├── admins/                       # Admin accounts
├── analytics/                     # Analytics data
└── system/                       # System configuration
```

---

## Collections

### 1. `libraries` Collection

**Document ID**: `{libraryId}` (e.g., `lib_001`)

**Fields**:
```typescript
{
  id: string,                    // Same as document ID
  name: string,                  // "Bibliothèque Nationale d'Algérie"
  address: string,               // "1 Rue Docteur Saâdane"
  postalCode: string,            // "16000"
  city: string,                  // "Alger"
  wilaya: string,                // "Alger" (for filtering)
  phone?: string,               // "+213 21 66 12 34"
  email?: string,                // "contact@bna.dz"
  floorCount: number,            // 4
  latitude: number,              // 36.7538
  longitude: number,             // 3.0588
  logoUrl?: string,              // URL to logo image
  hours?: string,                // "Dim-Jeu: 8h-17h"
  description?: string,
  isActive: boolean,             // true (for admin control)
  createdAt: timestamp,
  updatedAt: timestamp,
  createdBy: string,             // Admin user ID
  stats: {
    totalBooks: number,
    totalShelves: number,
    totalFloors: number,
    lastScanDate?: timestamp
  }
}
```

**Indexes Required**:
- `city` (ascending)
- `wilaya` (ascending)
- `isActive` (ascending)

---

### 2. `libraries/{libraryId}/floors` Subcollection

**Document ID**: `{floorId}` (e.g., `floor_001`)

**Fields**:
```typescript
{
  id: string,                    // Same as document ID
  name: string,                  // "Rez-de-chaussée"
  floorNumber: number,           // 0 (RDC), 1, 2, etc.
  libraryId: string,             // Parent library ID
  mapAssetPath?: string,         // Path to floor map image
  mapUrl?: string,               // Firebase Storage URL
  description?: string,
  shelfCount: number,            // Number of shelves
  mapWidth?: number,             // Map width in pixels
  mapHeight?: number,            // Map height in pixels
  isActive: boolean,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Indexes Required**:
- `libraryId` + `floorNumber` (composite)

---

### 3. `libraries/{libraryId}/floors/{floorId}/shelves` Subcollection

**Document ID**: `{shelfId}` (e.g., `shelf_004`)

**Fields**:
```typescript
{
  id: string,                    // Same as document ID
  name: string,                  // "A-1-1" or "B-2-1"
  floorId: string,               // Parent floor ID
  libraryId: string,             // Parent library ID
  x: number,                     // Position X (meters)
  y: number,                     // Position Y (meters)
  z: number,                     // Position Z (height)
  width: number,                 // Width (meters)
  height: number,                // Height (meters)
  depth: number,                 // Depth (meters)
  category?: string,             // "Fiction", "Science", etc.
  capacity: number,               // Max books capacity
  currentCount: number,          // Current number of books
  description?: string,
  isActive: boolean,
  lastCorrectionDate?: timestamp,
  accuracy: number,              // Percentage (0-100)
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Indexes Required**:
- `floorId` + `category` (composite)
- `libraryId` + `isActive` (composite)

---

### 4. `libraries/{libraryId}/floors/{floorId}/shelves/{shelfId}/books` Subcollection

**Document ID**: `{bookIsbn}` (ISBN as document ID)

**Fields**:
```typescript
{
  bookIsbn: string,              // ISBN (same as document ID)
  position: number,               // Current position (1-indexed)
  expectedPosition: number,       // Expected position
  isCorrectOrder: boolean,        // Is at correct position
  isFlagged: boolean,             // Flagged for review
  reason?: string,                // Reason if misplaced
  lastCheckedAt?: timestamp,      // Last verification date
  misplacementCount: number,     // Number of times misplaced
  addedAt: timestamp,             // When added to shelf
  updatedAt: timestamp
}
```

**Indexes Required**:
- `position` (ascending)
- `expectedPosition` (ascending)
- `isCorrectOrder` (ascending)

---

### 5. `books` Collection

**Document ID**: `{isbn}` (ISBN as document ID for easy lookup)

**Fields**:
```typescript
{
  isbn: string,                   // Same as document ID
  title: string,                  // "Le Seigneur des Anneaux"
  author: string,                 // "J.R.R. Tolkien"
  category: string,               // "Fantasy"
  coverUrl?: string,              // Book cover image URL
  description?: string,           // Book description
  publisher?: string,
  publishDate?: string,
  language: string,               // "fr", "ar", "en"
  pageCount?: number,
  isActive: boolean,              // Admin can deactivate
  createdAt: timestamp,
  updatedAt: timestamp,
  addedBy?: string,               // Admin user ID
  stats: {
    totalCopies: number,          // Total copies across all libraries
    totalLocations: number,        // Number of shelf locations
    scanCount: number,             // Total scans
    lastScanDate?: timestamp
  }
}
```

**Indexes Required**:
- `category` (ascending)
- `author` (ascending)
- `isActive` (ascending)
- `title` (full-text search - requires Algolia/Elasticsearch or similar)

---

### 6. `bookLocations` Collection

**Document ID**: Auto-generated

**Fields**:
```typescript
{
  id: string,                     // Auto-generated document ID
  bookIsbn: string,               // Reference to books collection
  libraryId: string,              // Reference to libraries
  floorId: string,                // Reference to floor
  shelfId: string,                // Reference to shelf
  position: number,                // Current position
  expectedPosition: number,        // Expected position
  isCorrectOrder: boolean,
  isFlagged: boolean,
  reason?: string,
  lastCheckedAt?: timestamp,
  misplacementCount: number,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Indexes Required**:
- `bookIsbn` (ascending)
- `libraryId` + `shelfId` (composite)
- `libraryId` + `isCorrectOrder` (composite)
- `shelfId` + `position` (composite)

---

### 7. `scans` Collection

**Document ID**: Auto-generated

**Fields**:
```typescript
{
  id: string,                     // Auto-generated
  userId?: string,                // User who scanned (if authenticated)
  libraryId: string,
  shelfId: string,
  floorId: string,
  scannedBooks: Array<{
    isbn: string,
    title: string,
    detectedPosition: number,     // Physical position from scan
    expectedPosition: number,
    isCorrect: boolean
  }>,
  totalScanned: number,           // Number of books scanned
  correctCount: number,            // Number correctly positioned
  errorCount: number,             // Number misplaced
  accuracy: number,                // Percentage
  scanDuration: number,            // Duration in seconds
  createdAt: timestamp,
  deviceInfo?: {
    platform: string,              // "android", "ios"
    model?: string,
    osVersion?: string
  }
}
```

**Indexes Required**:
- `libraryId` + `createdAt` (composite, descending)
- `shelfId` + `createdAt` (composite, descending)
- `userId` + `createdAt` (composite, descending)

---

### 8. `corrections` Collection

**Document ID**: Auto-generated

**Fields**:
```typescript
{
  id: string,                     // Auto-generated
  libraryId: string,
  shelfId: string,
  userId?: string,                // User who performed correction
  status: string,                 // "in_progress", "completed", "cancelled"
  totalMoves: number,              // Total movements required
  completedMoves: number,         // Movements completed
  progressPercentage: number,      // 0-100
  movements: Array<{
    bookIsbn: string,
    bookTitle: string,
    fromPosition: number,
    toPosition: number,
    direction: string,             // "left", "right"
    priority: number,               // 0-5
    isCompleted: boolean,
    completedAt?: timestamp
  }>,
  startedAt: timestamp,
  completedAt?: timestamp,
  duration?: number,              // Duration in seconds
  createdAt: timestamp
}
```

**Indexes Required**:
- `libraryId` + `status` + `createdAt` (composite, descending)
- `shelfId` + `status` (composite)
- `userId` + `createdAt` (composite, descending)

---

### 9. `users` Collection

**Document ID**: `{userId}` (Firebase Auth UID)

**Fields**:
```typescript
{
  id: string,                     // Firebase Auth UID
  email: string,
  displayName?: string,
  photoUrl?: string,
  role: string,                   // "user", "librarian", "admin"
  libraryId?: string,             // Associated library (for librarians)
  isActive: boolean,
  lastLoginAt?: timestamp,
  createdAt: timestamp,
  updatedAt: timestamp,
  preferences: {
    language: string,             // "fr", "ar"
    theme?: string                // "light", "dark"
  },
  stats: {
    totalScans: number,
    totalCorrections: number,
    lastScanDate?: timestamp
  }
}
```

**Indexes Required**:
- `role` + `isActive` (composite)
- `libraryId` + `role` (composite)

---

### 10. `admins` Collection

**Document ID**: `{adminId}` (Firebase Auth UID)

**Fields**:
```typescript
{
  id: string,                     // Firebase Auth UID
  email: string,
  displayName: string,
  role: string,                   // "super_admin", "admin", "librarian"
  permissions: {
    canManageLibraries: boolean,
    canManageBooks: boolean,
    canManageUsers: boolean,
    canViewAnalytics: boolean,
    canManageSystem: boolean
  },
  assignedLibraries: string[],    // Array of library IDs
  isActive: boolean,
  lastLoginAt?: timestamp,
  createdAt: timestamp,
  createdBy?: string,             // Admin who created this account
  updatedAt: timestamp
}
```

**Indexes Required**:
- `role` + `isActive` (composite)
- `email` (ascending)

---

### 11. `analytics` Collection

**Document ID**: `{date}` (format: `YYYY-MM-DD`)

**Fields**:
```typescript
{
  date: string,                   // "2024-01-15"
  libraryId?: string,             // Optional: library-specific analytics
  metrics: {
    totalScans: number,
    totalCorrections: number,
    totalBooksScanned: number,
    averageAccuracy: number,      // Average shelf accuracy
    totalMisplacedBooks: number,
    correctionsCompleted: number,
    activeUsers: number
  },
  topMisplacedShelves: Array<{
    shelfId: string,
    shelfName: string,
    errorCount: number
  }>,
  topScannedBooks: Array<{
    isbn: string,
    title: string,
    scanCount: number
  }>,
  createdAt: timestamp
}
```

**Indexes Required**:
- `date` (ascending)
- `libraryId` + `date` (composite, descending)

---

### 12. `system` Collection

**Document ID**: `config`

**Fields**:
```typescript
{
  appVersion: string,             // Current app version
  minAppVersion: string,          // Minimum supported version
  maintenanceMode: boolean,        // Enable/disable app
  maintenanceMessage?: string,    // Message to show users
  features: {
    arScanning: boolean,
    bookSearch: boolean,
    corrections: boolean,
    analytics: boolean
  },
  settings: {
    maxBooksPerScan: number,      // Maximum books per scan session
    scanTimeout: number,           // Scan timeout in seconds
    correctionTimeout: number      // Correction timeout in seconds
  },
  updatedAt: timestamp,
  updatedBy: string               // Admin user ID
}
```

---

## Security Rules Structure

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isActive == true;
    }
    
    function isLibrarian() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'librarian';
    }
    
    // Libraries - Read: all, Write: admin only
    match /libraries/{libraryId} {
      allow read: if true; // Public read
      allow write: if isAdmin();
      
      // Floors subcollection
      match /floors/{floorId} {
        allow read: if true;
        allow write: if isAdmin();
        
        // Shelves subcollection
        match /shelves/{shelfId} {
          allow read: if true;
          allow write: if isAdmin();
          
          // Books on shelf subcollection
          match /books/{bookIsbn} {
            allow read: if true;
            allow write: if isAdmin() || isLibrarian();
          }
        }
      }
    }
    
    // Books - Read: all, Write: admin/librarian
    match /books/{isbn} {
      allow read: if true;
      allow write: if isAdmin() || isLibrarian();
    }
    
    // Scans - Read: own scans or admin, Write: authenticated
    match /scans/{scanId} {
      allow read: if isAuthenticated() && 
                     (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if isAuthenticated();
      allow update, delete: if isAdmin();
    }
    
    // Corrections - Read: own corrections or admin, Write: authenticated
    match /corrections/{correctionId} {
      allow read: if isAuthenticated() && 
                     (resource.data.userId == request.auth.uid || isAdmin());
      allow create, update: if isAuthenticated();
      allow delete: if isAdmin();
    }
    
    // Users - Read: own profile or admin, Write: own profile or admin
    match /users/{userId} {
      allow read: if isAuthenticated() && 
                     (userId == request.auth.uid || isAdmin());
      allow create: if isAuthenticated() && userId == request.auth.uid;
      allow update: if isAuthenticated() && 
                       (userId == request.auth.uid || isAdmin());
      allow delete: if isAdmin();
    }
    
    // Admins - Admin only
    match /admins/{adminId} {
      allow read, write: if isAdmin();
    }
    
    // Analytics - Read: admin only, Write: system/admin
    match /analytics/{date} {
      allow read: if isAdmin();
      allow write: if isAdmin();
    }
    
    // System - Admin only
    match /system/{document=**} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

---

## Indexes Required

### Composite Indexes

1. `libraries` collection:
   - `city` (Ascending)
   - `wilaya` (Ascending)
   - `isActive` (Ascending)

2. `libraries/{libraryId}/floors` subcollection:
   - `libraryId` (Ascending) + `floorNumber` (Ascending)

3. `libraries/{libraryId}/floors/{floorId}/shelves` subcollection:
   - `floorId` (Ascending) + `category` (Ascending)
   - `libraryId` (Ascending) + `isActive` (Ascending)

4. `bookLocations` collection:
   - `libraryId` (Ascending) + `shelfId` (Ascending)
   - `libraryId` (Ascending) + `isCorrectOrder` (Ascending)
   - `shelfId` (Ascending) + `position` (Ascending)

5. `scans` collection:
   - `libraryId` (Ascending) + `createdAt` (Descending)
   - `shelfId` (Ascending) + `createdAt` (Descending)
   - `userId` (Ascending) + `createdAt` (Descending)

6. `corrections` collection:
   - `libraryId` (Ascending) + `status` (Ascending) + `createdAt` (Descending)
   - `shelfId` (Ascending) + `status` (Ascending)
   - `userId` (Ascending) + `createdAt` (Descending)

7. `users` collection:
   - `role` (Ascending) + `isActive` (Ascending)
   - `libraryId` (Ascending) + `role` (Ascending)

8. `analytics` collection:
   - `libraryId` (Ascending) + `date` (Descending)

---

## Data Migration Strategy

1. **Phase 1**: Create collections and indexes
2. **Phase 2**: Migrate mock data to Firestore
3. **Phase 3**: Update app to use Firestore
4. **Phase 4**: Add admin dashboard
5. **Phase 5**: Enable real-time features

---

## Admin Dashboard Data Views

### Key Queries for Admin Dashboard

1. **Library Overview**:
   ```javascript
   db.collection('libraries')
     .where('isActive', '==', true)
     .orderBy('city')
     .get()
   ```

2. **Shelf Accuracy**:
   ```javascript
   db.collection('libraries').doc(libraryId)
     .collection('floors').doc(floorId)
     .collection('shelves')
     .where('accuracy', '<', 90)
     .orderBy('accuracy', 'asc')
     .get()
   ```

3. **Recent Scans**:
   ```javascript
   db.collection('scans')
     .where('libraryId', '==', libraryId)
     .orderBy('createdAt', 'desc')
     .limit(50)
     .get()
   ```

4. **Misplaced Books**:
   ```javascript
   db.collection('bookLocations')
     .where('libraryId', '==', libraryId)
     .where('isCorrectOrder', '==', false)
     .get()
   ```

5. **User Activity**:
   ```javascript
   db.collection('scans')
     .where('userId', '==', userId)
     .orderBy('createdAt', 'desc')
     .limit(100)
     .get()
   ```

---

## Notes

- All timestamps use Firestore `Timestamp` type
- Use subcollections for hierarchical data (libraries → floors → shelves)
- Use document IDs for easy lookups (ISBN for books)
- Add indexes before deploying to production
- Consider using Cloud Functions for complex operations
- Use Firestore transactions for critical updates
- Implement caching strategy for frequently accessed data


