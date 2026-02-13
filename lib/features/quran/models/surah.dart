import 'package:equatable/equatable.dart';
import 'ayah.dart';

class Surah extends Equatable {
  final int number;
  final String name;          // Arabic name
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType; // 'Meccan' | 'Medinan'
  final List<Ayah>? ayahs;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
    this.ayahs,
  });

  // ── AlQuran.cloud format ─────────────────────
  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      englishNameTranslation: json['englishNameTranslation'] as String,
      numberOfAyahs: json['numberOfAyahs'] as int,
      revelationType: json['revelationType'] as String,
      ayahs: json['ayahs'] != null
          ? (json['ayahs'] as List)
          .map((e) => Ayah.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
          : null,
    );
  }

  // ── Quran.com v4 chapter format ──────────────
  factory Surah.fromQuranComJson(Map<String, dynamic> json) {
    final nameAr = json['name_arabic'] as String? ?? '';
    final nameSimple = json['name_simple'] as String? ?? '';
    final nameMeaning = json['translated_name'] is Map
        ? (json['translated_name'] as Map)['name'] as String? ?? ''
        : '';
    return Surah(
      number: json['id'] as int,
      name: nameAr,
      englishName: nameSimple,
      englishNameTranslation: nameMeaning,
      numberOfAyahs: json['verses_count'] as int,
      revelationType: json['revelation_place'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'name': name,
    'englishName': englishName,
    'englishNameTranslation': englishNameTranslation,
    'numberOfAyahs': numberOfAyahs,
    'revelationType': revelationType,
    'ayahs': ayahs?.map((a) => a.toJson()).toList(),
  };

  Surah copyWith({List<Ayah>? ayahs}) => Surah(
    number: number,
    name: name,
    englishName: englishName,
    englishNameTranslation: englishNameTranslation,
    numberOfAyahs: numberOfAyahs,
    revelationType: revelationType,
    ayahs: ayahs ?? this.ayahs,
  );

  @override
  List<Object?> get props => [
    number, name, englishName, englishNameTranslation,
    numberOfAyahs, revelationType, ayahs,
  ];
}