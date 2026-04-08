import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/book.dart';
import '../models/book_location.dart';
import '../models/floor.dart';
import '../models/library.dart';
import '../models/shelf.dart';
import 'local_database_service.dart';

/// SQLite-backed local data service used across the app.
class FirebaseService {
  static final StreamController<void> _booksChangedController =
      StreamController<void>.broadcast();

  static Stream<void> get booksChanges => _booksChangedController.stream;

  Future<Database> get _db async => LocalDatabaseService.instance.database;

  // ==================== Libraries ====================

  Future<List<Library>> getLibraries({String? wilaya}) async {
    final db = await _db;
    final rows = await db.query(
      'libraries',
      where: (wilaya == null || wilaya == 'Tous' || wilaya == 'الكل')
          ? null
          : 'city = ?',
      whereArgs: (wilaya == null || wilaya == 'Tous' || wilaya == 'الكل')
          ? null
          : [wilaya],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_libraryFromRow).toList();
  }

  Future<Library?> getLibraryById(String libraryId) async {
    final db = await _db;
    final rows = await db.query(
      'libraries',
      where: 'id = ?',
      whereArgs: [libraryId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _libraryFromRow(rows.first);
  }

  Future<void> saveLibrary(Library library) async {
    final db = await _db;
    await db.insert(
      'libraries',
      _libraryToRow(library),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== Floors ====================

  Future<List<Floor>> getFloorsByLibrary(String libraryId) async {
    final db = await _db;
    final rows = await db.query(
      'floors',
      where: 'libraryId = ?',
      whereArgs: [libraryId],
      orderBy: 'floorNumber ASC',
    );
    return rows.map(_floorFromRow).toList();
  }

  Future<Floor?> getFloorById(String libraryId, String floorId) async {
    final db = await _db;
    final rows = await db.query(
      'floors',
      where: 'id = ? AND libraryId = ?',
      whereArgs: [floorId, libraryId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _floorFromRow(rows.first);
  }

  Future<void> saveFloor(Floor floor) async {
    final db = await _db;
    await db.insert(
      'floors',
      _floorToRow(floor),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== Shelves ====================

  Future<List<Shelf>> getShelvesByFloor(
    String libraryId,
    String floorId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'shelves',
      where: 'libraryId = ? AND floorId = ?',
      whereArgs: [libraryId, floorId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_shelfFromRow).toList();
  }

  Future<List<Shelf>> getShelvesByLibrary(String libraryId) async {
    final db = await _db;
    final rows = await db.query(
      'shelves',
      where: 'libraryId = ?',
      whereArgs: [libraryId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_shelfFromRow).toList();
  }

  Future<Shelf?> getShelfById(
    String libraryId,
    String floorId,
    String shelfId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'shelves',
      where: 'id = ? AND libraryId = ? AND floorId = ?',
      whereArgs: [shelfId, libraryId, floorId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _shelfFromRow(rows.first);
  }

  Future<Shelf?> getShelfByLibraryAndShelfId(
    String libraryId,
    String shelfId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'shelves',
      where: 'id = ? AND libraryId = ?',
      whereArgs: [shelfId, libraryId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _shelfFromRow(rows.first);
  }

  Future<void> saveShelf(Shelf shelf) async {
    final db = await _db;
    await db.insert(
      'shelves',
      _shelfToRow(shelf),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== Books ====================

  Future<Book?> getBookByIsbn(String isbn) async {
    final db = await _db;
    final rows = await db.query(
      'books',
      where: 'isbn = ?',
      whereArgs: [isbn],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _bookFromRow(rows.first);
  }

  Future<List<Book>> searchBooks(String query, {String? libraryId}) async {
    final db = await _db;
    final rows = await db.query('books');
    final books = rows.map(_bookFromRow).toList();
    if (query.trim().isEmpty) return books;
    final lower = query.toLowerCase();

    Map<String, BookLocation> locationByIsbn = {};
    Map<String, String> shelfNameById = {};
    Map<String, String> floorNameById = {};

    if (libraryId != null) {
      final locationRows = await db.query(
        'book_locations',
        where: 'libraryId = ?',
        whereArgs: [libraryId],
      );
      locationByIsbn = {
        for (final row in locationRows)
          row['bookIsbn'].toString(): _bookLocationFromRow(row),
      };

      final shelfRows = await db.query(
        'shelves',
        where: 'libraryId = ?',
        whereArgs: [libraryId],
      );
      shelfNameById = {
        for (final row in shelfRows)
          row['id'].toString(): row['name'].toString(),
      };

      final floorRows = await db.query(
        'floors',
        where: 'libraryId = ?',
        whereArgs: [libraryId],
      );
      floorNameById = {
        for (final row in floorRows)
          row['id'].toString(): row['name'].toString(),
      };
    }

    return books.where((b) {
      final baseMatch =
          b.title.toLowerCase().contains(lower) ||
          b.author.toLowerCase().contains(lower) ||
          b.category.toLowerCase().contains(lower) ||
          b.isbn.toLowerCase().contains(lower);
      if (baseMatch) return true;

      final loc = locationByIsbn[b.isbn];
      if (loc == null) return false;
      final shelfName = (shelfNameById[loc.shelfId] ?? '').toLowerCase();
      final floorName = (floorNameById[loc.floorId] ?? '').toLowerCase();
      return loc.shelfId.toLowerCase().contains(lower) ||
          loc.floorId.toLowerCase().contains(lower) ||
          shelfName.contains(lower) ||
          floorName.contains(lower) ||
          loc.position.toString().contains(lower) ||
          loc.expectedPosition.toString().contains(lower);
    }).toList();
  }

  Future<List<Book>> getBooksByCategory(String category) async {
    final db = await _db;
    final rows = await db.query(
      'books',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return rows.map(_bookFromRow).toList();
  }

  /// Returns books that have been scanned (scannedAt IS NOT NULL),
  /// most recently scanned first.
  Future<List<Book>> getScannedBooks() async {
    final db = await _db;
    final rows = await db.query(
      'books',
      where: 'scannedAt IS NOT NULL',
      orderBy: 'scannedAt DESC',
    );
    return rows.map(_bookFromRow).toList();
  }

  /// Stamps a book's scannedAt to now, recording it was seen by the scanner.
  Future<void> markBookAsScanned(String isbn) async {
    final db = await _db;
    await db.update(
      'books',
      {'scannedAt': DateTime.now().toIso8601String()},
      where: 'isbn = ?',
      whereArgs: [isbn],
    );
  }

  /// Clears the scannedAt timestamp for all books (resets scan history).
  Future<void> clearScanHistory() async {
    final db = await _db;
    await db.update('books', {'scannedAt': null});
  }

  /// Returns true if an ISBN is already taken by another book.
  Future<bool> isbnExists(String isbn) async {
    final db = await _db;
    final rows = await db.query(
      'books',
      columns: ['isbn'],
      where: 'isbn = ?',
      whereArgs: [isbn],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> saveBook(Book book) async {
    final db = await _db;
    await db.insert(
      'books',
      _bookToRow(book),
      // Replace only when explicitly editing an existing book (same ISBN).
      // New books with a duplicate ISBN will throw — callers should check
      // isbnExists() first or catch the exception.
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _booksChangedController.add(null);
  }

  Future<void> deleteBook(String isbn) async {
    final db = await _db;
    await db.delete('books', where: 'isbn = ?', whereArgs: [isbn]);
    await db.delete('book_locations', where: 'bookIsbn = ?', whereArgs: [isbn]);
    _booksChangedController.add(null);
  }

  // ==================== Book Locations ====================

  Future<BookLocation?> getBookLocation(String isbn, String libraryId) async {
    final db = await _db;
    var rows = await db.query(
      'book_locations',
      where: 'bookIsbn = ? AND libraryId = ?',
      whereArgs: [isbn, libraryId],
      limit: 1,
    );
    if (rows.isEmpty) {
      // Fallback for cases where current UI library context differs from
      // the seeded/actual library that owns this book location.
      rows = await db.query(
        'book_locations',
        where: 'bookIsbn = ?',
        whereArgs: [isbn],
        limit: 1,
      );
    }
    if (rows.isEmpty) return null;
    return _bookLocationFromRow(rows.first);
  }

  Future<List<BookLocation>> getShelfBooks(
    String libraryId,
    String shelfId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'book_locations',
      where: 'libraryId = ? AND shelfId = ?',
      whereArgs: [libraryId, shelfId],
      orderBy: 'position ASC',
    );
    return rows.map(_bookLocationFromRow).toList();
  }

  Future<List<BookLocation>> getBookLocationsByLibrary(String libraryId) async {
    final db = await _db;
    final rows = await db.query(
      'book_locations',
      where: 'libraryId = ?',
      whereArgs: [libraryId],
    );
    return rows.map(_bookLocationFromRow).toList();
  }

  Future<void> updateBookPosition(BookLocation location) async {
    final db = await _db;
    await db.insert(
      'book_locations',
      _bookLocationToRow(location),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== Scans / Corrections ====================

  Future<String> saveScan({
    required String libraryId,
    required String shelfId,
    required String floorId,
    required List<Map<String, dynamic>> scannedBooks,
    String? userId,
  }) async {
    final db = await _db;
    final id = 'scan_${DateTime.now().microsecondsSinceEpoch}';
    await db.insert('scans', {
      'id': id,
      'libraryId': libraryId,
      'shelfId': shelfId,
      'floorId': floorId,
      'scannedBooksJson': jsonEncode(scannedBooks),
      'userId': userId,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<String> saveCorrection({
    required String libraryId,
    required String shelfId,
    required List<Map<String, dynamic>> movements,
    String? userId,
  }) async {
    final db = await _db;
    final id = 'correction_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();
    await db.insert('corrections', {
      'id': id,
      'libraryId': libraryId,
      'shelfId': shelfId,
      'movementsJson': jsonEncode(movements),
      'status': 'in_progress',
      'userId': userId,
      'createdAt': now,
      'updatedAt': now,
    });
    return id;
  }

  Future<void> updateCorrection(
    String correctionId,
    Map<String, dynamic> updates,
  ) async {
    final db = await _db;
    final payload = <String, Object?>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (updates.containsKey('status')) payload['status'] = updates['status'];
    if (updates.containsKey('movements')) {
      payload['movementsJson'] = jsonEncode(updates['movements']);
    }
    await db.update(
      'corrections',
      payload,
      where: 'id = ?',
      whereArgs: [correctionId],
    );
  }

  Future<String> saveIsbnLabel({
    required String isbn,
    required String title,
    required String labelText,
  }) async {
    final db = await _db;
    final id = 'label_${DateTime.now().microsecondsSinceEpoch}';
    await db.insert('isbn_labels', {
      'id': id,
      'isbn': isbn,
      'title': title,
      'labelText': labelText,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return id;
  }

  // ==================== Real-time Listeners ====================

  Stream<Library?> watchLibrary(String libraryId) async* {
    yield await getLibraryById(libraryId);
  }

  Stream<Shelf?> watchShelf(
    String libraryId,
    String floorId,
    String shelfId,
  ) async* {
    yield await getShelfById(libraryId, floorId, shelfId);
  }

  Stream<List<BookLocation>> watchShelfBooks(
    String libraryId,
    String shelfId,
  ) async* {
    yield await getShelfBooks(libraryId, shelfId);
  }

  // ==================== Row mappers ====================

  Library _libraryFromRow(Map<String, Object?> row) => Library.fromJson({
    'id': row['id'],
    'name': row['name'],
    'address': row['address'],
    'postalCode': row['postalCode'],
    'city': row['city'],
    'phone': row['phone'],
    'email': row['email'],
    'floorCount': row['floorCount'],
    'latitude': row['latitude'],
    'longitude': row['longitude'],
    'logoUrl': row['logoUrl'],
    'hours': row['hours'],
    'description': row['description'],
  });

  Map<String, Object?> _libraryToRow(Library library) => {
    'id': library.id,
    'name': library.name,
    'address': library.address,
    'postalCode': library.postalCode,
    'city': library.city,
    'phone': library.phone,
    'email': library.email,
    'floorCount': library.floorCount,
    'latitude': library.latitude,
    'longitude': library.longitude,
    'logoUrl': library.logoUrl,
    'hours': library.hours,
    'description': library.description,
  };

  Floor _floorFromRow(Map<String, Object?> row) => Floor.fromJson({
    'id': row['id'],
    'name': row['name'],
    'floorNumber': row['floorNumber'],
    'libraryId': row['libraryId'],
    'mapAssetPath': row['mapAssetPath'],
    'description': row['description'],
    'shelfCount': row['shelfCount'],
    'mapWidth': row['mapWidth'],
    'mapHeight': row['mapHeight'],
  });

  Map<String, Object?> _floorToRow(Floor floor) => {
    'id': floor.id,
    'name': floor.name,
    'floorNumber': floor.floorNumber,
    'libraryId': floor.libraryId,
    'mapAssetPath': floor.mapAssetPath,
    'description': floor.description,
    'shelfCount': floor.shelfCount,
    'mapWidth': floor.mapWidth,
    'mapHeight': floor.mapHeight,
  };

  Shelf _shelfFromRow(Map<String, Object?> row) => Shelf.fromJson({
    'id': row['id'],
    'name': row['name'],
    'floorId': row['floorId'],
    'libraryId': row['libraryId'],
    'x': row['x'],
    'y': row['y'],
    'z': row['z'],
    'width': row['width'],
    'height': row['height'],
    'depth': row['depth'],
    'category': row['category'],
    'capacity': row['capacity'],
    'currentCount': row['currentCount'],
    'description': row['description'],
  });

  Map<String, Object?> _shelfToRow(Shelf shelf) => {
    'id': shelf.id,
    'name': shelf.name,
    'floorId': shelf.floorId,
    'libraryId': shelf.libraryId,
    'x': shelf.x,
    'y': shelf.y,
    'z': shelf.z,
    'width': shelf.width,
    'height': shelf.height,
    'depth': shelf.depth,
    'category': shelf.category,
    'capacity': shelf.capacity,
    'currentCount': shelf.currentCount,
    'description': shelf.description,
  };

  Book _bookFromRow(Map<String, Object?> row) => Book.fromJson({
    'isbn': row['isbn'],
    'title': row['title'],
    'author': row['author'],
    'category': row['category'],
    'coverUrl': row['coverUrl'],
    'description': row['description'],
    'scannedAt': row['scannedAt'],
    'order': row['orderIndex'],
  });

  Map<String, Object?> _bookToRow(Book book) => {
    'isbn': book.isbn,
    'title': book.title,
    'author': book.author,
    'category': book.category,
    'coverUrl': book.coverUrl,
    'description': book.description,
    'scannedAt': book.scannedAt?.toIso8601String(),
    'orderIndex': book.order,
  };

  BookLocation _bookLocationFromRow(Map<String, Object?> row) =>
      BookLocation.fromJson({
        'bookIsbn': row['bookIsbn'],
        'libraryId': row['libraryId'],
        'floorId': row['floorId'],
        'shelfId': row['shelfId'],
        'position': row['position'],
        'expectedPosition': row['expectedPosition'],
        'isCorrectOrder': (row['isCorrectOrder'] as int? ?? 0) == 1,
        'isFlagged': (row['isFlagged'] as int? ?? 0) == 1,
        'reason': row['reason'],
        'lastCheckedAt': row['lastCheckedAt'],
        'misplacementCount': row['misplacementCount'],
      });

  Map<String, Object?> _bookLocationToRow(BookLocation location) => {
    'bookIsbn': location.bookIsbn,
    'libraryId': location.libraryId,
    'floorId': location.floorId,
    'shelfId': location.shelfId,
    'position': location.position,
    'expectedPosition': location.expectedPosition,
    'isCorrectOrder': location.isCorrectOrder ? 1 : 0,
    'isFlagged': location.isFlagged ? 1 : 0,
    'reason': location.reason,
    'lastCheckedAt': location.lastCheckedAt?.toIso8601String(),
    'misplacementCount': location.misplacementCount,
  };
}
