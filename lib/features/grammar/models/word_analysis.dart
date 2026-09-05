class WordEntry {
  final String arabic;
  final String transliteration;
  final String meaning;
  final String root;
  final String type;
  final String irab; // 'Raf\'', 'Nasb', 'Jarr', 'Jazm'
  final String grammarNote;

  WordEntry({
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    required this.root,
    required this.type,
    required this.irab,
    required this.grammarNote,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      meaning: json['meaning'] as String,
      root: json['root'] as String,
      type: json['type'] as String,
      irab: json['irab'] as String,
      grammarNote: json['grammar_note'] as String,
    );
  }
}

class AyahAnalysis {
  final int ayah;
  final String arabicFull;
  final List<WordEntry> words;

  AyahAnalysis({
    required this.ayah,
    required this.arabicFull,
    required this.words,
  });

  factory AyahAnalysis.fromJson(Map<String, dynamic> json) {
    return AyahAnalysis(
      ayah: json['ayah'] as int,
      arabicFull: json['arabic_full'] as String,
      words: (json['words'] as List)
          .map((w) => WordEntry.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SurahAnalysis {
  final int surah;
  final String surahName;
  final List<AyahAnalysis> ayahs;

  SurahAnalysis({
    required this.surah,
    required this.surahName,
    required this.ayahs,
  });

  factory SurahAnalysis.fromJson(Map<String, dynamic> json) {
    return SurahAnalysis(
      surah: json['surah'] as int,
      surahName: json['surah_name'] as String,
      ayahs: (json['ayahs'] as List)
          .map((a) => AyahAnalysis.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
