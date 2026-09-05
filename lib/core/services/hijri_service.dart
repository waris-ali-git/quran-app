import 'package:shared_preferences/shared_preferences.dart';

/// Representation of a Hijri (Islamic) Date
class HijriDate {
  final int day;
  final int month;
  final String monthNameEn;
  final String monthNameAr;
  final int year;

  const HijriDate({
    required this.day,
    required this.month,
    required this.monthNameEn,
    required this.monthNameAr,
    required this.year,
  });

  static const List<String> monthsEn = [
    'Muharram',
    'Safar',
    'Rabi\' al-Awwal',
    'Rabi\' al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi\'dah',
    'Dhu al-Hijjah',
  ];

  static const List<String> monthsAr = [
    'محَرَّم',
    'صَفَر',
    'رَبِيع الأَوَّل',
    'رَبِيع الآخِر',
    'جُمَادَى الأُولَى',
    'جُمَادَى الآخِرَة',
    'رَجَب',
    'شَعْبَان',
    'رَمَضَان',
    'شَوَّال',
    'ذُو القَعْدَة',
    'ذُو الحِجَّة',
  ];

  String get formattedEn => '$day $monthNameEn $year AH';
  String get formattedAr => '$day $monthNameAr $year هـ';

  @override
  String toString() => formattedEn;
}

/// Service to handle Hijri date conversion and user preference offsets
class HijriService {
  static const String _offsetKey = 'user_hijri_date_offset';

  /// Convert a Gregorian DateTime to Hijri Date with an optional day offset
  static HijriDate convertToHijri(DateTime date, {int dayOffset = 0}) {
    // Apply user manual offset (for regional moon sighting adjustment)
    final adjustedDate = date.add(Duration(days: dayOffset));

    int day = adjustedDate.day;
    int month = adjustedDate.month;
    int year = adjustedDate.year;

    int m = month;
    int y = year;
    if (m < 3) {
      y -= 1;
      m += 12;
    }

    double a = (y / 100).floorToDouble();
    double b = 2 - a + (a / 4).floorToDouble();

    int jd = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b.toInt() -
        1524;

    double z = jd - 1948440 + 1.0625;
    int hy = ((z - 1) / 10631).floor();
    z -= hy * 10631;

    int hm = ((z - 0.5) / 29.5001).floor();
    z -= (hm * 29.5001).round();

    int hd = z.toInt();
    hm += 1;
    hy += 1;

    // Handle edge cases for month bounds
    if (hm > 12) {
      hm -= 12;
      hy += 1;
    }
    if (hd < 1) {
      hd = 1;
    }

    final mIdx = (hm - 1).clamp(0, 11);

    return HijriDate(
      day: hd,
      month: hm,
      monthNameEn: HijriDate.monthsEn[mIdx],
      monthNameAr: HijriDate.monthsAr[mIdx],
      year: hy,
    );
  }

  /// Get current user offset setting (-2 to +2 days)
  static Future<int> getSavedOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_offsetKey) ?? 0;
  }

  /// Save user offset setting
  static Future<void> setSavedOffset(int offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_offsetKey, offset);
  }

  /// Get today's Hijri Date considering saved offset
  static Future<HijriDate> getTodayHijriDate() async {
    final offset = await getSavedOffset();
    return convertToHijri(DateTime.now(), dayOffset: offset);
  }
}
