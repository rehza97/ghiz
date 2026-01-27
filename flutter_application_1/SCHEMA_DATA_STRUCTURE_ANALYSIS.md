# Complete Schema & Data Structure Analysis

## Overview
This document provides a comprehensive analysis of all data structures, models, and Firestore schema in the Flutter AR Book Scanner application.

---

## 📊 Firestore Collection Structure

### Hierarchical Structure
```
firestore/
├── libraries/                              # Main libraries collection
│   └── {libraryId}/
│       ├── floors/                         # Subcollection: Floors
│       │   └── {floorId}/
│       │       ├── shelves/                # Subcollection: Shelves
│       │       │   └── {shelfId}/
│       │       │       └── books/          # Subcollection: Books on shelf
│       │       │           └── {bookIsbn}
│       │       └── beacons/                # Subcollection: IPS Beacons (Schema only)
│       │           └── {beaconId}
│       └── settings/                       # Library-specific settings (Schema only)
│           └── {settingId}
├── books/                                  # Global books catalog (ISBN as document ID)
│   └── {isbn}
├── bookLocations/                          # Book location tracking
│   └── {auto-generated-id}
├── scans/                                  # Scan history
│   └── {auto-generated-id}
├── corrections/                            # Correction sessions
│   └── {auto-generated-id}
├── users/                                  # User accounts (Schema only)
│   └── {userId}
├── admins/                                 # Admin accounts (Schema only)
│   └── {adminId}
├── analytics/                              # Analytics data (Schema only)
│   └── {date}
└── system/                                 # System configuration (Schema only)
    └── {document}
```

---

## 📦 Model Classes Analysis

### 1. Library Model (`lib/models/library.dart`)

**Firestore Collection**: `libraries/{libraryId}`

**Fields**:
```dart
{
  id: String,                    // Same as document ID
  name: String,                  // "Bibliothèque Nationale d'Algérie"
  address: String,               // "1 Rue Docteur Saâdane"
  postalCode: String,            // "16000"
  city: String,                  // "Alger"
  phone: String?,               // Optional
  email: String?,                // Optional
  floorCount: int,               // 4
  latitude: double,              // 36.7538
  longitude: double,             // 3.0588
  logoUrl: String?,              // Optional
  hours: String?,                // Optional
  description: String?,          // Optional
}
```

**Firestore Mapping**:
- ✅ `wilaya` - Added in `toFirestore()` (uses city value)
- ✅ `isActive` - Defaults to `true`
- ✅ `createdAt` - Timestamp
- ✅ `updatedAt` - Timestamp
- ⚠️ `createdBy` - Missing (schema defines it but model doesn't have it)
- ⚠️ `stats` - Missing (schema defines it but model doesn't have it)

**Indexes Required**:
- `city` (ascending)
- `wilaya` (ascending)
- `isActive` (ascending)

---

### 2. Floor Model (`lib/models/floor.dart`)

**Firestore Collection**: `libraries/{libraryId}/floors/{floorId}`

**Fields**:
```dart
{
  id: String,                    // Same as document ID
  name: String,                  // "Rez-de-chaussée"
  floorNumber: int,              // 0 (RDC), 1, 2, etc.
  libraryId: String,             // Parent library ID
  mapAssetPath: String?,         // Optional - Path to floor map image
  description: String?,          // Optional
  shelfCount: int,               // Number of shelves
  mapWidth: double?,             // Optional - Map width in pixels
  mapHeight: double?,            // Optional - Map height in pixels
}
```

**Firestore Mapping**:
- ✅ `mapUrl` - Added in `toFirestore()` (uses mapAssetPath value)
- ✅ `isActive` - Defaults to `true`
- ✅ `createdAt` - Timestamp
- ✅ `updatedAt` - Timestamp

**Indexes Required**:
- `libraryId` + `floorNumber` (composite)

---

### 3. Shelf Model (`lib/models/shelf.dart`)

**Firestore Collection**: `libraries/{libraryId}/floors/{floorId}/shelves/{shelfId}`

**Fields**:
```dart
{
  id: String,                    // Same as document ID
  name: String,                  // "A-1-1" or "B-2-1"
  floorId: String,               // Parent floor ID
  libraryId: String,             // Parent library ID
  x: double,                     // Position X (meters)
  y: double,                     // Position Y (meters)
  z: double,                     // Position Z (height)
  width: double,                 // Width (meters)
  height: double,                // Height (meters)
  depth: double,                 // Depth (meters)
  category: String?,             // Optional - "Fiction", "Science", etc.
  capacity: int,                 // Max books capacity
  currentCount: int,             // Current number of books
  description: String?,          // Optional
}
```

**Firestore Mapping**:
- ✅ `isActive` - Defaults to `true`
- ✅ `accuracy` - Calculated in `toFirestore()`: `((capacity - (capacity - currentCount)) / capacity * 100)`
- ✅ `createdAt` - Timestamp
- ✅ `updatedAt` - Timestamp
- ⚠️ `lastCorrectionDate` - Missing (schema defines it but model doesn't have it)

**Computed Properties** (not stored in Firestore):
- `occupancyRate` - `currentCount / capacity`
- `isFull` - `currentCount >= capacity`
- `availableSpace` - `capacity - currentCount`

**Indexes Required**:
- `floorId` + `category` (composite)
- `libraryId` + `isActive` (composite)

---

### 4. Book Model (`lib/models/book.dart`)

**Firestore Collection**: `books/{isbn}`

**Fields**:
```dart
{
  isbn: String,                  // ISBN/Code-barres (document ID)
  title: String,                 // "Le Seigneur des Anneaux"
  author: String,                // "J.R.R. Tolkien"
  category: String,              // "Fantasy"
  coverUrl: String?,             // Optional - Book cover image URL
  description: String?,          // Optional
  scannedAt: DateTime?,          // ⚠️ Not stored in Firestore (local only)
  order: int?,                   // ⚠️ Not stored in Firestore (local only)
}
```

**Firestore Mapping**:
- ✅ `language` - Defaults to `'fr'` in `toFirestore()`
- ✅ `isActive` - Defaults to `true`
- ✅ `createdAt` - Timestamp
- ✅ `updatedAt` - Timestamp
- ⚠️ `publisher` - Missing (schema defines it)
- ⚠️ `publishDate` - Missing (schema defines it)
- ⚠️ `pageCount` - Missing (schema defines it)
- ⚠️ `addedBy` - Missing (schema defines it)
- ⚠️ `stats` - Missing (schema defines it)

**Indexes Required**:
- `category` (ascending)
- `author` (ascending)
- `isActive` (ascending)
- `title` (full-text search - requires Algolia/Elasticsearch or similar)

---

### 5. BookLocation Model (`lib/models/book_location.dart`)

**Firestore Collection**: `bookLocations` (root collection)

**Fields**:
```dart
{
  bookIsbn: String,              // Reference to books collection
  libraryId: String,             // Reference to libraries
  floorId: String,               // Reference to floor
  shelfId: String,               // Reference to shelf
  position: int,                 // Current position (1-indexed)
  expectedPosition: int,         // Expected position
  isCorrectOrder: bool,          // Is at correct position
  isFlagged: bool,               // Flagged for review (default: false)
  reason: String?,               // Optional - Reason if misplaced
  lastCheckedAt: DateTime?,      // Optional - Last verification date
  misplacementCount: int,        // Number of times misplaced (default: 0)
}
```

**Firestore Mapping**:
- ✅ `createdAt` - Timestamp
- ✅ `updatedAt` - Timestamp

**Computed Properties** (not stored in Firestore):
- `positionDeviation` - `(expectedPosition - position).abs()`
- `movementDirection` - Returns 'correct', 'right', or 'left'

**Indexes Required**:
- `bookIsbn` (ascending)
- `libraryId` + `shelfId` (composite)
- `libraryId` + `isCorrectOrder` (composite)
- `shelfId` + `position` (composite)

---

### 6. ShelfBook Model (`lib/models/shelf_book.dart`)

**Firestore Collection**: N/A (Composite/Derived Model)

**Purpose**: Combines Book + position information for display

**Fields**:
```dart
{
  book: Book,                    // The book itself
  currentPosition: int,          // Current position (1-indexed)
  expectedPosition: int,         // Expected position
  barcode: String,               // ISBN/barcode
  isCorrect: bool,               // Is at correct position
  deviation: int,                // Distance between positions
  movementDirection: String?,    // Optional - Movement direction
}
```

**Computed Properties**:
- `correctionPriority` - Returns 0-5 (0 = most urgent, 5 = correct)
- `statusDescription` - Human-readable status

**Note**: This is a presentation model, not stored directly in Firestore. Created from `Book` + `BookLocation` data.

---

### 7. Shelf Books Subcollection

**Firestore Collection**: `libraries/{libraryId}/floors/{floorId}/shelves/{shelfId}/books/{bookIsbn}`

**Schema Definition** (from FIREBASE_SCHEMA.md):
```typescript
{
  bookIsbn: string,              // ISBN (document ID)
  position: number,              // Current position (1-indexed)
  expectedPosition: number,      // Expected position
  isCorrectOrder: boolean,       // Is at correct position
  isFlagged: boolean,            // Flagged for review
  reason?: string,               // Reason if misplaced
  lastCheckedAt?: timestamp,     // Last verification date
  misplacementCount: number,     // Number of times misplaced
  addedAt: timestamp,            // When added to shelf
  updatedAt: timestamp
}
```

**Status**: ⚠️ Model not implemented in Flutter code - only schema documentation exists

---

### 8. AdminUser Model (`lib/models/admin_user.dart`)

**Firestore Collection**: `admins/{adminId}` (Firebase Auth UID)

**Fields**:
```dart
{
  id: String,                    // Firebase Auth UID
  email: String,
  displayName: String,
  role: AdminRole,               // Enum: superAdmin, admin, librarian
  permissions: AdminPermissions, // Permission object
  assignedLibraries: List<String>, // Array of library IDs
  isActive: bool,                // Default: true
  lastLoginAt: DateTime?,        // Optional
  createdAt: DateTime,
  updatedAt: DateTime,
  createdBy: String?,            // Optional - Admin who created this
}
```

**AdminRole Enum**:
- `superAdmin` → Firestore: `"super_admin"`
- `admin` → Firestore: `"admin"`
- `librarian` → Firestore: `"librarian"`

**AdminPermissions Class**:
```dart
{
  canManageLibraries: bool,
  canManageBooks: bool,
  canManageUsers: bool,
  canViewAnalytics: bool,
  canManageSystem: bool,
}
```

**Firestore Mapping**:
- ✅ All fields mapped correctly
- ✅ Role stored as string (name property)
- ✅ Permissions stored as map

**Methods**:
- `hasPermission(String permission)` - Check specific permission
- `canAccessLibrary(String libraryId)` - Check library access

**Indexes Required**:
- `role` + `isActive` (composite)
- `email` (ascending)

---

### 9. BookMovement Model (`lib/models/book_movement.dart`)

**Firestore Collection**: Part of `corrections` collection (nested in movements array)

**Fields**:
```dart
{
  bookBarcode: String,           // ISBN/barcode
  bookTitle: String,             // Title for display
  fromPosition: int,             // Current position
  toPosition: int,               // Target position
  direction: MovementDirection,  // Enum: left, right, up, down
  distance: int,                 // Distance to move (positions)
  priority: int,                 // 0-5 (0 = most urgent)
  instruction: String,           // Human-readable instruction
  isCompleted: bool,             // Default: false
}
```

**MovementDirection Enum**:
- `left` → Text: "gauche", Symbol: "←"
- `right` → Text: "droite", Symbol: "→"
- `up` → Text: "haut", Symbol: "↑"
- `down` → Text: "bas", Symbol: "↓"

**Computed Properties**:
- `priorityDescription` - "CRITIQUE", "ÉLEVÉE", "MOYENNE", "NORMALE", "FAIBLE"
- `directionText` - French text
- `directionSymbol` - Unicode symbol

**Firestore Storage**: Stored as nested object in `corrections.movements[]` array

---

### 10. BookCorrectionGuide Model (`lib/models/book_correction_guide.dart`)

**Firestore Collection**: N/A (Computed/Temporary Model)

**Purpose**: Guide for correcting shelf book order

**Fields**:
```dart
{
  currentOrder: List<ShelfBook>,     // Current detected order
  expectedOrder: List<ShelfBook>,    // Expected order from database
  requiredMoves: List<BookMovement>, // Required movements
  isInCorrectOrder: bool,            // Is already correct
  totalErrorsFound: int,             // Total errors
  misplacedBooksCount: int,          // Number misplaced
  generatedAt: DateTime,             // Generation timestamp
  shelfId: String?,                  // Optional - Shelf ID
}
```

**Computed Properties**:
- `accuracyPercentage` - Calculated accuracy
- `accuracyDescription` - "Parfait ✓", "Bon (X%)", etc.
- `prioritySortedMoves` - Moves sorted by priority
- `leftMovesCount` - Count of left movements
- `rightMovesCount` - Count of right movements

**Note**: This is a computed/temporary model for UI, not stored in Firestore.

---

### 11. ShelfCorrectionState Model (`lib/models/shelf_correction_state.dart`)

**Firestore Collection**: Related to `corrections` collection (can be derived from it)

**Purpose**: Tracks the state of an ongoing correction process

**Fields**:
```dart
{
  currentBooks: List<ShelfBook>,        // Current books on shelf
  remainingMoves: List<BookMovement>,   // Moves still to do
  movesMade: int,                       // Corrections completed
  progressPercentage: double,           // 0-100
  correctionComplete: bool,             // Is correction done
  lastUpdated: DateTime,                // Last update timestamp
  completedMoves: List<BookMovement>,   // Moves already done (history)
}
```

**Computed Properties**:
- `nextMove` - Next move to perform (by priority)
- `urgentMove` - Most urgent move (priority 0)
- `misplacedBooksCount` - Count of misplaced books
- `correctBooksCount` - Count of correct books
- `statusText` - Human-readable status
- `detailedStatus` - Detailed description

**Methods**:
- `markMoveAsCompleted(String bookBarcode)` - Mark move as done
- `undoLastMove()` - Undo last move
- `reset()` - Reset correction state

**Note**: This can be derived from `corrections` collection data but is primarily used for local state management.

---

### 12. IPSBeacon Model (`lib/models/ips_beacon.dart`)

**Firestore Collection**: Schema defines `libraries/{libraryId}/floors/{floorId}/beacons/{beaconId}` but model exists

**Fields**:
```dart
{
  id: String,                    // Beacon ID
  uuid: String,                  // BLE UUID
  txPower: int,                  // RSSI at 1 meter
  x: double,                     // Position X (meters)
  y: double,                     // Position Y (meters)
  z: double,                     // Position Z (height)
  floorId: String,               // Parent floor ID
  libraryId: String,             // Parent library ID
  coverageRadius: double,        // Coverage radius (meters)
  location: String?,             // Optional - Location description
}
```

**Methods**:
- `estimatedDistance(int measuredRssi)` - Calculate distance from RSSI using Friis propagation model

**Firestore Mapping**: ⚠️ Model has `toJson()` but no `toFirestore()` method - needs implementation

**Status**: Model exists but Firestore integration incomplete

---

### 13. UserPosition Model (`lib/models/user_position.dart`)

**Firestore Collection**: N/A (Local/Real-time Model)

**Purpose**: Represents user's current position (GPS + indoor)

**Fields**:
```dart
{
  gpsCoordinate: LatLng,         // GPS coordinates
  floorId: String,               // Current floor
  indoorX: double,               // Indoor X position (meters)
  indoorY: double,               // Indoor Y position (meters)
  accuracy: double,              // Position accuracy (meters)
  heading: double,               // User direction (0-360 degrees)
  cameraAngle: double?,          // Optional - Camera angle
  lastUpdated: DateTime,         // Last update timestamp
  isReliable: bool,              // Is position reliable
}
```

**Computed Properties**:
- `distanceTo(UserPosition other)` - Calculate distance to another position

**Helper Classes**:
- `LatLng` - Latitude/Longitude coordinates

**Note**: This is a local/real-time model for AR positioning, typically not stored in Firestore (or stored in real-time database if needed).

---

### 14. BookARData Model (`lib/models/book_ar_data.dart`)

**Firestore Collection**: N/A (Computed/Display Model)

**Purpose**: AR overlay data for book display

**Fields**:
```dart
{
  book: Book,                    // The book
  location: BookLocation,        // Book location
  shelf: Shelf,                  // Shelf information
  shelfPosition: ShelfPosition,  // 3D positioning data
  arOverlay: ArOverlay,          // AR overlay content
  isInCorrectOrder: bool,        // Is correct
  currentPosition: int,          // Current position
  expectedPosition: int,         // Expected position
  distanceToUser: double,        // Distance to user (meters)
}
```

**Helper Classes**:

**ShelfPosition**:
```dart
{
  shelfId: String,
  x, y, z: double,               // 3D position
  width, height, depth: double,  // Dimensions
  gpsCoordinate: LatLng,
  distanceToUser: double,
  topLeft, topRight,             // Corner coordinates
  bottomLeft, bottomRight: Vector3,
}
```

**ArOverlay**:
```dart
{
  bookBarcode: String,
  bookTitle: String,
  bookAuthor: String,
  bookCover: String?,
  status: BadgeStatus,           // Enum
  statusMessage: String,
  statusColor: int,              // RGB as int
  shelfBoundary: List<Vector3>,  // 3D boundary
  screenPosition: Map<String, double>?, // Screen position
  badgeSize: Map<String, double>, // Badge dimensions
}
```

**BadgeStatus Enum**:
- `correct` → Color: Green (#4CAF50), Symbol: "✓"
- `wrongPosition` → Color: Yellow/Orange (#FFC107), Symbol: "⚠"
- `wrongShelf` → Color: Red (#F44336), Symbol: "✗"
- `duplicate` → Color: Purple (#9C27B0), Symbol: "⚠⚠"
- `unknown` → Color: Gray (#757575), Symbol: "?"

**Helper Classes**:
- `Vector3` - 3D vector (x, y, z)
- `LatLng` - GPS coordinates

**Note**: This is a computed/presentation model for AR display, not stored in Firestore.

---

## 📋 Collections Summary

### ✅ Fully Implemented Collections

1. **libraries** - ✅ Complete
   - Model: `Library`
   - Service: `FirebaseService.getLibraries()`, `getLibraryById()`, `saveLibrary()`

2. **libraries/{id}/floors** - ✅ Complete
   - Model: `Floor`
   - Service: `FirebaseService.getFloorsByLibrary()`, `getFloorById()`

3. **libraries/{id}/floors/{id}/shelves** - ✅ Complete
   - Model: `Shelf`
   - Service: `FirebaseService.getShelvesByFloor()`, `getShelfById()`

4. **books** - ✅ Complete
   - Model: `Book`
   - Service: `FirebaseService.getBookByIsbn()`, `saveBook()`

5. **bookLocations** - ✅ Complete
   - Model: `BookLocation`
   - Service: `FirebaseService.updateBookPosition()`

6. **scans** - ✅ Complete (Service only)
   - Service: `FirebaseService.saveScan()`
   - ⚠️ No model class (uses Map directly)

7. **corrections** - ✅ Complete (Service only)
   - Service: `FirebaseService.saveCorrection()`, `updateCorrection()`
   - ⚠️ No model class (uses Map directly)
   - Uses `BookMovement` model for movements array

8. **admins** - ✅ Model exists
   - Model: `AdminUser`
   - ⚠️ No service methods implemented

### ⚠️ Schema Defined but Not Implemented

1. **libraries/{id}/floors/{id}/shelves/{id}/books** - Schema only
   - ⚠️ No model or service implementation

2. **libraries/{id}/floors/{id}/beacons** - Schema only
   - Model: `IPSBeacon` exists but no Firestore methods

3. **users** - Schema only
   - ⚠️ No model or service implementation

4. **analytics** - Schema only
   - ⚠️ No model or service implementation

5. **system** - Schema only
   - ⚠️ No model or service implementation

### 📊 Presentation/Computed Models (Not Stored)

1. **ShelfBook** - Composite of Book + BookLocation
2. **BookCorrectionGuide** - Computed correction guide
3. **ShelfCorrectionState** - Local state for corrections
4. **BookARData** - AR display data
5. **UserPosition** - Real-time positioning (not stored)

---

## 🔍 Data Flow & Relationships

### Library Hierarchy
```
Library (1)
  └── Floor (N) - via libraryId
      └── Shelf (N) - via floorId + libraryId
          └── Books (N) - via shelfId (subcollection, not implemented)
```

### Book Tracking
```
Book (1) ←─── BookLocation (N) - via bookIsbn
                └── references: libraryId, floorId, shelfId
```

### Correction Flow
```
Shelf (1)
  └── generates: BookCorrectionGuide (computed)
      └── contains: List<BookMovement>
          └── stored in: corrections collection
              └── tracks: ShelfCorrectionState (local)
```

### AR Flow
```
UserPosition (real-time)
  └── used with: Shelf + BookLocation
      └── generates: BookARData (computed)
          └── displays: ArOverlay
```

---

## ⚠️ Gaps & Missing Implementations

### Model Gaps

1. **Library Model**:
   - ❌ Missing `createdBy` field
   - ❌ Missing `stats` object

2. **Book Model**:
   - ❌ Missing `publisher` field
   - ❌ Missing `publishDate` field
   - ❌ Missing `pageCount` field
   - ❌ Missing `addedBy` field
   - ❌ Missing `stats` object

3. **Shelf Model**:
   - ❌ Missing `lastCorrectionDate` field

### Service Gaps

1. ❌ No CRUD operations for `admins` collection
2. ❌ No CRUD operations for `users` collection
3. ❌ No CRUD operations for `analytics` collection
4. ❌ No CRUD operations for `system` collection
5. ❌ No operations for `beacons` subcollection
6. ❌ No operations for `shelves/{id}/books` subcollection

### Firestore Method Gaps

1. **IPSBeacon**: Has `toJson()` but no `toFirestore()` or `fromFirestore()`
2. **Scans**: No model class, uses Map directly
3. **Corrections**: No model class, uses Map directly

---

## 📝 Recommendations

### High Priority

1. **Implement missing model fields** to match schema:
   - Add `stats` object to Library and Book models
   - Add missing optional fields to Book model
   - Add `lastCorrectionDate` to Shelf model

2. **Create model classes** for:
   - Scan collection
   - Correction collection (beyond just BookMovement)

3. **Implement Firestore methods** for:
   - IPSBeacon model
   - AdminUser CRUD operations

### Medium Priority

1. **Implement subcollections**:
   - `shelves/{id}/books` subcollection
   - `floors/{id}/beacons` subcollection

2. **Create missing collections**:
   - Users model and service
   - Analytics model and service
   - System configuration model and service

### Low Priority

1. **Enhance computed models** with Firestore persistence if needed
2. **Add validation** to model `toFirestore()` methods
3. **Add batch operations** for bulk updates

---

## 🔗 Key Relationships

| Parent | Child | Relationship | Collection Path |
|--------|-------|--------------|-----------------|
| Library | Floor | 1:N | `libraries/{libId}/floors` |
| Floor | Shelf | 1:N | `libraries/{libId}/floors/{floorId}/shelves` |
| Shelf | Book | N:M | `bookLocations` (junction table) |
| Shelf | Book | 1:N | `libraries/{libId}/floors/{floorId}/shelves/{shelfId}/books` (not implemented) |
| Book | BookLocation | 1:N | `bookLocations` |
| User | Scan | 1:N | `scans` (via userId) |
| User | Correction | 1:N | `corrections` (via userId) |
| Shelf | Correction | 1:N | `corrections` (via shelfId) |
| Floor | IPSBeacon | 1:N | `libraries/{libId}/floors/{floorId}/beacons` (not implemented) |

---

## 📊 Statistics

- **Total Models**: 14
- **Firestore Collections**: 8 defined in schema
- **Fully Implemented**: 5 collections
- **Partially Implemented**: 2 collections (scans, corrections - service only)
- **Schema Only**: 3 collections (users, analytics, system)
- **Presentation Models**: 5 (not stored in Firestore)
- **Missing Fields**: ~10 across various models

---

## 🎯 Conclusion

The Flutter application has a well-structured data model foundation with most core functionality implemented. The main gaps are:

1. **Missing optional fields** in some models
2. **Missing subcollection implementations** (shelf books, beacons)
3. **Missing admin/user management** services
4. **Missing analytics and system** collections

The schema documentation is comprehensive and well-designed. The implementation is about 70% complete for core features, with the remaining 30% being administrative and analytics features.

