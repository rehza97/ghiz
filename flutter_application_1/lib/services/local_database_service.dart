import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/mock_data.dart';
import '../models/floor.dart';
import '../models/library.dart';
import '../models/shelf.dart';

class LocalDatabaseService {
  LocalDatabaseService._();
  static final LocalDatabaseService instance = LocalDatabaseService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ghiz_local.db');
    _db = await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedInitialData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createSchema(db);
      },
      onOpen: (db) async {
        // Ensure newly added tables exist even on older DB files that may not
        // trigger onUpgrade in hot-restart sessions.
        await _createSchema(db);
        await _seedInitialData(db);
      },
    );
    return _db!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS libraries(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        postalCode TEXT NOT NULL,
        city TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        floorCount INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        logoUrl TEXT,
        hours TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS floors(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        floorNumber INTEGER NOT NULL,
        libraryId TEXT NOT NULL,
        mapAssetPath TEXT,
        description TEXT,
        shelfCount INTEGER NOT NULL,
        mapWidth REAL,
        mapHeight REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shelves(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        floorId TEXT NOT NULL,
        libraryId TEXT NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL,
        z REAL NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        depth REAL NOT NULL,
        category TEXT,
        capacity INTEGER NOT NULL,
        currentCount INTEGER NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS books(
        isbn TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        category TEXT NOT NULL,
        coverUrl TEXT,
        description TEXT,
        scannedAt TEXT,
        orderIndex INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS book_locations(
        bookIsbn TEXT NOT NULL,
        libraryId TEXT NOT NULL,
        floorId TEXT NOT NULL,
        shelfId TEXT NOT NULL,
        position INTEGER NOT NULL,
        expectedPosition INTEGER NOT NULL,
        isCorrectOrder INTEGER NOT NULL,
        isFlagged INTEGER NOT NULL,
        reason TEXT,
        lastCheckedAt TEXT,
        misplacementCount INTEGER NOT NULL,
        PRIMARY KEY(bookIsbn, libraryId, shelfId)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS librarian_profile(
        id INTEGER PRIMARY KEY CHECK(id = 1),
        fullName TEXT NOT NULL,
        email TEXT NOT NULL,
        libraryName TEXT NOT NULL,
        phone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS scans(
        id TEXT PRIMARY KEY,
        libraryId TEXT NOT NULL,
        shelfId TEXT NOT NULL,
        floorId TEXT NOT NULL,
        scannedBooksJson TEXT NOT NULL,
        userId TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS corrections(
        id TEXT PRIMARY KEY,
        libraryId TEXT NOT NULL,
        shelfId TEXT NOT NULL,
        movementsJson TEXT NOT NULL,
        status TEXT NOT NULL,
        userId TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS isbn_labels(
        id TEXT PRIMARY KEY,
        isbn TEXT NOT NULL,
        title TEXT NOT NULL,
        labelText TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings(
        settingKey TEXT PRIMARY KEY,
        settingValue TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedInitialData(Database db) async {
    final libraryCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM libraries'),
        ) ??
        0;
    if (libraryCount == 0) {
      final batch = db.batch();
      for (final library in MockData.libraries) {
        batch.insert('libraries', _libraryToRow(library));
      }
      for (final floor in MockData.floors) {
        batch.insert('floors', _floorToRow(floor));
      }
      for (final shelf in MockData.shelves) {
        batch.insert('shelves', _shelfToRow(shelf));
      }
      await batch.commit(noResult: true);
    }
  }

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
}
