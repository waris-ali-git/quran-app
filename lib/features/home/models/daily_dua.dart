class DailyDua {
  final String id;
  final String arabic;
  final String translation;
  final String? translationUrdu;
  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final String? occasionTag;
  final int? hijriMonth;
  final int? hijriDay;

  const DailyDua({
    required this.id,
    required this.arabic,
    required this.translation,
    this.translationUrdu,
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    this.occasionTag,
    this.hijriMonth,
    this.hijriDay,
  });

  factory DailyDua.fromJson(Map<String, dynamic> json) {
    return DailyDua(
      id: json['id'] as String? ?? 'dua_0',
      arabic: json['arabic'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      translationUrdu: json['translationUrdu'] as String?,
      surahName: json['surahName'] as String? ?? '',
      surahNumber: json['surahNumber'] as int? ?? 1,
      ayahNumber: json['ayahNumber'] as int? ?? 1,
      occasionTag: json['occasionTag'] as String?,
      hijriMonth: json['hijriMonth'] as int?,
      hijriDay: json['hijriDay'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arabic': arabic,
      'translation': translation,
      'translationUrdu': translationUrdu,
      'surahName': surahName,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'occasionTag': occasionTag,
      'hijriMonth': hijriMonth,
      'hijriDay': hijriDay,
    };
  }

  /// Default fallback Dua (Rabbi Zidni 'Ilma)
  static const fallback = DailyDua(
    id: 'fallback_1',
    arabic: 'رَبِّ زِدْنِي عِلْمًا',
    translation: 'O my Lord, increase me in knowledge',
    translationUrdu: 'اے میرے رب! میرے علم میں اضافہ فرما',
    surahName: 'Taha',
    surahNumber: 20,
    ayahNumber: 114,
  );
}
