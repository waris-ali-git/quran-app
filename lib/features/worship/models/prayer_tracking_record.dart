class PrayerTrackingRecord {
  static const List<String> prayerKeys = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  final String dateKey;
  final Set<String> completedPrayers;
  final DateTime updatedAt;

  const PrayerTrackingRecord({
    required this.dateKey,
    required this.completedPrayers,
    required this.updatedAt,
  });

  factory PrayerTrackingRecord.empty(String dateKey) {
    return PrayerTrackingRecord(
      dateKey: dateKey,
      completedPrayers: <String>{},
      updatedAt: DateTime.now(),
    );
  }

  factory PrayerTrackingRecord.fromJson(Map<String, dynamic> json) {
    final completed = (json['completedPrayers'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .where(prayerKeys.contains)
        .toSet();

    return PrayerTrackingRecord(
      dateKey: json['dateKey']?.toString() ?? '',
      completedPrayers: completed,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  int get completionCount => completedPrayers.length;

  double get completionRatio => completionCount / prayerKeys.length;

  bool get isComplete => completionCount == prayerKeys.length;

  bool isCompleted(String prayerKey) {
    return completedPrayers.contains(canonicalPrayerKey(prayerKey));
  }

  PrayerTrackingRecord copyWith({
    String? dateKey,
    Set<String>? completedPrayers,
    DateTime? updatedAt,
  }) {
    return PrayerTrackingRecord(
      dateKey: dateKey ?? this.dateKey,
      completedPrayers: completedPrayers ?? this.completedPrayers,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'completedPrayers': completedPrayers.toList()..sort(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static String canonicalPrayerKey(String prayerKey) {
    switch (prayerKey.trim().toLowerCase()) {
      case 'jumma':
      case 'jumuah':
      case "jumu'ah":
      case 'zuhr':
      case 'zuhar':
        return 'Dhuhr';
      default:
        for (final key in prayerKeys) {
          if (key.toLowerCase() == prayerKey.trim().toLowerCase()) {
            return key;
          }
        }
        return prayerKey;
    }
  }
}
