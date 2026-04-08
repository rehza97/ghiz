import 'package:sqflite/sqflite.dart';

import 'local_database_service.dart';

class AppSettingsService {
  Future<Database> get _db async => LocalDatabaseService.instance.database;

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final db = await _db;
    final rows = await db.query(
      'app_settings',
      where: 'settingKey = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return defaultValue;
    return (rows.first['settingValue']?.toString() ?? '0') == '1';
  }

  Future<void> setBool(String key, bool value) async {
    final db = await _db;
    await db.insert('app_settings', {
      'settingKey': key,
      'settingValue': value ? '1' : '0',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
