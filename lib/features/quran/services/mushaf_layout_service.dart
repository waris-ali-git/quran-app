import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class MushafLayoutService {
  Database? _db;
  bool _initFailed = false;

  Future<void> init() async {
    if (_db != null) return;

    try {
      // Get the database directory (more reliable than documents dir for DBs)
      final String dbDir = await getDatabasesPath();
      final String dbPath = join(dbDir, "quran_layout.db");

      final dbFile = File(dbPath);

      // Copy from asset if it doesn't exist or if previous init failed
      if (!await dbFile.exists() || _initFailed) {
        debugPrint('MushafLayoutService: Copying DB from assets to $dbPath');
        try {
          // Make sure parent directory exists
          await dbFile.parent.create(recursive: true);

          ByteData data = await rootBundle.load("lib/assets/data/qpc-v1-15-lines.db");
          List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          await dbFile.writeAsBytes(bytes, flush: true);
          debugPrint('MushafLayoutService: DB copied successfully, ${bytes.length} bytes');
        } catch (e) {
          debugPrint('MushafLayoutService: Failed to copy DB from assets: $e');
          rethrow;
        }
      }

      // Open the database
      _db = await openDatabase(dbPath, readOnly: true);
      _initFailed = false;

      // Quick sanity check - verify tables exist
      final tables = await _db!.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('pages', 'words')");
      debugPrint('MushafLayoutService: DB opened. Found tables: ${tables.map((t) => t['name']).toList()}');

      if (tables.length < 2) {
        debugPrint('MushafLayoutService: Missing required tables! Trying re-copy...');
        await _db!.close();
        _db = null;
        _initFailed = true;
        // Delete corrupted file and retry once
        await dbFile.delete();
        return init();
      }
    } catch (e, stack) {
      _initFailed = true;
      debugPrint('MushafLayoutService: init() failed: $e\n$stack');
      rethrow;
    }
  }

  /// Get all lines for a given surah number from the `pages` table
  /// with the words already concatenated using a JOIN.
  Future<List<Map<String, dynamic>>> getSurahLayoutWithWords(int surahNumber) async {
    if (_db == null) await init();

    try {
      // Use a LEFT JOIN because non-ayah lines (like surah_name, basmallah) won't have words
      final String query = '''
        SELECT 
          p.page_number, p.line_number, p.line_type, p.is_centered, 
          p.first_word_id, p.last_word_id, p.surah_number,
          GROUP_CONCAT(w.text, ' ') as line_text
        FROM pages p
        LEFT JOIN words w 
          ON w.word_index >= p.first_word_id AND w.word_index <= p.last_word_id
        WHERE p.surah_number = ?
        GROUP BY p.page_number, p.line_number
        ORDER BY p.page_number ASC, p.line_number ASC
      ''';

      final lines = await _db!.rawQuery(query, [surahNumber]);
      debugPrint('MushafLayoutService: Surah $surahNumber returned ${lines.length} lines');
      return lines;
    } catch (e, stack) {
      debugPrint('MushafLayoutService: Query failed for surah $surahNumber: $e\n$stack');

      // If query fails, try reinitializing the DB
      _db = null;
      _initFailed = true;
      await init();

      // Retry once
      final String query = '''
        SELECT 
          p.page_number, p.line_number, p.line_type, p.is_centered, 
          p.first_word_id, p.last_word_id, p.surah_number,
          GROUP_CONCAT(w.text, ' ') as line_text
        FROM pages p
        LEFT JOIN words w 
          ON w.word_index >= p.first_word_id AND w.word_index <= p.last_word_id
        WHERE p.surah_number = ?
        GROUP BY p.page_number, p.line_number
        ORDER BY p.page_number ASC, p.line_number ASC
      ''';
      return await _db!.rawQuery(query, [surahNumber]);
    }
  }

  // Pre-fetch a batch of pages if needed
  Future<List<Map<String, dynamic>>> getPageLines(int pageNumber) async {
    if (_db == null) await init();

    final lines = await _db!.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );

    return lines;
  }
}
