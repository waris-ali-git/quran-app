import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/hadith.dart';

class HadithService {
  final Dio _dio;
  final Box<dynamic> _cacheBox;

  static const String _baseUrl = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1';
  static const String _infoUrl = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/info.json';

  HadithService(this._dio, this._cacheBox);

  // 1. Get Available Editions (e.g. Bukhari in Eng, Ara, Urdu)
  Future<List<HadithBook>> getAvailableBooks() async {
    const cacheKey = 'hadith_editions';
    try {
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        return _parseEditionsFromCache(cached);
      }

      final res = await _dio.get('$_baseUrl/editions.json');
      if (res.statusCode == 200) {
        final dynamic data = res.data is String ? jsonDecode(res.data) : res.data;
        await _cacheBox.put(cacheKey, jsonEncode(data));
        return _parseEditions(Map<String, dynamic>.from(data as Map));
      }
      return [];
    } catch (e, stack) {
      debugPrint('HadithService getAvailableBooks Error: $e\n$stack');
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        return _parseEditionsFromCache(cached);
      }
      return [];
    }
  }

  List<HadithBook> _parseEditionsFromCache(dynamic cached) {
    final decoded = jsonDecode(cached.toString()) as Map<String, dynamic>;
    return _parseEditions(decoded);
  }

  List<HadithBook> _parseEditions(Map<String, dynamic> data) {
    final List<HadithBook> books = [];
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        books.add(HadithBook.fromJson(key, value));
      }
    });
    return books;
  }

  // 2. Fetch the metadata (sections) of a specific edition
  // ─── Sections (Chapters) ───────────────────
  Future<List<HadithSection>> getEditionSections(String editionIdentifier) async {
    // Preferred: use info.json (smaller + consistent structure).
    final infoCacheKey = 'hadith_info_json_v1';
    try {
      dynamic info;
      final cachedInfo = _cacheBox.get(infoCacheKey);
      if (cachedInfo != null) {
        info = jsonDecode(cachedInfo.toString());
      } else {
        final res = await _dio.get(_infoUrl);
        if (res.statusCode == 200) {
          info = res.data is String ? jsonDecode(res.data) : res.data;
          await _cacheBox.put(infoCacheKey, jsonEncode(info));
        }
      }

      final bookId = _bookIdFromEdition(editionIdentifier);
      final bookInfo = (info is Map) ? info[bookId] : null;
      if (bookInfo is Map) {
        final meta = bookInfo['metadata'];
        if (meta is Map) {
          return _parseSectionsFromInfoJson(Map<String, dynamic>.from(meta));
        }
      }

      // Fallback to old (monolithic) edition metadata parsing if info.json missing structure
      return await _getSectionsFromEditionJsonFallback(editionIdentifier);
    } catch (e, stack) {
      debugPrint('HadithService getEditionSections Error: $e\n$stack');
      // Fallback if info.json fails
      return await _getSectionsFromEditionJsonFallback(editionIdentifier);
    }
  }

  String _bookIdFromEdition(String editionIdentifier) {
    final parts = editionIdentifier.split('-');
    if (parts.length <= 1) return editionIdentifier;
    return parts.sublist(1).join('-');
  }

  Future<List<HadithSection>> _getSectionsFromEditionJsonFallback(String editionIdentifier) async {
    final cacheKey = 'hadith_edition_full_$editionIdentifier';
    try {
      dynamic data;
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        data = jsonDecode(cached.toString());
      } else {
        final res = await _dio.get('$_baseUrl/editions/$editionIdentifier.json');
        if (res.statusCode == 200) {
          data = res.data is String ? jsonDecode(res.data) : res.data;
          await _cacheBox.put(cacheKey, jsonEncode(data));
        }
      }
      if (data != null && data['metadata'] is Map) {
        return _parseSections(Map<String, dynamic>.from(data['metadata'] as Map));
      }
    } catch (e, stack) {
      debugPrint('HadithService _getSectionsFromEditionJsonFallback Error: $e\n$stack');
    }
    return [];
  }

  List<HadithSection> _parseSectionsFromInfoJson(Map<String, dynamic> metadata) {
    // info.json uses plural keys: sections / section_details
    final sections = metadata['sections'] as Map<String, dynamic>? ?? {};
    final details = metadata['section_details'] as Map<String, dynamic>? ?? {};

    final result = <HadithSection>[];
    sections.forEach((key, value) {
      final name = value?.toString().trim() ?? '';
      if (name.isEmpty) return;

      int firstHadith = 0;
      int lastHadith = 0;

      final detailObj = details[key];
      if (detailObj is Map) {
        firstHadith = int.tryParse(detailObj['hadithnumber_first']?.toString() ?? '0') ?? 0;
        lastHadith = int.tryParse(detailObj['hadithnumber_last']?.toString() ?? '0') ?? 0;
      }

      result.add(HadithSection(
        id: key.toString(),
        name: name,
        firstHadith: firstHadith,
        lastHadith: lastHadith,
      ));
    });

    // Sort numeric section ids where possible
    result.sort((a, b) {
      final ai = int.tryParse(a.id) ?? 0;
      final bi = int.tryParse(b.id) ?? 0;
      return ai.compareTo(bi);
    });

    return result;
  }

  List<HadithSection> _parseSections(Map<String, dynamic> metadata) {
    final sections = metadata['section'] as Map<String, dynamic>? ?? {};
    final sectionDetail = metadata['section_detail'] as Map<String, dynamic>? ?? {};

    final List<HadithSection> result = [];
    sections.forEach((key, value) {
      final name = value?.toString().trim() ?? '';
      final finalName = name.isNotEmpty ? name : 'Section $key';

      int firstHadith = 0;
      int lastHadith = 0;
      bool hasDetail = false;

      final detailObj = sectionDetail[key];
      if (detailObj is Map) {
        hasDetail = true;
        firstHadith = int.tryParse(detailObj['hadithnumber_first']?.toString() ?? '0') ?? 0;
        lastHadith = int.tryParse(detailObj['hadithnumber_last']?.toString() ?? '0') ?? 0;
      }
      
      if (hasDetail || name.isNotEmpty) {
        result.add(HadithSection(
          id: key,
          name: finalName,
          firstHadith: firstHadith,
          lastHadith: lastHadith,
        ));
      }
    });

    return result;
  }

  // ─── Fetch Specific Hadiths ────────────────
  Future<List<HadithItem>> getHadithsBySection(String editionIdentifier, HadithSection section) async {
    // Preferred: per-section endpoint (fast + reliable): /editions/{edition}/sections/{section}.{min.}json
    final sectionCacheKey = 'hadith_section_${editionIdentifier}_${section.id}_v1';
    try {
      // 1) cache
      final cached = _cacheBox.get(sectionCacheKey);
      if (cached != null) {
        final dynamic data = jsonDecode(cached.toString());
        return _parseHadithListFromSectionJson(data);
      }

      // 2) network: try minified then full
      final sectionId = section.id;
      final urls = [
        '$_baseUrl/editions/$editionIdentifier/sections/$sectionId.min.json',
        '$_baseUrl/editions/$editionIdentifier/sections/$sectionId.json',
      ];

      for (final url in urls) {
        try {
          final res = await _dio.get(url);
          if (res.statusCode == 200) {
            final dynamic data = res.data is String ? jsonDecode(res.data) : res.data;
            await _cacheBox.put(sectionCacheKey, jsonEncode(data));
            return _parseHadithListFromSectionJson(data);
          }
        } catch (_) {
          // try next url
        }
      }

      // 3) fallback: monolithic edition json (older path)
      return await _getHadithsFromEditionJsonFallback(editionIdentifier, section);
    } catch (e, stack) {
      debugPrint('HadithService getHadithsBySection Error: $e\n$stack');
      return await _getHadithsFromEditionJsonFallback(editionIdentifier, section);
    }
  }

  List<HadithItem> _parseHadithListFromSectionJson(dynamic data) {
    if (data is Map && data['hadiths'] is List) {
      final list = data['hadiths'] as List;
      return list
          .map((e) => HadithItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<List<HadithItem>> _getHadithsFromEditionJsonFallback(String editionIdentifier, HadithSection section) async {
    final cacheKey = 'hadith_edition_full_$editionIdentifier';
    try {
      dynamic data;
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        data = jsonDecode(cached.toString());
      } else {
        final res = await _dio.get('$_baseUrl/editions/$editionIdentifier.json');
        if (res.statusCode == 200) {
          data = res.data is String ? jsonDecode(res.data) : res.data;
          await _cacheBox.put(cacheKey, jsonEncode(data));
        }
      }

      if (data != null && data['hadiths'] is List) {
        final dataList = data['hadiths'] as List;

        // If no usable range info, return full list (avoid empty UI).
        List rawSectionHadiths;
        if (section.firstHadith == 0 && section.lastHadith == 0) {
          rawSectionHadiths = dataList;
        } else {
          rawSectionHadiths = dataList.where((h) {
            final hNumRaw = (h as Map)['hadithnumber']?.toString() ?? '0';
            final hNum = double.tryParse(hNumRaw)?.toInt() ??
                int.tryParse(hNumRaw.replaceAll(RegExp(r'[^0-9]'), '')) ??
                0;
            return hNum >= section.firstHadith && hNum <= section.lastHadith;
          }).toList();
        }

        return rawSectionHadiths
            .map((e) => HadithItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e, stack) {
      debugPrint('HadithService _getHadithsFromEditionJsonFallback Error: $e\n$stack');
    }
    return [];
  }
}
