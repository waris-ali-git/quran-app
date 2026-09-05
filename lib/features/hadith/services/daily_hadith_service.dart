import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_hadith.dart';

class DailyHadithService {
  static List<DailyHadith>? _cachedHadiths;
  static const String _keyLastPopupDate = 'last_daily_hadith_popup_date';

  /// Load Hadiths from asset JSON
  static Future<List<DailyHadith>> _loadHadiths() async {
    if (_cachedHadiths != null && _cachedHadiths!.isNotEmpty) {
      return _cachedHadiths!;
    }
    try {
      final String jsonString =
          await rootBundle.loadString('lib/assets/data/daily_hadith.json');
      final List<dynamic> list = json.decode(jsonString);
      _cachedHadiths = list.map((item) => DailyHadith.fromJson(item)).toList();
      return _cachedHadiths!;
    } catch (e) {
      debugPrint('Error loading daily_hadith.json: $e');
      return [DailyHadith.fallback];
    }
  }

  /// Get Hadith for Today (deterministic based on current date)
  static Future<DailyHadith> getTodayHadith() async {
    final hadiths = await _loadHadiths();
    if (hadiths.isEmpty) return DailyHadith.fallback;

    final now = DateTime.now();
    // Create a unique daily index based on year, month, and day
    final dayIndex = (now.year * 366 + now.month * 31 + now.day) % hadiths.length;
    return hadiths[dayIndex.abs()];
  }

  /// Format date string YYYY-MM-DD
  static String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check whether the daily Hadith pop-up should be displayed today
  static Future<bool> shouldShowPopUpToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getString(_keyLastPopupDate);
      final todayStr = _getTodayDateString();
      return lastShown != todayStr;
    } catch (e) {
      debugPrint('Error checking daily Hadith pop-up status: $e');
      return false;
    }
  }

  /// Mark that the pop-up has been displayed today
  static Future<void> markPopUpShownToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = _getTodayDateString();
      await prefs.setString(_keyLastPopupDate, todayStr);
    } catch (e) {
      debugPrint('Error marking daily Hadith pop-up shown: $e');
    }
  }
}
