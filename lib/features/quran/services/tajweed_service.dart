import 'package:flutter/material.dart';
import '../models/ayah.dart';

/// Complete Tajweed Service
/// Quran.com API se colored tajweed text parse karta hai
class TajweedService {
  // Quran.com tajweed API se milne wale rule codes
  // https://api.quran.com/api/v4/verses/by_chapter/1?words=true&word_fields=text_uthmani,transliteration,tajweed
  static const Map<String, TajweedRule> _ruleCodeMap = {
    'ham_wasl': TajweedRule.hamzatWasl,
    'laam_shamsiyya': TajweedRule.laamShamsiyya,
    'madda_normal': TajweedRule.maddNormal,
    'madda_permissible': TajweedRule.maddPermissible,
    'madda_necessary': TajweedRule.maddNecessary,
    'madda_obligatory': TajweedRule.maddObligatory,
    'qalaqala': TajweedRule.qalqalah,
    'ikhafa_shafawi': TajweedRule.ikhfaShafawi,
    'ikhafa': TajweedRule.ikhfa,
    'idghaam_shafawi': TajweedRule.idghaamShafawi,
    'idghaam_ghunnah': TajweedRule.idghaamGhunnah,
    'idghaam_wo_ghunnah': TajweedRule.idghaamWithoutGhunnah,
    'idghaam_mutajanisayn': TajweedRule.idghaamMutajanisayn,
    'idghaam_mutaqaribayn': TajweedRule.idghaamMutaqaribayn,
    'iqlab': TajweedRule.iqlab,
    'ghunnah': TajweedRule.ghunnah,
    'idgham_with_ghunnah': TajweedRule.idghaamGhunnah,
    'silent': TajweedRule.silent,
  };

  /// Quran.com API ke tajweed_char_type_name se segments banao
  /// API response format:
  /// "tajweed": [{"duration": 0, "type": "ghunnah", "start": 0, "end": 3}]
  static List<TajweedSegment> parseTajweedSegments(
      String arabicText,
      List<dynamic>? tajweedData,
      ) {
    if (tajweedData == null || tajweedData.isEmpty) {
      return [TajweedSegment(text: arabicText, rule: TajweedRule.none)];
    }

    final segments = <TajweedSegment>[];
    int lastIndex = 0;

    // Sort by start position
    final sorted = List<dynamic>.from(tajweedData)
      ..sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));

    for (final item in sorted) {
      final start = item['start'] as int? ?? 0;
      final end = item['end'] as int? ?? arabicText.length;
      final ruleCode = item['type'] as String? ?? '';

      // Start se pehle ka normal text
      if (start > lastIndex) {
        final normalText = _safeSubstring(arabicText, lastIndex, start);
        if (normalText.isNotEmpty) {
          segments.add(TajweedSegment(text: normalText, rule: TajweedRule.none));
        }
      }

      // Tajweed segment
      final ruleText = _safeSubstring(arabicText, start, end);
      if (ruleText.isNotEmpty) {
        final rule = _ruleCodeMap[ruleCode] ?? TajweedRule.none;
        segments.add(TajweedSegment(text: ruleText, rule: rule));
      }

      lastIndex = end;
    }

    // Remaining text
    if (lastIndex < arabicText.length) {
      final remaining = _safeSubstring(arabicText, lastIndex, arabicText.length);
      if (remaining.isNotEmpty) {
        segments.add(TajweedSegment(text: remaining, rule: TajweedRule.none));
      }
    }

    return segments.isEmpty
        ? [TajweedSegment(text: arabicText, rule: TajweedRule.none)]
        : segments;
  }

  static String _safeSubstring(String text, int start, int end) {
    if (start < 0) start = 0;
    if (end > text.length) end = text.length;
    if (start >= end) return '';
    return text.substring(start, end);
  }

  /// Har Tajweed rule ka color — GatewayToQuran style
  /// Red: Ghunnah
  /// Green: Ikhfa
  /// Blue: Qalqalah
  /// Pink/Purple: Madd
  /// Orange: Iqlab
  static Color getTajweedColor(TajweedRule rule) {
    switch (rule) {
      // 🔴 RED GROUP (Ghunnah / Nasal)
      case TajweedRule.ghunnah:
      case TajweedRule.idghaamGhunnah:
      case TajweedRule.idghaamMutajanisayn:
      case TajweedRule.idghaamMutaqaribayn:
        return const Color(0xFFF30606); // Red

      // 🟢 GREEN GROUP (Ikhfa / Hiding)
      case TajweedRule.ikhfa:
      case TajweedRule.ikhfaShafawi:
      case TajweedRule.idghaamShafawi:
        return const Color(0xFF05CC0F); // Green

      // 🔵 BLUE GROUP (Qalqalah / Echo)
      case TajweedRule.qalqalah:
        return const Color(0xFF4C9DFA); // Blue

      // 🟣 PURPLE/PINK GROUP (Madd / Elongation)
      case TajweedRule.maddNormal:
        return const Color(0xFFA20AC6); // Purple
      case TajweedRule.maddPermissible:
      case TajweedRule.maddNecessary:
      case TajweedRule.maddObligatory:
        return const Color(0xFFFA0267); // Pink/Dark Pink

      // 🟠 ORANGE (Iqlab / Change)
      case TajweedRule.iqlab:
        return const Color(0xFFEF6C00); // Orange

      // ⚪ GREY (Silent / No sound)
      case TajweedRule.hamzatWasl:
      case TajweedRule.laamShamsiyya:
      case TajweedRule.silent:
      case TajweedRule.idghaamWithoutGhunnah:
        return const Color(0xFF9E9E9E); // Grey

      // 🔵 DARK ROYAL BLUE (Heavy / Tafkhim - Autodetected)
      case TajweedRule.heavy:
        return const Color(0xFF0159FF); // Dark Royal Blue

      case TajweedRule.none:
        return Colors.black;
    }
  }

  /// Tajweed rule ka Urdu naam
  static String getTajweedRuleNameUrdu(TajweedRule rule) {
    switch (rule) {
      case TajweedRule.hamzatWasl:
        return 'ہمزۃ الوصل';
      case TajweedRule.laamShamsiyya:
        return 'لام شمسیہ';
      case TajweedRule.maddNormal:
        return 'مد طبیعی';
      case TajweedRule.maddPermissible:
        return 'مد جائز';
      case TajweedRule.maddNecessary:
        return 'مد لازم';
      case TajweedRule.maddObligatory:
        return 'مد واجب';
      case TajweedRule.qalqalah:
        return 'قلقلہ';
      case TajweedRule.ikhfaShafawi:
        return 'اخفاء شفوی';
      case TajweedRule.ikhfa:
        return 'اخفاء';
      case TajweedRule.idghaamShafawi:
        return 'ادغام شفوی';
      case TajweedRule.idghaamGhunnah:
        return 'ادغام بغنہ';
      case TajweedRule.idghaamWithoutGhunnah:
        return 'ادغام بلا غنہ';
      case TajweedRule.idghaamMutajanisayn:
        return 'ادغام متجانسین';
      case TajweedRule.idghaamMutaqaribayn:
        return 'ادغام متقاربین';
      case TajweedRule.iqlab:
        return 'اقلاب';
      case TajweedRule.ghunnah:
        return 'غنہ';
      case TajweedRule.silent:
        return 'ساکن';
      case TajweedRule.heavy:
        return 'پر (مفخم)';
      case TajweedRule.none:
        return '';
    }
  }

  /// Tajweed rule ka English naam
  static String getTajweedRuleNameEnglish(TajweedRule rule) {
    switch (rule) {
      case TajweedRule.hamzatWasl:
        return 'Hamzat Wasl';
      case TajweedRule.laamShamsiyya:
        return 'Laam Shamsiyya';
      case TajweedRule.maddNormal:
        return 'Normal Madd';
      case TajweedRule.maddPermissible:
        return 'Permissible Madd';
      case TajweedRule.maddNecessary:
        return 'Necessary Madd';
      case TajweedRule.maddObligatory:
        return 'Obligatory Madd';
      case TajweedRule.qalqalah:
        return 'Qalqalah';
      case TajweedRule.ikhfaShafawi:
        return 'Ikhfa Shafawi';
      case TajweedRule.ikhfa:
        return 'Ikhfa';
      case TajweedRule.idghaamShafawi:
        return 'Idghaam Shafawi';
      case TajweedRule.idghaamGhunnah:
        return 'Idghaam with Ghunnah';
      case TajweedRule.idghaamWithoutGhunnah:
        return 'Idghaam without Ghunnah';
      case TajweedRule.idghaamMutajanisayn:
        return 'Idghaam Mutajanisayn';
      case TajweedRule.idghaamMutaqaribayn:
        return 'Idghaam Mutaqaribayn';
      case TajweedRule.iqlab:
        return 'Iqlab';
      case TajweedRule.ghunnah:
        return 'Ghunnah';
      case TajweedRule.silent:
        return 'Silent';
      case TajweedRule.heavy:
        return 'Heavy (Tafkhim)';
      case TajweedRule.none:
        return '';
    }
  }

  /// RichText ke liye TextSpan list banao (Tajweed colors ke saath)
  static List<TextSpan> buildTajweedSpans(
      List<TajweedSegment> segments,
      double fontSize,
      String fontFamily,
      ) {
    return segments.map((segment) {
      final color = getTajweedColor(segment.rule);
      return TextSpan(
        text: segment.text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: fontFamily,
          height: 1.8,
        ),
      );
    }).toList();
  }

  /// AlQuran.cloud Tajweed text (`[h:1[ٱ]...`) se TextSpans banao
  static List<TextSpan> parseTajweedTextToSpans(
      String tajweedText,
      double fontSize,
      String fontFamily,
      ) {
    final spans = <TextSpan>[];
    
    // Regex explanation:
    // \[([a-z])(?::\d+)?\[([^\]]+)\]
    // \[       : match literal [
    // ([a-z])  : Group 1 - Code (h, n, p, etc.)
    // (?::\d+)? : Optional non-capturing group for :ID (e.g. :1, :14679)
    // \[       : match literal [
    // ([^\]]+) : Group 2 - The text content (e.g. ٱ)
    // \]       : match literal ]
    //
    // NOTE: This regex assumes no nested brackets in the text content. 
    // AlQuran.cloud text seems flat or simple nesting.
    // Example: [h:1[ٱ] -> Code: h, Text: ٱ
    
    final regex = RegExp(r'\[([a-z])(?::\d+)?\[([^\]]+)\]');
    
    int lastIndex = 0;
    
    for (final match in regex.allMatches(tajweedText)) {
      // 1. Add plain text before the match (now with heavy letter detection)
      if (match.start > lastIndex) {
        final plainText = tajweedText.substring(lastIndex, match.start);
        spans.addAll(_parsePlainTextForHeavyLetters(plainText, fontSize, fontFamily));
      }
      
      // 2. Add colored text
      final code = match.group(1);
      final text = match.group(2);
      final rule = _mapCodeToRule(code);
      final color = getTajweedColor(rule);
      
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: fontFamily,
          height: 2.0,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // 3. Add remaining plain text
    if (lastIndex < tajweedText.length) {
      final remaining = tajweedText.substring(lastIndex);
      spans.addAll(_parsePlainTextForHeavyLetters(remaining, fontSize, fontFamily));
    }
    
    return spans;
  }

  /// Plain text mein se Heavy Letters (Tafkhim) detect karo
  /// Letters: خ ص ض غ ط ق ظ
  static List<TextSpan> _parsePlainTextForHeavyLetters(
      String text,
      double fontSize,
      String fontFamily,
      ) {
    final spans = <TextSpan>[];
    // Regex for heavy letters: [خ|ص|ض|غ|ط|ق|ظ]
    // Use character class properly
    final heavyRegex = RegExp(r'[خصضغطقظ]'); 
    
    int lastIdx = 0;
    for (final match in heavyRegex.allMatches(text)) {
      if (match.start > lastIdx) {
        // Text before heavy letter
        spans.add(TextSpan(
          text: text.substring(lastIdx, match.start),
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            fontFamily: fontFamily,
            height: 2.0,
          ),
        ));
      }
      
      // The heavy letter itself
      final heavyChar = text.substring(match.start, match.end);
      spans.add(TextSpan(
        text: heavyChar,
        style: TextStyle(
          color: getTajweedColor(TajweedRule.heavy), // Dark Royal Blue
          fontSize: fontSize,
          fontFamily: fontFamily,
          height: 2.0,
        ),
      ));
      
      lastIdx = match.end;
    }
    
    // Remaining text after last heavy letter
    if (lastIdx < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIdx),
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontFamily: fontFamily,
          height: 2.0,
        ),
      ));
    }
    
    return spans;
  }

  static TajweedRule _mapCodeToRule(String? code) {
    if (code == null) return TajweedRule.none;
    switch (code) {
      case 'h': // Hamzat Wasl
      case 'l': // Lam Shamsiyya / Silent letters
        return TajweedRule.silent;
      case 'n': // Normal Madd
        return TajweedRule.maddNormal;
      case 'p': // Permissible Madd
        return TajweedRule.maddPermissible;
      case 'm': // Necessary Madd
        return TajweedRule.maddNecessary;
      case 'q': // Qalqalah
        return TajweedRule.qalqalah;
      case 'g': // Ghunnah
        return TajweedRule.ghunnah;
      case 'f': // Ikhfa (guessed from 'Min Sharri')
      // Note: 'c' is sometimes used for Ikhfa in other protocols, but 'f' seen in data
        return TajweedRule.ikhfa;
      default:
        return TajweedRule.none;
    }
  }

  /// Legend ke liye sab active rules return karo
  static List<TajweedRule> getAllRules() {
    return [
      TajweedRule.ghunnah,
      TajweedRule.idghaamGhunnah,
      TajweedRule.idghaamWithoutGhunnah,
      TajweedRule.ikhfa,
      TajweedRule.iqlab,
      TajweedRule.qalqalah,
      TajweedRule.maddNormal,
      TajweedRule.maddPermissible,
      TajweedRule.maddNecessary,
      TajweedRule.hamzatWasl,
      TajweedRule.silent,
    ];
  }
}