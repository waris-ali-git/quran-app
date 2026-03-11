class HadithEdition {
  final String name;      // The identifier, e.g., 'ara-bukhari'
  final String bookId;    // The parent book id, e.g., 'bukhari'
  final String language;  // e.g., 'Arabic', 'English'
  final String direction; // 'rtl' or 'ltr'
  final bool hasSections;

  const HadithEdition({
    required this.name,
    required this.bookId,
    required this.language,
    required this.direction,
    required this.hasSections,
  });

  factory HadithEdition.fromJson(Map<String, dynamic> json) {
    return HadithEdition(
      name: json['name'] as String,
      bookId: json['book'] as String,
      language: json['language'] as String,
      direction: json['direction'] as String? ?? 'ltr',
      hasSections: json['has_sections'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'book': bookId,
      'language': language,
      'direction': direction,
      'has_sections': hasSections,
    };
  }
}

class HadithBook {
  final String id;
  final String name;
  final List<HadithEdition> editions;

  const HadithBook({
    required this.id,
    required this.name,
    required this.editions,
  });

  factory HadithBook.fromJson(String id, Map<String, dynamic> json) {
    final collection = json['collection'] as List;
    final List<HadithEdition> editions = collection
        .map((e) => HadithEdition.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return HadithBook(
      id: id,
      name: json['name'] as String,
      editions: editions,
    );
  }
}

class HadithSection {
  final String id;
  final String name;
  final int firstHadith;
  final int lastHadith;

  const HadithSection({
    required this.id,
    required this.name,
    required this.firstHadith,
    required this.lastHadith,
  });
}

class HadithGrade {
  final String name;
  final String grade;

  const HadithGrade({required this.name, required this.grade});

  factory HadithGrade.fromJson(Map<String, dynamic> json) {
    return HadithGrade(
      name: json['name'] as String,
      grade: json['grade'] as String,
    );
  }
}

class HadithItem {
  final dynamic hadithNumber;
  final dynamic arabicNumber;
  final String text;
  final List<HadithGrade> grades;

  const HadithItem({
    required this.hadithNumber,
    required this.arabicNumber,
    required this.text,
    required this.grades,
  });

  factory HadithItem.fromJson(Map<String, dynamic> json) {
    final gradesList = (json['grades'] as List?) ?? [];
    final textRaw = (json['body'] ?? json['text'] ?? '').toString();
    return HadithItem(
      hadithNumber: json['hadithnumber'],
      arabicNumber: json['arabicnumber'],
      text: textRaw,
      grades: gradesList
          .map((e) => HadithGrade.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// Holds one hadith's text across multiple translations/languages.
class MultiTranslationHadith {
  final dynamic hadithNumber;
  final dynamic arabicNumber;
  final List<HadithGrade> grades;
  /// Map of language label → translated text
  final Map<String, String> translations;

  const MultiTranslationHadith({
    required this.hadithNumber,
    required this.arabicNumber,
    required this.grades,
    required this.translations,
  });
}

