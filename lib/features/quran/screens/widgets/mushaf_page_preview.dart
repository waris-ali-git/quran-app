import 'package:flutter/material.dart';
import '../../models/surah.dart';
import '../../models/ayah.dart';

/// Renders Surah text in a mushaf-style page layout.
/// Uses the already-loaded Surah data — no database needed.
class MushafPagePreview extends StatelessWidget {
  final Surah surah;
  const MushafPagePreview({super.key, required this.surah});

  static const List<String> _bismillahVariants = [
    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', // AlQuran.cloud general
    'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', // AlQuran.cloud variant for Baqarah, etc.
    'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ', // Fatiha specific
    'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِيمِ',
    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
    'بِسمِ اللَّهِ الرَّحمٰنِ الرَّحيمِ', // IndoPak style
    'بسم الله الرحمن الرحيم',
    '﷽',
  ];

  String _toArabicDigits(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((e) => digits[int.parse(e)]).join('');
  }

  String _extractApiBismillah(String ayah1Text) {
    final cleanText = ayah1Text.cleanArabic.trim();
    for (final variant in _bismillahVariants) {
      final cleanVariant = variant.cleanArabic;
      if (cleanText.startsWith(cleanVariant)) {
        return cleanVariant;
      }
    }
    // Fallback if no exact match found, return most common Uthmani one
    return _bismillahVariants[1].cleanArabic;
  }

  String _stripApiBismillah(String text) {
    final cleanText = text.cleanArabic.trim();
    for (final variant in _bismillahVariants) {
      final cleanVariant = variant.cleanArabic;
      if (cleanText.startsWith(cleanVariant)) {
        return cleanText.substring(cleanVariant.length).trimLeft();
      }
    }
    
    // Robust regex fallback - clean the string so it matches cleanText perfectly
    final baseRegexStr = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'.cleanArabic;
    final regexStr = '^' + baseRegexStr.split(' ').join(r'\s+') + r'\s*';
    final regex = RegExp(regexStr, caseSensitive: false);
    
    final match = regex.firstMatch(cleanText);
    if (match != null) {
      return cleanText.substring(match.end).trimLeft();
    }
    
    // If not found, return text as is
    return cleanText;
  }

  @override
  Widget build(BuildContext context) {
    if (surah.number == 1) {
      return _buildFatihaLayout();
    }

    final ayahs = surah.ayahs;
    if (ayahs == null || ayahs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No ayah data found for this Surah.'),
        ),
      );
    }
    
    // Extract the Bismillah directly from the API for this specific Surah
    String apiBismillahToDisplay = '';
    if (surah.number != 9 && surah.number != 1) {
       final firstAyah = ayahs.firstWhere((a) => a.numberInSurah == 1, orElse: () => ayahs.first);
       apiBismillahToDisplay = _extractApiBismillah(firstAyah.text);
    }

    // Group ayahs by page number
    final Map<int, List<Ayah>> pageMap = {};
    for (final ayah in ayahs) {
      pageMap.putIfAbsent(ayah.page, () => []).add(ayah);
    }
    final sortedPages = pageMap.keys.toList()..sort();

    return Column(
      children: [
        _buildSurahHeader(),
        if (apiBismillahToDisplay.isNotEmpty) _buildApiBasmallah(apiBismillahToDisplay),
        ...sortedPages.map((pageNum) {
          return _buildMushafPage(pageMap[pageNum]!, pageNum);
        }),
      ],
    );
  }

  Widget _buildSurahHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1B5E20), width: 1),
      ),
      child: Text(
        'surah${surah.number.toString().padLeft(3, '0')}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'surah-name-v2-icon',
          fontSize: 40,
          color: Color(0xFF1B5E20),
          fontFeatures: [FontFeature.enable('liga')],
        ),
      ),
    );
  }

  Widget _buildApiBasmallah(String bismillahText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 16, right: 16),
      child: Text(
        bismillahText,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'UthmanicHafs',
          fontSize: 24,
          color: Color(0xFF1B5E20),
        ),
      ),
    );
  }

  Widget _buildFatihaLayout() {
    return Column(
      children: [
        _buildSurahHeader(),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFDF6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E5D1), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '— 1 —',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ...[
                "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١",
                "ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ ٢",
                "ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ٣ مَٰلِكِ يَوۡمِ ٱلدِّينِ ٤",
                "إِيَّاكَ نَعۡبُدُ وَإِيَّاكَ نَسۡتَعِينُ ٥",
                "ٱهۡدِنَا ٱلصِّرَٰطَ ٱلۡمُسۡتَقِيمَ ٦",
                "صِرَٰطَ ٱلَّذِينَ أَنۡعَمۡتَ عَلَيۡهِمۡ",
                "غَيۡرِ ٱلۡمَغۡضُوبِ عَلَيۡهِمۡ وَلَا ٱلضَّآلِّينَ ٧",
              ].map((lineText) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  lineText,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 26,
                    height: 2.0,
                    color: Colors.black87,
                    wordSpacing: 2,
                  ),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMushafPage(List<Ayah> pageAyahs, int pageNumber) {
    final buffer = StringBuffer();
    for (var i = 0; i < pageAyahs.length; i++) {
      var text = pageAyahs[i].text.cleanArabic.trim();
      
      // Strip leading Bismillah from Ayah 1 for any Surah (except Fatiha and Tawbah)
      if (pageAyahs[i].numberInSurah == 1 && surah.number != 9 && surah.number != 1) {
        text = _stripApiBismillah(text);
      }
      
      if (text.isEmpty) continue;
      
      // Append formatted Arabic Ayah number
      text = '$text ${_toArabicDigits(pageAyahs[i].numberInSurah)}';
      
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(text);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDF6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E5D1), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '— $pageNumber —',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            buffer.toString(),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 26,
              height: 2.0,
              color: Colors.black87,
              wordSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
