import 'package:equatable/equatable.dart';
import 'surah.dart';


// ───────────────────────────────────────────────
// TAJWEED RULE ENUM (Complete — image jaise)
// ───────────────────────────────────────────────
enum TajweedRule {
  none,
  hamzatWasl,
  laamShamsiyya,
  maddNormal,
  maddPermissible,
  maddNecessary,
  maddObligatory,
  qalqalah,
  ikhfaShafawi,
  ikhfa,
  idghaamShafawi,
  idghaamGhunnah,
  idghaamWithoutGhunnah,
  idghaamMutajanisayn,
  idghaamMutaqaribayn,
  iqlab,
  ghunnah,
  silent,
  heavy, // New rule for Tafkhim
}

// ───────────────────────────────────────────────
// TAJWEED SEGMENT
// ───────────────────────────────────────────────
class TajweedSegment extends Equatable {
  final String text;
  final TajweedRule rule;

  const TajweedSegment({
    required this.text,
    required this.rule,
  });

  @override
  List<Object?> get props => [text, rule];
}

// ───────────────────────────────────────────────
// AYAH WORD (Word-by-word with Tajweed support)
// ───────────────────────────────────────────────
class AyahWord extends Equatable {
  final int position;
  final String arabic;
  final String? translation;
  final String? transliteration;
  final List<TajweedSegment>? tajweedSegments;
  final String? audioUrl;

  const AyahWord({
    required this.position,
    required this.arabic,
    this.translation,
    this.transliteration,
    this.tajweedSegments,
    this.audioUrl,
  });

  /// Quran.com API v4 word format se parse karo
  /// GET /verses/by_chapter/{chapter}?words=true&word_fields=text_uthmani,transliteration,translation_text,tajweed
  factory AyahWord.fromQuranComJson(Map<String, dynamic> json) {
    List<TajweedSegment>? segments;

    // Quran.com tajweed array parse karo
    final tajweedData = json['tajweed'] as List<dynamic>?;
    final arabicText = json['text_uthmani'] as String? ?? json['text'] as String? ?? '';

    if (tajweedData != null && tajweedData.isNotEmpty) {
      segments = _parseTajweedFromApi(arabicText, tajweedData);
    }

    // Translation text — nested object mein hota hai
    String? translationText;
    if (json['translation'] is Map) {
      translationText = (json['translation'] as Map)['text'] as String?;
    } else {
      translationText = json['translation'] as String?;
    }

    return AyahWord(
      position: json['position'] as int? ?? json['char_type_id'] as int? ?? 0,
      arabic: arabicText,
      translation: translationText,
      transliteration: json['transliteration'] is Map
          ? (json['transliteration'] as Map)['text'] as String?
          : json['transliteration'] as String?,
      tajweedSegments: segments,
    );
  }

  /// AlQuran.cloud format se parse karo (basic, no tajweed)
  factory AyahWord.fromAlQuranCloudJson(Map<String, dynamic> json) {
    return AyahWord(
      position: json['position'] as int? ?? 0,
      arabic: json['text'] as String? ?? '',
      translation: json['translation'] as String?,
      transliteration: json['transliteration'] as String?,
    );
  }

  static List<TajweedSegment> _parseTajweedFromApi(
      String text,
      List<dynamic> tajweedData,
      ) {
    const ruleCodeMap = <String, TajweedRule>{
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
      'silent': TajweedRule.silent,
    };

    final segments = <TajweedSegment>[];
    int lastIndex = 0;

    final sorted = List<dynamic>.from(tajweedData)
      ..sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));

    for (final item in sorted) {
      final start = item['start'] as int? ?? 0;
      final end = item['end'] as int? ?? text.length;
      final ruleCode = item['type'] as String? ?? '';

      if (start > lastIndex) {
        final t = _sub(text, lastIndex, start);
        if (t.isNotEmpty) segments.add(TajweedSegment(text: t, rule: TajweedRule.none));
      }

      final t = _sub(text, start, end);
      if (t.isNotEmpty) {
        segments.add(TajweedSegment(
          text: t,
          rule: ruleCodeMap[ruleCode] ?? TajweedRule.none,
        ));
      }
      lastIndex = end;
    }

    if (lastIndex < text.length) {
      final t = _sub(text, lastIndex, text.length);
      if (t.isNotEmpty) segments.add(TajweedSegment(text: t, rule: TajweedRule.none));
    }

    return segments.isEmpty
        ? [TajweedSegment(text: text, rule: TajweedRule.none)]
        : segments;
  }

  static String _sub(String text, int start, int end) {
    if (start < 0) start = 0;
    if (end > text.length) end = text.length;
    if (start >= end) return '';
    return text.substring(start, end);
  }

  Map<String, dynamic> toJson() => {
    'position': position,
    'text': arabic,
    'translation': translation,
    'transliteration': transliteration,
  };

  @override
  List<Object?> get props => [position, arabic, translation, transliteration, tajweedSegments];
}

// ───────────────────────────────────────────────
// AYAH
// ───────────────────────────────────────────────

// ───────────────────────────────────────────────
// AYAH
// ───────────────────────────────────────────────
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
  final String? transliteration;
  final List<AyahWord>? ayahWords; // Renamed from words
  final String? audioUrl;
  final String? tajweedText; // AlQuran.cloud tajweed text with codes
  final String? tafseerText; // Tafseer explanation (e.g. Maududi)
  final Surah? surah; // For search results

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
    this.transliteration,
    this.ayahWords,
    this.audioUrl,
    this.tajweedText,
    this.tafseerText,
    this.surah,
  });

  /// AlQuran.cloud format
  factory Ayah.fromJson(Map<String, dynamic> json) {
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
      ayahWords: json['words'] != null
          ? (json['words'] as List)
          .map((w) => AyahWord.fromAlQuranCloudJson(Map<String, dynamic>.from(w as Map)))
          .toList()
          : null,
      audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${json['number']}.mp3',
      tajweedText: json['tajweedText'] as String?,
      tafseerText: json['tafseerText'] as String?,
      surah: json['surah'] != null ? Surah.fromJson(Map<String, dynamic>.from(json['surah'] as Map)) : null,
    );
  }

  /// Quran.com v4 verse format
  factory Ayah.fromQuranComJson(Map<String, dynamic> json) {
    final verseKey = json['verse_key'] as String? ?? '';
    final parts = verseKey.split(':');
    final numberInSurah = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return Ayah(
      number: json['id'] as int? ?? 0,
      text: json['text_uthmani'] as String? ?? '',
      numberInSurah: numberInSurah,
      juz: json['juz_number'] as int? ?? 0,
      manzil: json['manzil_number'] as int? ?? 0,
      page: json['page_number'] as int? ?? 0,
      ruku: json['ruku_number'] as int? ?? 0,
      hizbQuarter: json['hizb_number'] as int? ?? 0,
      sajda: json['sajdah_type'] != null,
      translation: json['translations'] != null
          ? ((json['translations'] as List).first['text'] as String?)
          : null,
      ayahWords: json['words'] != null
          ? (json['words'] as List)
          .where((w) => (w as Map)['char_type_name'] == 'word')
          .map((w) => AyahWord.fromQuranComJson(Map<String, dynamic>.from(w as Map)))
          .toList()
          : null,
      audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${json['id']}.mp3',
      // tajweedText not available from Quran.com usually
    );
  }

  Map<String, dynamic> toJson() => {
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
    'transliteration': transliteration,
    'words': ayahWords?.map((w) => w.toJson()).toList(),
    'audio': audioUrl,
    'tajweedText': tajweedText,
    'tafseerText': tafseerText,
    'surah': surah?.toJson(),
  };

  Ayah copyWith({
    String? translation,
    String? transliteration,
    List<AyahWord>? words,
    String? audioUrl,
    String? tajweedText,
    String? tafseerText,
    Surah? surah,
  }) {
    return Ayah(
      number: number,
      text: text,
      numberInSurah: numberInSurah,
      juz: juz,
      manzil: manzil,
      page: page,
      ruku: ruku,
      hizbQuarter: hizbQuarter,
      sajda: sajda,
      translation: translation ?? this.translation,
      transliteration: transliteration ?? this.transliteration,
      ayahWords: words ?? ayahWords,
      audioUrl: audioUrl ?? this.audioUrl,
      tajweedText: tajweedText ?? this.tajweedText,
      tafseerText: tafseerText ?? this.tafseerText,
      surah: surah ?? this.surah,
    );
  }

  @override
  List<Object?> get props => [
    number, text, numberInSurah, juz, manzil, page,
    ruku, hizbQuarter, sajda, translation, transliteration, ayahWords,
    tajweedText, tafseerText, surah,
  ];
}