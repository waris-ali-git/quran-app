class TranslationEdition {
  final String identifier;
  final String language;
  final String name;
  final String englishName;
  final String format;
  final String direction;

  const TranslationEdition({
    required this.identifier,
    required this.language,
    required this.name,
    required this.englishName,
    required this.format,
    required this.direction,
  });

  factory TranslationEdition.fromJson(Map<String, dynamic> json) {
    return TranslationEdition(
      identifier: json['identifier'] as String,
      language: json['language'] as String,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      format: json['format'] as String,
      direction: json['direction'] as String? ?? 'ltr',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'language': language,
      'name': name,
      'englishName': englishName,
      'format': format,
      'direction': direction,
    };
  }
}
