import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TranslationService {
  final Dio _dio;
  
  // Simple in-memory cache to prevent redundant API calls
  static final Map<String, String> _cache = {};

  static const Map<String, Map<String, String>> _phraseMap = {
    'jazakallah': {
      'ur': 'جزاک اللہ خیراً',
      'hi': 'जज़ाकअल्लाह',
      'ar': 'جزاك الله خيراً',
      'en': 'JazakAllah',
      'fr': "Qu'Allah vous récompense",
      'es': 'Que Allah te recompense',
      'tr': 'Allah razı olsun',
      'id': 'Jazakallahu khairan',
      'bn': 'জাজাকাল্লাহ',
      'ms': 'Jazakallahu khairan',
      'fa': 'جزاک الله',
      'ru': 'Джазакаллаху хайран',
    },
    'hadith of the day': {
      'ur': 'حدیثِ مبارکہ',
      'hi': 'आज की हदीस',
      'ar': 'حديث اليوم',
      'en': 'Hadith of the Day',
      'fr': 'Hadith du jour',
      'es': 'Hadiz del día',
      'tr': 'Günün Hadisi',
      'id': 'Hadits Hari Ini',
      'bn': 'আজকের হাদিস',
    },
    'daily hadith': {
      'ur': 'آج کی حدیثِ مبارکہ',
      'hi': 'दैनिक हदीस',
      'ar': 'الحديث اليومي',
      'en': 'Daily Hadith',
      'fr': 'Hadith quotidien',
      'es': 'Hadiz diario',
      'tr': 'Günlük Hadis',
      'id': 'Hadits Harian',
      'bn': 'দৈনিক হাদিস',
    },
    'daily hadith of the day • tap to view': {
      'ur': 'آج کی حدیثِ مبارکہ • دیکھنے کے لیے ٹیپ کریں',
      'hi': 'आज की हदीस • देखने के लिए टैप करें',
      'ar': 'حديث اليوم • انقر للعرض',
      'en': 'Daily Hadith of the Day • Tap to view',
      'fr': 'Hadith du jour • Appuyez pour voir',
      'es': 'Hadiz del día • Toca para ver',
      'tr': 'Günün Hadisi • Görmek için dokunun',
      'id': 'Hadits Hari Ini • Ketuk untuk melihat',
    },
  };

  static const Map<String, String> _urduOverrides = {
    'kalma': 'کلمہ',
    'kalmas': 'کلمے',
    '6 kalmas': '6 کلمے',
    'namaz': 'نماز',
    'roza': 'روزہ',
    'zakat': 'زکوٰۃ',
    'hajj': 'حج',
    'the declaration of faith': 'ایمان کا اقرار',
    'the five daily prayers': 'پانچ وقت کی نماز',
    'fasting in ramadan': 'رمضان میں روزہ',
    'obligatory charity': 'فرض زکوٰۃ',
    'pilgrimage to makkah': 'مکہ کی زیارت (حج)',
    '5 pillars of islam': 'اسلام کے 5 ارکان',
    'explore the foundational acts of worship in islam.': 'اسلام میں عبادت کے بنیادی اعمال کو دریافت کریں۔',
    'first kalma (tayyab)': 'پہلا کلمہ (طیب)',
    'second kalma (shahadat)': 'دوسرا کلمہ (شہادت)',
    'third kalma (tamjeed)': 'تیسرا کلمہ (تمجید)',
    'fourth kalma (tauheed)': 'چوتھا کلمہ (توحید)',
    'fifth kalma (astaghfar)': 'پانچواں کلمہ (استغفار)',
    'sixth kalma (radde kufr)': 'چھٹا کلمہ (ردِ کفر)',
    'transliteration': 'رومن اردو',
    'copy': 'کاپی',
    'share': 'شیئر',
    'jazakallah': 'جزاک اللہ خیراً',
    'hadith of the day': 'حدیثِ مبارکہ',
    'daily hadith': 'آج کی حدیثِ مبارکہ',
    'daily hadith of the day • tap to view': 'آج کی حدیثِ مبارکہ • دیکھنے کے لیے ٹیپ کریں',
    'hadith copied to clipboard': 'حدیث کاپی کر لی گئی ہے',
  };

  TranslationService(this._dio);

  Future<String> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    if (text.trim().isEmpty) return text;

    final key = text.trim().toLowerCase();

    // Check multi-language phrase map first (JazakAllah, Daily Hadith, etc.)
    if (_phraseMap.containsKey(key)) {
      final langMap = _phraseMap[key]!;
      if (langMap.containsKey(targetLang)) {
        return langMap[targetLang]!;
      }
    }
    
    if (targetLang == 'ur') {
      if (_urduOverrides.containsKey(key)) {
        return _urduOverrides[key]!;
      }
    }

    final cacheKey = '${text}_${sourceLang}_$targetLang';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _dio.get(
        'https://translate.googleapis.com/translate_a/single',
        queryParameters: {
          'client': 'gtx',
          'sl': sourceLang,
          'tl': targetLang,
          'dt': 't',
          'q': text,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty && data[0] is List) {
          final List<dynamic> translationParts = data[0];
          StringBuffer translatedText = StringBuffer();
          
          for (var part in translationParts) {
            if (part is List && part.isNotEmpty) {
              translatedText.write(part[0].toString());
            }
          }
          
          final result = translatedText.toString();
          _cache[cacheKey] = result;
          return result;
        }
      }
      return text;
    } catch (e) {
      debugPrint('Translation Error: $e');
      return text;
    }
  }
}
