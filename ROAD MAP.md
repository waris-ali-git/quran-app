## Aj or kal ka kam
- Dependencies
- State Management decide
- API ka kuch kam
- Quran Auth source find
- Audio Recitation



# 🕌 Quran Feature - Complete Implementation Guide

## 📋 Table of Contents
1. [API Setup & Documentation](#api-setup)
2. [Models (Data Structures)](#m987odels)
3. [Services (Business Logic)](#services)
4. [State Management (BLoC)](#bloc)
5. [UI Screens](#screens)
6. [Tajweed Colors Implementation](#tajweed)
7. [Reading Modes](#reading-modes)

---

## 🌐 API Setup & Documentation

### **APIs We'll Use:**

1. **AlQuran.cloud** - Main Quran API
    - Base URL: `https://api.alquran.cloud/v1/`
    - Free, no API key needed
    - Supports multiple translations

2. **Quran.com** - Tajweed & Audio
    - Base URL: `https://api.quran.com/api/v4/`
    - Free, no API key needed
    - Has Tajweed rules data

### **Key Endpoints:**

```dart
// Get all Surahs metadata
GET https://api.alquran.cloud/v1/surah

// Get specific Surah with translation
GET https://api.alquran.cloud/v1/surah/{surahNumber}/{edition}
// Example: https://api.alquran.cloud/v1/surah/1/en.asad

// Get Ayah by Surah and Ayah number
GET https://api.alquran.cloud/v1/ayah/{surahNumber}:{ayahNumber}

// Get multiple editions (Arabic + Translation)
GET https://api.alquran.cloud/v1/surah/{surahNumber}/editions/{editions}
// Example: https://api.alquran.cloud/v1/surah/1/editions/quran-uthmani,en.asad
```

### **Available Editions:**

```dart
// Arabic Texts
'quran-uthmani'       // Uthmani script (standard)
'quran-simple'        // Simple text
'quran-tajweed'       // With Tajweed markers

// English Translations
'en.sahih'            // Sahih International
'en.pickthall'        // Pickthall
'en.asad'             // Muhammad Asad

// Urdu Translations
'ur.jalandhry'        // Fateh Muhammad Jalandhry
'ur.jawadi'           // Syed Zeeshan Haider Jawadi
'ur.qadri'            // Tahir ul Qadri
```

---

## 📦 Project Setup

### **Step 1: Dependencies (pubspec.yaml)**

```yaml
name: islamic_app
description: A comprehensive Islamic app

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  # Dependency Injection
  get_it: ^7.6.4

  # Networking
  dio: ^5.4.0
  connectivity_plus: ^5.0.2

  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1

  # Navigation
  go_router: ^13.0.0

  # Audio
  just_audio: ^0.9.36

  # UI Components
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0

  # Utils
  intl: ^0.18.1
  logger: ^2.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

---

## 📝 MODELS (Data Structures)

### **File: `lib/features/quran/models/surah.dart`**

```dart
import 'package:equatable/equatable.dart';

class Surah extends Equatable {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;
  final List? ayahs;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
    this.ayahs,
  });

  factory Surah.fromJson(Map json) {
    return Surah(
      number: json['number'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      englishNameTranslation: json['englishNameTranslation'] as String,
      numberOfAyahs: json['numberOfAyahs'] as int,
      revelationType: json['revelationType'] as String,
      ayahs: json['ayahs'] != null
          ? (json['ayahs'] as List)
              .map((ayah) => Ayah.fromJson(ayah))
              .toList()
          : null,
    );
  }

  Map toJson() {
    return {
      'number': number,
      'name': name,
      'englishName': englishName,
      'englishNameTranslation': englishNameTranslation,
      'numberOfAyahs': numberOfAyahs,
      'revelationType': revelationType,
      'ayahs': ayahs?.map((ayah) => ayah.toJson()).toList(),
    };
  }

  @override
  List get props => [
        number,
        name,
        englishName,
        englishNameTranslation,
        numberOfAyahs,
        revelationType,
        ayahs,
      ];
}
```

### **File: `lib/features/quran/models/ayah.dart`**

```dart
import 'package:equatable/equatable.dart';

class Ayah extends Equatable {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final bool sajda;
  final String? translation;
  final List? words;

  const Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    required this.sajda,
    this.translation,
    this.words,
  });

  factory Ayah.fromJson(Map json) {
    return Ayah(
      number: json['number'] as int,
      text: json['text'] as String,
      numberInSurah: json['numberInSurah'] as int,
      juz: json['juz'] as int,
      manzil: json['manzil'] as int,
      page: json['page'] as int,
      ruku: json['ruku'] as int,
      hizbQuarter: json['hizbQuarter'] as int,
      sajda: json['sajda'] is Map ? true : false,
      translation: json['translation'] as String?,
      words: json['words'] != null
          ? (json['words'] as List)
              .map((word) => AyahWord.fromJson(word))
              .toList()
          : null,
    );
  }

  Map toJson() {
    return {
      'number': number,
      'text': text,
      'numberInSurah': numberInSurah,
      'juz': juz,
      'manzil': manzil,
      'page': page,
      'ruku': ruku,
      'hizbQuarter': hizbQuarter,
      'sajda': sajda,
      'translation': translation,
      'words': words?.map((word) => word.toJson()).toList(),
    };
  }

  @override
  List get props => [
        number,
        text,
        numberInSurah,
        juz,
        manzil,
        page,
        ruku,
        hizbQuarter,
        sajda,
        translation,
        words,
      ];
}

class AyahWord extends Equatable {
  final int position;
  final String arabic;
  final String? translation;
  final String? transliteration;
  final List? tajweedSegments;

  const AyahWord({
    required this.position,
    required this.arabic,
    this.translation,
    this.transliteration,
    this.tajweedSegments,
  });

  factory AyahWord.fromJson(Map json) {
    return AyahWord(
      position: json['position'] as int,
      arabic: json['text'] as String,
      translation: json['translation'] as String?,
      transliteration: json['transliteration'] as String?,
    );
  }

  Map toJson() {
    return {
      'position': position,
      'text': arabic,
      'translation': translation,
      'transliteration': transliteration,
    };
  }

  @override
  List get props => [
        position,
        arabic,
        translation,
        transliteration,
        tajweedSegments,
      ];
}

// For Tajweed colored text
class TajweedSegment extends Equatable {
  final String text;
  final TajweedRule rule;

  const TajweedSegment({
    required this.text,
    required this.rule,
  });

  @override
  List get props => [text, rule];
}

enum TajweedRule {
  none,           // No special rule
  ghunnah,        // Ghunnah (nasal sound)
  idghaam,        // Idghaam (merging)
  ikhfa,          // Ikhfa (hiding)
  iqlab,          // Iqlab (conversion)
  qalqalah,       // Qalqalah (echo)
  madd,           // Madd (prolongation)
  hamzatWasl,     // Hamzat Wasl
  silent,         // Silent letter
}
```

### **File: `lib/features/quran/models/reading_mode.dart`**

```dart
import 'package:equatable/equatable.dart';

enum ReadingDisplayMode {
  arabicOnly,           // Only Arabic text
  arabicWithTranslation, // Arabic + Translation below
  wordByWord,           // Word by word with translation
  tajweed,              // Colored Tajweed
}

class ReadingPreferences extends Equatable {
  final ReadingDisplayMode displayMode;
  final bool showTajweed;
  final double arabicFontSize;
  final double translationFontSize;
  final String selectedTranslation;
  final bool showTransliteration;

  const ReadingPreferences({
    this.displayMode = ReadingDisplayMode.arabicWithTranslation,
    this.showTajweed = true,
    this.arabicFontSize = 28.0,
    this.translationFontSize = 16.0,
    this.selectedTranslation = 'en.sahih',
    this.showTransliteration = false,
  });

  ReadingPreferences copyWith({
    ReadingDisplayMode? displayMode,
    bool? showTajweed,
    double? arabicFontSize,
    double? translationFontSize,
    String? selectedTranslation,
    bool? showTransliteration,
  }) {
    return ReadingPreferences(
      displayMode: displayMode ?? this.displayMode,
      showTajweed: showTajweed ?? this.showTajweed,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      selectedTranslation: selectedTranslation ?? this.selectedTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
    );
  }

  @override
  List get props => [
        displayMode,
        showTajweed,
        arabicFontSize,
        translationFontSize,
        selectedTranslation,
        showTransliteration,
      ];
}
```

---

## 🔧 SERVICES (Business Logic + API)

### **File: `lib/features/quran/services/quran_service.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../models/surah.dart';
import '../models/ayah.dart';

class QuranService {
  final Dio _dio;
  final Box _cacheBox;

  static const String _baseUrl = 'https://api.alquran.cloud/v1';
  static const String _quranComBaseUrl = 'https://api.quran.com/api/v4';

  QuranService(this._dio, this._cacheBox) {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Get all Surahs metadata (list)
  Future<List> getAllSurahs() async {
    try {
      // Check cache first
      final cached = _cacheBox.get('all_surahs');
      if (cached != null) {
        return (cached as List)
            .map((e) => Surah.fromJson(e as Map))
            .toList();
      }

      // Fetch from API
      final response = await _dio.get('/surah');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final surahs = data.map((e) => Surah.fromJson(e)).toList();

        // Cache it
        await _cacheBox.put('all_surahs', data);

        return surahs;
      } else {
        throw Exception('Failed to load Surahs');
      }
    } on DioException catch (e) {
      // Try to return cached data on network error
      final cached = _cacheBox.get('all_surahs');
      if (cached != null) {
        return (cached as List)
            .map((e) => Surah.fromJson(e as Map))
            .toList();
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Get Surah with Ayahs (Arabic + Translation)
  Future getSurahWithTranslation(
    int surahNumber,
    String translationEdition,
  ) async {
    try {
      final cacheKey = 'surah_${surahNumber}_$translationEdition';

      // Check cache
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        return Surah.fromJson(cached as Map);
      }

      // Fetch both Arabic (Uthmani) and Translation
      final editions = 'quran-uthmani,$translationEdition';
      final response = await _dio.get('/surah/$surahNumber/editions/$editions');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;

        // data[0] = Arabic, data[1] = Translation
        final arabicData = data[0];
        final translationData = data[1];

        // Combine Arabic and Translation
        final surah = Surah.fromJson(arabicData);
        final ayahsWithTranslation = [];

        for (int i = 0; i < surah.ayahs!.length; i++) {
          final arabicAyah = surah.ayahs![i];
          final translationAyah = Ayah.fromJson(translationData['ayahs'][i]);

          ayahsWithTranslation.add(
            Ayah(
              number: arabicAyah.number,
              text: arabicAyah.text,
              numberInSurah: arabicAyah.numberInSurah,
              juz: arabicAyah.juz,
              manzil: arabicAyah.manzil,
              page: arabicAyah.page,
              ruku: arabicAyah.ruku,
              hizbQuarter: arabicAyah.hizbQuarter,
              sajda: arabicAyah.sajda,
              translation: translationAyah.text,
            ),
          );
        }

        final finalSurah = Surah(
          number: surah.number,
          name: surah.name,
          englishName: surah.englishName,
          englishNameTranslation: surah.englishNameTranslation,
          numberOfAyahs: surah.numberOfAyahs,
          revelationType: surah.revelationType,
          ayahs: ayahsWithTranslation,
        );

        // Cache it
        await _cacheBox.put(cacheKey, finalSurah.toJson());

        return finalSurah;
      } else {
        throw Exception('Failed to load Surah');
      }
    } on DioException catch (e) {
      // Try cache on error
      final cacheKey = 'surah_${surahNumber}_$translationEdition';
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        return Surah.fromJson(cached as Map);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Get word-by-word data for a Surah
  Future getSurahWithWordByWord(int surahNumber) async {
    try {
      final cacheKey = 'surah_wbw_$surahNumber';

      // Check cache
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        return Surah.fromJson(cached as Map);
      }

      // This would need Quran.com API or custom implementation
      // For now, return basic Surah
      return await getSurahWithTranslation(surahNumber, 'en.sahih');
    } catch (e) {
      throw Exception('Failed to load word-by-word data: $e');
    }
  }

  /// Search Quran
  Future<List> searchQuran(String query, String edition) async {
    try {
      final response = await _dio.get('/search/$query/$edition');

      if (response.statusCode == 200) {
        final matches = response.data['data']['matches'] as List;
        return matches.map((e) => Ayah.fromJson(e)).toList();
      } else {
        throw Exception('Search failed');
      }
    } catch (e) {
      throw Exception('Search error: $e');
    }
  }

  /// Bookmark Ayah
  Future bookmarkAyah(int surahNumber, int ayahNumber) async {
    final bookmarks = _cacheBox.get('bookmarks', defaultValue: []) as List;
    final bookmark = '$surahNumber:$ayahNumber';

    if (!bookmarks.contains(bookmark)) {
      bookmarks.add(bookmark);
      await _cacheBox.put('bookmarks', bookmarks);
    }
  }

  /// Remove bookmark
  Future removeBookmark(int surahNumber, int ayahNumber) async {
    final bookmarks = _cacheBox.get('bookmarks', defaultValue: []) as List;
    final bookmark = '$surahNumber:$ayahNumber';

    bookmarks.remove(bookmark);
    await _cacheBox.put('bookmarks', bookmarks);
  }

  /// Get all bookmarks
  Future<List> getBookmarks() async {
    final bookmarks = _cacheBox.get('bookmarks', defaultValue: []) as List;
    return bookmarks.cast();
  }

  /// Check if Ayah is bookmarked
  Future isBookmarked(int surahNumber, int ayahNumber) async {
    final bookmarks = await getBookmarks();
    return bookmarks.contains('$surahNumber:$ayahNumber');
  }

  /// Save last read position
  Future saveLastRead(int surahNumber, int ayahNumber) async {
    await _cacheBox.put('last_read', {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get last read position
  Future<Map?> getLastRead() async {
    return _cacheBox.get('last_read') as Map?;
  }
}
```

### **File: `lib/features/quran/services/tajweed_service.dart`**

```dart
import 'package:flutter/material.dart';
import '../models/ayah.dart';

class TajweedService {
  /// Parse Tajweed text and return styled segments
  /// This is a simplified version - you'll need proper Tajweed data from API
  static List<TajweedSegment> parseTajweedText(String arabicText) {
    // For now, this is a placeholder
    // Real implementation would parse Tajweed markers from API
    // or use a pre-processed dataset

    // Simplified example:
    final segments = <TajweedSegment>[];
    
    // You would parse special characters/markers here
    // For demo, return as single segment
    segments.add(TajweedSegment(
      text: arabicText,
      rule: TajweedRule.none,
    ));

    return segments;
  }

  /// Get color for Tajweed rule
  static Color getTajweedColor(TajweedRule rule) {
    switch (rule) {
      case TajweedRule.ghunnah:
        return const Color(0xFFAACCDD); // Light blue
      case TajweedRule.idghaam:
        return const Color(0xFF169777); // Green
      case TajweedRule.ikhfa:
        return const Color(0xFFAACCDD); // Light blue
      case TajweedRule.iqlab:
        return const Color(0xFFAACCDD); // Light blue
      case TajweedRule.qalqalah:
        return const Color(0xFFDD0008); // Red
      case TajweedRule.madd:
        return const Color(0xFFFF7E1E); // Orange
      case TajweedRule.hamzatWasl:
        return const Color(0xFF169777); // Green
      case TajweedRule.silent:
        return const Color(0xFFAAAAAA); // Gray
      case TajweedRule.none:
        return Colors.black;
    }
  }

  /// Get Tajweed rule name in Urdu
  static String getTajweedRuleNameUrdu(TajweedRule rule) {
    switch (rule) {
      case TajweedRule.ghunnah:
        return 'غنہ';
      case TajweedRule.idghaam:
        return 'ادغام';
      case TajweedRule.ikhfa:
        return 'اخفاء';
      case TajweedRule.iqlab:
        return 'اقلاب';
      case TajweedRule.qalqalah:
        return 'قلقلہ';
      case TajweedRule.madd:
        return 'مد';
      case TajweedRule.hamzatWasl:
        return 'ہمزۃ الوصل';
      case TajweedRule.silent:
        return 'ساکن';
      case TajweedRule.none:
        return '';
    }