import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/hijri_service.dart';
import '../models/daily_dua.dart';

class DailyDuaService {
  static List<DailyDua>? _cachedDuas;

  /// Load Duas from asset JSON
  static Future<List<DailyDua>> _loadDuas() async {
    if (_cachedDuas != null && _cachedDuas!.isNotEmpty) {
      return _cachedDuas!;
    }
    try {
      final String jsonString =
          await rootBundle.loadString('lib/assets/data/daily_duas.json');
      final List<dynamic> list = json.decode(jsonString);
      _cachedDuas = list.map((item) => DailyDua.fromJson(item)).toList();
      return _cachedDuas!;
    } catch (e) {
      debugPrint('Error loading daily_duas.json: $e');
      return [DailyDua.fallback];
    }
  }

  /// Get appropriate Dua for a given HijriDate & DateTime
  static Future<DailyDua> getDuaForDate({
    required HijriDate hijriDate,
    required DateTime gregorianDate,
  }) async {
    final duas = await _loadDuas();
    if (duas.isEmpty) return DailyDua.fallback;

    // 1. Check for Exact Hijri Month & Hijri Day Match (e.g., 1st Ramadan, Arafah 9th Dhul Hijjah)
    for (final dua in duas) {
      if (dua.hijriMonth == hijriDate.month &&
          dua.hijriDay == hijriDate.day) {
        return dua;
      }
    }

    // 2. Check for Ramadan General (Month 9)
    if (hijriDate.month == 9) {
      // Laylatul Qadr check (Odd nights 21, 23, 25, 27, 29)
      if ([21, 23, 25, 27, 29].contains(hijriDate.day)) {
        final qadrDua = duas.firstWhere(
          (d) => d.occasionTag == 'laylatul_qadr',
          orElse: () => DailyDua.fallback,
        );
        if (qadrDua.id != DailyDua.fallback.id) return qadrDua;
      }

      final ramadanDua = duas.firstWhere(
        (d) => d.occasionTag == 'ramadan_general',
        orElse: () => DailyDua.fallback,
      );
      if (ramadanDua.id != DailyDua.fallback.id) return ramadanDua;
    }

    // 3. Check for Friday (Jummah)
    if (gregorianDate.weekday == DateTime.friday) {
      final jummahDua = duas.firstWhere(
        (d) => d.occasionTag == 'jummah',
        orElse: () => DailyDua.fallback,
      );
      if (jummahDua.id != DailyDua.fallback.id) return jummahDua;
    }

    // 4. Fallback to Deterministic Daily Rotation
    // Filter out special occasion tagged duas for general daily rotation
    final generalDuas =
        duas.where((d) => d.occasionTag == null).toList();

    final pool = generalDuas.isNotEmpty ? generalDuas : duas;

    // Unique daily seed index based on Hijri date
    final dayIndex =
        (hijriDate.year * 354 + hijriDate.month * 30 + hijriDate.day) %
            pool.length;

    return pool[dayIndex.abs()];
  }

  /// Get Dua for Today
  static Future<DailyDua> getTodayDua() async {
    final gregorian = DateTime.now();
    final hijri = await HijriService.getTodayHijriDate();
    return getDuaForDate(hijriDate: hijri, gregorianDate: gregorian);
  }
}
