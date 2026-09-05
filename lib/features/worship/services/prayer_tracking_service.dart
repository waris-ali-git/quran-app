import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_tracking_record.dart';

class PrayerTrackingService {
  static const String _storageKey = 'prayer_tracking_records_v1';

  Future<PrayerTrackingRecord> getTodayRecord() {
    return getRecordForDate(DateTime.now());
  }

  Future<PrayerTrackingRecord> getRecordForDate(DateTime date) async {
    final records = await _readRecords();
    final key = dateKey(date);
    return records[key] ?? PrayerTrackingRecord.empty(key);
  }

  Future<Map<String, PrayerTrackingRecord>> getRecordsForMonth(
    DateTime month,
  ) async {
    final records = await _readRecords();
    final firstDay = DateTime(month.year, month.month);
    final nextMonth = DateTime(month.year, month.month + 1);
    final visibleRecords = <String, PrayerTrackingRecord>{};

    for (final entry in records.entries) {
      final date = parseDateKey(entry.key);
      if (date == null) continue;
      if (!date.isBefore(firstDay) && date.isBefore(nextMonth)) {
        visibleRecords[entry.key] = entry.value;
      }
    }

    return visibleRecords;
  }

  Future<PrayerTrackingRecord> togglePrayer(
    String prayerKey, {
    DateTime? date,
  }) async {
    final records = await _readRecords();
    final targetDate = date ?? DateTime.now();
    final key = dateKey(targetDate);
    final current = records[key] ?? PrayerTrackingRecord.empty(key);
    final canonicalKey = PrayerTrackingRecord.canonicalPrayerKey(prayerKey);
    final completed = Set<String>.from(current.completedPrayers);

    if (completed.contains(canonicalKey)) {
      completed.remove(canonicalKey);
    } else if (PrayerTrackingRecord.prayerKeys.contains(canonicalKey)) {
      completed.add(canonicalKey);
    }

    final updated = current.copyWith(
      completedPrayers: completed,
      updatedAt: DateTime.now(),
    );
    records[key] = updated;
    await _writeRecords(records);
    return updated;
  }

  Future<Map<String, PrayerTrackingRecord>> _readRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) {
        final json = Map<String, dynamic>.from(value as Map);
        return MapEntry(key, PrayerTrackingRecord.fromJson(json));
      });
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeRecords(
    Map<String, PrayerTrackingRecord> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = records.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  static String dateKey(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  static DateTime? parseDateKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }
}
