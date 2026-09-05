class RootDerivative {
  final String arabic;
  final String transliteration;
  final String meaning;

  RootDerivative({
    required this.arabic,
    required this.transliteration,
    required this.meaning,
  });

  factory RootDerivative.fromJson(Map<String, dynamic> json) {
    return RootDerivative(
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      meaning: json['meaning'] as String,
    );
  }
}

class RootOccurrence {
  final int surah;
  final int ayah;
  final String arabic;
  final String context;

  RootOccurrence({
    required this.surah,
    required this.ayah,
    required this.arabic,
    required this.context,
  });

  factory RootOccurrence.fromJson(Map<String, dynamic> json) {
    return RootOccurrence(
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      arabic: json['arabic'] as String,
      context: json['context'] as String,
    );
  }
}

class RootWord {
  final String root;
  final String meaning;
  final int frequency;
  final String category;
  final List<RootDerivative> derivatives;
  final List<RootOccurrence> occurrences;

  RootWord({
    required this.root,
    required this.meaning,
    required this.frequency,
    required this.category,
    required this.derivatives,
    required this.occurrences,
  });

  factory RootWord.fromJson(Map<String, dynamic> json) {
    return RootWord(
      root: json['root'] as String,
      meaning: json['meaning'] as String,
      frequency: json['frequency'] as int,
      category: json['category'] as String,
      derivatives: (json['derivatives'] as List)
          .map((d) => RootDerivative.fromJson(d as Map<String, dynamic>))
          .toList(),
      occurrences: (json['occurrences'] as List)
          .map((o) => RootOccurrence.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VocabularyWord {
  final int rank;
  final String arabic;
  final String transliteration;
  final String meaning;
  final String root;
  final String partOfSpeech;
  final int frequency;

  VocabularyWord({
    required this.rank,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    required this.root,
    required this.partOfSpeech,
    required this.frequency,
  });

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      rank: json['rank'] as int,
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      meaning: json['meaning'] as String,
      root: json['root'] as String,
      partOfSpeech: json['partOfSpeech'] as String,
      frequency: json['frequency'] as int,
    );
  }
}
