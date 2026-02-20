import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../models/tafseer_source.dart';
import '../models/tafseer_source.dart';

class TafseerService {
  final Dio _dio;
  final Box<dynamic> _cacheBox;

  static const String _baseUrl = 'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir';

  TafseerService(this._dio, this._cacheBox);

  /// Fetches Tafseer text for a complete Surah
  /// Returns a Map where Key = Ayah Number, Value = Tafseer Text
  Future<Map<int, String>> getTafseerText(String id, int surahNumber) async {
    final cacheKey = 'tafseer_text_${id}_$surahNumber';
    
    // 1. Check Cache
    final cached = _cacheBox.get(cacheKey);
    if (cached != null) {
      return Map<int, String>.from(cached as Map);
    }

    try {
      // 2. Fetch from API
      // URL format: https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/{slug}/{surahNumber}.json
      final url = '$_baseUrl/$id/$surahNumber.json';
      final res = await _dio.get(url);

      if (res.statusCode == 200) {
        final data = res.data; 
        final ayahs = data['ayahs'] as List;
        
        final resultMap = <int, String>{};
        for (final item in ayahs) {
          final ayahNum = item['ayah'] as int;
          final text = item['text'] as String;
          resultMap[ayahNum] = text;
        }

        // 3. Save to Cache
        await _cacheBox.put(cacheKey, resultMap);
        return resultMap;
      }
      return {};
    } catch (e) {
      print('Error fetching Tafseer: $e');
      throw Exception('Failed to load Tafseer');
    }
  }

  /// Generates the Audio URL for a specific Surah and Source
  String? getAudioUrl(TafseerSource source, int surahNumber) {
    if (source.audioUrlPattern == null) {
      return null;
    }

    String url = source.audioUrlPattern!;
    
    // Replace {surah_000} with 001, 012, 114 format
    final surahPadded = surahNumber.toString().padLeft(3, '0');
    url = url.replaceAll('{surah_000}', surahPadded);
    
    // Additional replacement logic can be added here if patterns become complex
    
    return url;
  }
}
