import 'package:flutter/material.dart';
import '../../models/ayah.dart';
import '../../models/reading_mode.dart';
import '../../services/tajweed_service.dart';

/// Word-by-Word Ayah Widget
/// Bilkul waise jaisa image mein hai:
/// - Arabic word (bara)
/// - Transliteration (colored)
/// - Urdu/English translation (neeche)
/// - Tajweed colors optional
class WordByWordAyahWidget extends StatelessWidget {
  final Ayah ayah;
  final int surahNumber;
  final ReadingPreferences preferences;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;

  const WordByWordAyahWidget({
    super.key,
    required this.ayah,
    required this.surahNumber,
    required this.preferences,
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  // Har word ko ek rng — cycle karta rahe (image jaise)
  static const List<Color> _wordColors = [
    Color(0xFF1565C0), // Blue
    Color(0xFFB71C1C), // Red
    Color(0xFF1B5E20), // Green
    Color(0xFF6A1B9A), // Purple
    Color(0xFFE65100), // Orange
    Color(0xFF00695C), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    final words = ayah.ayahWords;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Top Row: Ayah number + Bookmark ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _AyahBadge(number: ayah.numberInSurah),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? const Color(0xFF1B5E20) : Colors.grey,
                    size: 20,
                  ),
                  onPressed: onBookmarkToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),

          // ─── Word-by-Word Grid (RTL) ───────────
          if (words != null && words.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _WordByWordGrid(
                words: words,
                preferences: preferences,
                wordColors: _wordColors,
              ),
            )
          else
          // Fallback: full Arabic text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                ayah.text,
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: preferences.arabicFontSize,
                  height: 2.0,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),

          // ─── Full Translation at bottom ────────
          if (ayah.translation != null && ayah.translation!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FBE7),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                '(${ayah.numberInSurah}) ${ayah.translation!}',
                style: TextStyle(
                  fontSize: preferences.translationFontSize,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Word Grid — image jaise layout ─────────────────────────
class _WordByWordGrid extends StatelessWidget {
  final List<AyahWord> words;
  final ReadingPreferences preferences;
  final List<Color> wordColors;

  const _WordByWordGrid({
    required this.words,
    required this.preferences,
    required this.wordColors,
  });

  @override
  Widget build(BuildContext context) {
    // RTL direction mein words ko wrap karo
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        direction: Axis.horizontal,
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 16,
        children: List.generate(words.length, (index) {
          final word = words[index];
          final color = wordColors[index % wordColors.length];

          return _WordCard(
            word: word,
            color: color,
            arabicFontSize: preferences.arabicFontSize,
            translationFontSize: preferences.translationFontSize,
            showTransliteration: preferences.showTransliteration,
            showTajweed: preferences.showTajweed,
          );
        }),
      ),
    );
  }
}

// ─── Single Word Card ────────────────────────────────────────
class _WordCard extends StatelessWidget {
  final AyahWord word;
  final Color color;
  final double arabicFontSize;
  final double translationFontSize;
  final bool showTransliteration;
  final bool showTajweed;

  const _WordCard({
    required this.word,
    required this.color,
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.showTransliteration,
    required this.showTajweed,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Arabic word — Tajweed colors ya single color
          if (showTajweed && word.tajweedSegments != null && word.tajweedSegments!.isNotEmpty)
            RichText(
              textDirection: TextDirection.rtl,
              text: TextSpan(
                children: word.tajweedSegments!.map((seg) {
                  return TextSpan(
                    text: seg.text,
                    style: TextStyle(
                      color: TajweedService.getTajweedColor(seg.rule),
                      fontSize: arabicFontSize,
                      fontFamily: 'AmiriQuran',
                      height: 1.8,
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Text(
              word.arabic,
              style: TextStyle(
                color: color,
                fontSize: arabicFontSize,
                fontFamily: 'AmiriQuran',
                height: 1.8,
              ),
              textDirection: TextDirection.rtl,
            ),

          // Transliteration (colored same as Arabic)
          if (showTransliteration && word.transliteration != null)
            Text(
              word.transliteration!,
              style: TextStyle(
                color: color,
                fontSize: translationFontSize - 1,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

          // Word-level Urdu/English translation
          if (word.translation != null && word.translation!.isNotEmpty)
            Text(
              word.translation!,
              style: TextStyle(
                color: Colors.black54,
                fontSize: translationFontSize - 2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

// ─── Ayah Number Badge ───────────────────────────────────────
class _AyahBadge extends StatelessWidget {
  final int number;

  const _AyahBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '($number)',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}