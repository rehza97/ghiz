import 'package:sqflite/sqflite.dart';

import 'local_database_service.dart';

class LibrarianProfile {
  const LibrarianProfile({
    required this.fullName,
    required this.email,
    required this.libraryName,
    this.phone,
  });

  final String fullName;
  final String email;
  final String libraryName;
  final String? phone;
}

class LocalLibrarianProfileService {
  Future<Database> get _db async => LocalDatabaseService.instance.database;

  Future<bool> hasCompletedOnboarding() async {
    return (await getProfile()) != null;
  }

  Future<void> saveProfile(LibrarianProfile profile) async {
    final db = await _db;
    await db.insert('librarian_profile', {
      'id': 1,
      'fullName': profile.fullName,
      'email': profile.email,
      'libraryName': profile.libraryName,
      'phone': profile.phone,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<LibrarianProfile?> getProfile() async {
    final db = await _db;
    final rows = await db.query('librarian_profile', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return LibrarianProfile(
      fullName: (row['fullName'] ?? '').toString(),
      email: (row['email'] ?? '').toString(),
      libraryName: (row['libraryName'] ?? '').toString(),
      phone: row['phone']?.toString(),
    );
  }
}
