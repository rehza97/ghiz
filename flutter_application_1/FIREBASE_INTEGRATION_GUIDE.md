# Firebase Integration Guide

## Quick Start

This guide will help you integrate Firebase into your AR Book Scanner application.

## Step 1: Install Dependencies

Add Firebase dependencies to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Existing dependencies
  mobile_scanner: ^5.2.3
  provider: ^6.1.1
  
  # Firebase dependencies
  firebase_core: ^3.6.0
  cloud_firestore: ^5.4.4
  firebase_auth: ^5.3.1
  firebase_storage: ^12.3.4
  firebase_analytics: ^11.3.3
```

Then run:
```bash
flutter pub get
```

## Step 2: Setup Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing
3. Add Android app:
   - Package name: `com.example.flutter_application_1` (check your `build.gradle`)
   - Download `google-services.json`
   - Place in `android/app/`
4. Add iOS app:
   - Bundle ID: `com.example.flutterApplication1` (check your `Info.plist`)
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/`
5. Enable Firestore Database
6. Enable Authentication (Email/Password)

## Step 3: Initialize Firebase

Create `lib/firebase_options.dart` using FlutterFire CLI:

```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

Or manually create `lib/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not supported yet');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.example.flutterApplication1',
  );
}
```

Update `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/library_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner de Livres AR - Algérie',
      theme: ThemeData(
        primaryColor: const Color(0xFF38ada9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38ada9),
          secondary: const Color(0xFF3c6382),
        ),
        useMaterial3: true,
      ),
      home: const LibrarySelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

## Step 4: Update Services to Use Firebase

Replace `MockData` usage with `FirebaseService`:

### Example: Library Selection Screen

```dart
import '../services/firebase_service.dart';

class _LibrarySelectionScreenState extends State<LibrarySelectionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Library> _libraries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLibraries();
  }

  Future<void> _loadLibraries() async {
    try {
      final libraries = await _firebaseService.getLibraries(
        wilaya: selectedWilaya == 'Tous' ? null : selectedWilaya,
      );
      setState(() {
        _libraries = libraries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error
    }
  }
  
  // ... rest of the code
}
```

### Example: Book Search Screen

```dart
import '../services/firebase_service.dart';

class _BookSearchScreenState extends State<BookSearchScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  
  Future<void> _performSearch() async {
    final query = _searchController.text;
    try {
      List<Book> results;
      if (query.isEmpty && _selectedCategory == 'Tous') {
        // Get all books
        results = await _firebaseService.searchBooks('');
      } else if (_selectedCategory != 'Tous') {
        results = await _firebaseService.getBooksByCategory(_selectedCategory);
      } else {
        results = await _firebaseService.searchBooks(query);
      }
      
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      // Handle error
    }
  }
}
```

## Step 5: Setup Firestore Security Rules

Copy the security rules from `FIREBASE_SCHEMA.md` to Firebase Console:

1. Go to Firestore Database → Rules
2. Paste the rules
3. Publish

## Step 6: Create Firestore Indexes

Firebase will prompt you to create indexes when you run queries. Or create them manually:

1. Go to Firestore Database → Indexes
2. Create composite indexes as listed in `FIREBASE_SCHEMA.md`

## Step 7: Migrate Mock Data to Firestore

Create a migration script or use Firebase Console to import initial data:

### Option 1: Firebase Console (Manual)
1. Go to Firestore Database
2. Create collections manually
3. Add documents

### Option 2: Migration Script (Recommended)

Create `scripts/migrate_to_firebase.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/data/mock_data.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  
  // Migrate libraries
  for (final library in MockData.libraries) {
    await firestore.collection('libraries').doc(library.id).set({
      ...library.toFirestore(),
    });
    
    // Migrate floors
    final floors = MockData.getFloorsByLibrary(library.id);
    for (final floor in floors) {
      await firestore
          .collection('libraries')
          .doc(library.id)
          .collection('floors')
          .doc(floor.id)
          .set(floor.toFirestore());
      
      // Migrate shelves
      final shelves = MockData.getShelvesByFloor(floor.id);
      for (final shelf in shelves) {
        await firestore
            .collection('libraries')
            .doc(library.id)
            .collection('floors')
            .doc(floor.id)
            .collection('shelves')
            .doc(shelf.id)
            .set(shelf.toFirestore());
      }
    }
  }
  
  // Migrate books
  for (final book in MockData.books) {
    await firestore.collection('books').doc(book.isbn).set(book.toFirestore());
  }
  
  // Migrate book locations
  for (final location in MockData.bookLocations) {
    await firestore.collection('bookLocations').add(location.toFirestore());
  }
  
  print('Migration completed!');
}
```

Run migration:
```bash
dart run scripts/migrate_to_firebase.dart
```

## Step 8: Update AR Detection Screen

Update `ar_book_detection_screen.dart` to save scans:

```dart
import '../services/firebase_service.dart';

class _ARBookDetectionScreenState extends State<ARBookDetectionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  
  Future<void> _saveScan() async {
    try {
      final scannedBooks = _detectedBarcodes.map((isbn) {
        final book = MockData.getBookByIsbn(isbn);
        final location = MockData.getBookLocation(isbn);
        return {
          'isbn': isbn,
          'title': book?.title ?? '',
          'detectedPosition': _detectedBooksInfo[isbn]?.detectionOrder ?? 0,
          'expectedPosition': location?.expectedPosition ?? 0,
          'isCorrect': location?.isCorrectOrder ?? false,
        };
      }).toList();
      
      await _firebaseService.saveScan(
        libraryId: widget.libraryId,
        shelfId: widget.shelfId,
        floorId: 'floor_002', // Get from context
        scannedBooks: scannedBooks,
      );
    } catch (e) {
      // Handle error
    }
  }
}
```

## Step 9: Add Real-time Updates (Optional)

Use streams for real-time data:

```dart
StreamBuilder<Shelf?>(
  stream: _firebaseService.watchShelf(libraryId, floorId, shelfId),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    final shelf = snapshot.data!;
    // Use shelf data
  },
)
```

## Step 10: Testing

1. Test on Android device/emulator
2. Test on iOS device/simulator
3. Verify data appears in Firestore Console
4. Test real-time updates
5. Test offline mode (Firestore supports offline persistence)

## Troubleshooting

### Issue: "MissingPluginException"
- Solution: Run `flutter clean` and `flutter pub get`
- Rebuild the app

### Issue: "PlatformException"
- Solution: Check Firebase configuration files are in correct locations
- Verify package names match

### Issue: "Permission denied"
- Solution: Check Firestore security rules
- Verify user is authenticated (if required)

### Issue: "Index not found"
- Solution: Create the required indexes in Firestore Console
- Wait for indexes to build (can take a few minutes)

## Next Steps

1. Implement authentication
2. Add user management
3. Create admin dashboard
4. Add analytics
5. Implement offline support
6. Add push notifications

## Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firebase Console](https://console.firebase.google.com/)


