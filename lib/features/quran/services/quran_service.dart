import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../models/reading_mode.dart';

/// Quran Service — AlQuran.cloud + Quran.com dono APIs use karta hai
/// AlQuran.cloud  → Surah list, Ayah text, Translation
/// Quran.com v4   → Word-by-word, Tajweed segments, Audio
class QuranService {
  final Dio _dio;
  final Box<dynamic> _cacheBox;

  static const String _alQuranBase = 'https://api.alquran.cloud/v1';
  static const String _quranComBase = 'https://api.quran.com/api/v4';

  // Quran.com audio reciters
  static const int _defaultReciterId = 7; // Mishari Rashid Al-Afasy

  QuranService(this._dio, this._cacheBox);

  // ─────────────────────────────────────────────
  // 1. SURAH LIST  (AlQuran.cloud)
  // ─────────────────────────────────────────────

  Future<List<Surah>> getAllSurahs() async {
    const cacheKey = 'all_surahs';
    try {
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        return (cached as List)
            .map((e) => Surah.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      final res = await _dio.get('$_alQuranBase/surah');
      if (res.statusCode == 200) {
        final data = res.data['data'] as List;
        final surahs = data.map((e) => Surah.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        await _cacheBox.put(cacheKey, data);
        return surahs;
      }
      throw Exception('Surah list load nahi hua');
    } on DioException catch (e) {
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        return (cached as List)
            .map((e) => Surah.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // ─────────────────────────────────────────────
  // 2. SURAH WITH TRANSLATION  (AlQuran.cloud)
  // ─────────────────────────────────────────────

  Future<Surah> getSurahWithTranslation(
      int surahNumber,
      String translationEdition,
      ) async {
    final cacheKey = 'surah_${surahNumber}_${translationEdition}_tj'; // Changed key
    try {
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        return Surah.fromJson(Map<String, dynamic>.from(cached as Map));
      }

      // Arabic (Uthmani) + Tajweed + Translation
      // AlQuran.cloud allows multiple editions comma separated
      final editions = 'quran-uthmani,quran-tajweed,$translationEdition';
      final res = await _dio.get('$_alQuranBase/surah/$surahNumber/editions/$editions');

      if (res.statusCode == 200) {
        final data = res.data['data'] as List;
        
        // Data order depends on response, usually matches request order but better to check identifiers if possible.
        // Usually: [0]=Uthmani, [1]=Tajweed, [2]=Translation
        // Let's assume order for now or use flexible mapping if identifiers exist.
        // API ensures order matches request usually.
        
        final arabicData = Map<String, dynamic>.from(data[0] as Map);
        final tajweedData = Map<String, dynamic>.from(data[1] as Map);
        final translData = Map<String, dynamic>.from(data[2] as Map);

        final surah = Surah.fromJson(arabicData);
        final tajweedAyahs = tajweedData['ayahs'] as List;
        final translAyahs = translData['ayahs'] as List;

        final mergedAyahs = <Ayah>[];
        for (int i = 0; i < surah.ayahs!.length; i++) {
          final ar = surah.ayahs![i];
          final tr = Map<String, dynamic>.from(translAyahs[i] as Map);
          final tj = Map<String, dynamic>.from(tajweedAyahs[i] as Map); // Tajweed ayah
          
          mergedAyahs.add(ar.copyWith(
            translation: tr['text'] as String?,
            tajweedText: tj['text'] as String?, // Store Tajweed markup text
          ));
        }

        final finalSurah = surah.copyWith(ayahs: mergedAyahs);
        await _cacheBox.put(cacheKey, finalSurah.toJson());
        return finalSurah;
      }
      throw Exception('Surah load nahi hua');
    } on DioException catch (e) {
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        return Surah.fromJson(Map<String, dynamic>.from(cached as Map));
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // ─────────────────────────────────────────────
  // 3. WORD-BY-WORD + TAJWEED  (Quran.com v4)
  // ─────────────────────────────────────────────

  /// Quran.com se ek surah ke sare verses + words lao
  /// Har word mein arabic, transliteration, translation, tajweed segments hain
  Future<List<Ayah>> getSurahWithWordByWord(
      int surahNumber, {
        int translationId = 131, // Urdu: Dr. Farooq Khan & Dr. Nadeem
        // English: 131 = Dr. Wahiduddin Khan, 57 = Sahih International
      }) async {
    final cacheKey = 'surah_wbw_${surahNumber}_${translationId}_v2';
    try {
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        return (cached as List)
            .map((e) => Ayah.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      final ayahs = <Ayah>[];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final res = await _dio.get(
          '$_quranComBase/verses/by_chapter/$surahNumber',
          queryParameters: {
            'language': 'ur',
            'words': true,
            'word_fields': 'text_uthmani,transliteration,tajweed',
            'translations': translationId,
            'per_page': 50,
            'page': page,
          },
        );

        if (res.statusCode == 200) {
          final verses = res.data['verses'] as List;
          final meta = res.data['meta'] as Map<String, dynamic>? ?? {};
          final totalPages = meta['total_pages'] as int? ?? 1;

          for (final v in verses) {
            final ayah = Ayah.fromQuranComJson(Map<String, dynamic>.from(v as Map));
            ayahs.add(ayah);
          }

          hasMore = page < totalPages;
          page++;
        } else {
          break;
        }
      }

      // Cache karo
      await _cacheBox.put(cacheKey, ayahs.map((a) => a.toJson()).toList());
      return ayahs;
    } on DioException catch (e) {
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        return (cached as List)
            .map((e) => Ayah.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      throw Exception('Word-by-word load nahi hua: ${e.message}');
    }
  }

  // ─────────────────────────────────────────────
  // 4. AUDIO  (Quran.com v4)
  // ─────────────────────────────────────────────

  /// Single ayah ki audio URL
  Future<String?> getAyahAudioUrl(
      int surahNumber,
      int ayahNumber, {
        int reciterId = _defaultReciterId,
      }) async {
    final verseKey = '$surahNumber:$ayahNumber';
    final cacheKey = 'audio_${verseKey}_$reciterId';

    try {
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) return cached as String;

      final res = await _dio.get(
        '$_quranComBase/recitations/$reciterId/by_ayah/$verseKey',
      );

      if (res.statusCode == 200) {
        final audioFiles = res.data['audio_files'] as List?;
        if (audioFiles != null && audioFiles.isNotEmpty) {
          final url = 'https://verses.quran.com/${audioFiles[0]['url']}';
          await _cacheBox.put(cacheKey, url);
          return url;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Reciters list
  Future<List<Map<String, dynamic>>> getReciters() async {
    const cacheKey = 'reciters_list';
    try {
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        return (cached as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      final res = await _dio.get('$_quranComBase/resources/recitations');
      if (res.statusCode == 200) {
        final data = res.data['recitations'] as List;
        final reciters = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        await _cacheBox.put(cacheKey, data);
        return reciters;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // 5. SEARCH  (AlQuran.cloud)
  // ─────────────────────────────────────────────

  Future<List<Ayah>> searchQuran(String query, String edition) async {
    try {
      final res = await _dio.get(
        '$_alQuranBase/search/$query/$edition',
      );
      if (res.statusCode == 200) {
        final matches = res.data['data']['matches'] as List;
        return matches.map((e) => Ayah.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Search error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // 6. BOOKMARKS  (Local — Hive)
  // ─────────────────────────────────────────────

  Future<void> bookmarkAyah(int surahNumber, int ayahNumber) async {
    final bookmarks = _cacheBox.get('bookmarks', defaultValue: <dynamic>[]) as List;
    final key = '$surahNumber:$ayahNumber';
    if (!bookmarks.contains(key)) {
      bookmarks.add(key);
      await _cacheBox.put('bookmarks', bookmarks);
    }
  }

  Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    final bookmarks = _cacheBox.get('bookmarks', defaultValue: <dynamic>[]) as List;
    bookmarks.remove('$surahNumber:$ayahNumber');
    await _cacheBox.put('bookmarks', bookmarks);
  }

  Future<List<String>> getBookmarks() async {
    final bookmarks = _cacheBox.get('bookmarks', defaultValue: <dynamic>[]) as List;
    return bookmarks.cast<String>();
  }

  Future<bool> isBookmarked(int surahNumber, int ayahNumber) async {
    final bookmarks = await getBookmarks();
    return bookmarks.contains('$surahNumber:$ayahNumber');
  }

  // ─────────────────────────────────────────────
  // 7. LAST READ  (Local — Hive)
  // ─────────────────────────────────────────────

  Future<void> saveLastRead(int surahNumber, int ayahNumber) async {
    await _cacheBox.put('last_read', {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getLastRead() async {
    final data = _cacheBox.get('last_read');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  // ─────────────────────────────────────────────
  // 8. READING PREFERENCES  (Local — Hive)
  // ─────────────────────────────────────────────

  Future<void> saveReadingPreferences(ReadingPreferences prefs) async {
    await _cacheBox.put('reading_prefs', {
      'displayMode': prefs.displayMode.index,
      'showTajweed': prefs.showTajweed,
      'arabicFontSize': prefs.arabicFontSize,
      'translationFontSize': prefs.translationFontSize,
      'selectedTranslation': prefs.selectedTranslation,
      'showTransliteration': prefs.showTransliteration,
    });
  }

  Future<ReadingPreferences> getReadingPreferences() async {
    final data = _cacheBox.get('reading_prefs');
    if (data == null) return const ReadingPreferences();
    final map = Map<String, dynamic>.from(data as Map);
    return ReadingPreferences(
      displayMode: ReadingDisplayMode.values[map['displayMode'] as int? ?? 1],
      showTajweed: map['showTajweed'] as bool? ?? true,
      arabicFontSize: (map['arabicFontSize'] as num?)?.toDouble() ?? 28.0,
      translationFontSize: (map['translationFontSize'] as num?)?.toDouble() ?? 16.0,
      selectedTranslation: map['selectedTranslation'] as String? ?? 'en.sahih',
      showTransliteration: map['showTransliteration'] as bool? ?? false,
    );
  }
}