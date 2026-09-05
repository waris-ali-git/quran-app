import 'package:flutter/material.dart';
import '../../models/ayah.dart';
import '../../models/reading_mode.dart';
import '../../services/tajweed_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/audio_service.dart';
import '../../state/quran_bloc.dart';
import '../../../../shared/icons/icomoon.dart';
import '../../../../shared/icons/custom_icons_v2.dart';
import '../widgets/reciter_selection_sheet.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../widgets/wbw_language_selector.dart';

/// Helper to construct standard 4 words of Bismillah if API word data is missing
List<AyahWord> getBismillahWords(String wbwLanguage) {
  final isUrdu = wbwLanguage.startsWith('ur');
  return [
    AyahWord(
      position: 1,
      arabic: 'بِسْمِ',
      transliteration: 'Bism-i',
      translation: isUrdu ? 'شروع' : 'In [the] name',
    ),
    AyahWord(
      position: 2,
      arabic: 'ٱللَّهِ',
      transliteration: 'Allāhi',
      translation: isUrdu ? 'اللہ کے' : '(of) Allah',
    ),
    AyahWord(
      position: 3,
      arabic: 'ٱلرَّحْمَٰنِ',
      transliteration: 'Ar-Raḥmāni',
      translation: isUrdu ? 'جو بے حد مہربان' : 'the Entirely Merciful',
    ),
    AyahWord(
      position: 4,
      arabic: 'ٱلرَّحِيمِ',
      transliteration: 'Ar-Raḥīmi',
      translation: isUrdu ? 'نہایت رحم والا ہے' : 'the Especially Merciful',
    ),
  ];
}

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
  final VoidCallback onTafseerTap;

  const WordByWordAyahWidget({
    super.key,
    required this.ayah,
    required this.surahNumber,
    required this.preferences,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onTafseerTap,
  });

  // Har word ko ek rng — cycle karta rahe (elegant scheme)
  static const List<Color> wordColors = [
    Color(0xFFF06292), // Soft Neon Magenta
    Color(0xFF81C784), // Soft Neon Lime
    Color(0xFFBA68C8), // Soft Plasma Violet
    Color(0xFF64B5F6), // Soft Deep Electric Blue
    Color(0xFFF48FB1), // Soft Hyper Pink
    Color(0xFF4FC3F7), // Soft Cyber Sky
  ];

  @override
  Widget build(BuildContext context) {
    final words = (ayah.ayahWords != null && ayah.ayahWords!.isNotEmpty)
        ? ayah.ayahWords
        : (ayah.numberInSurah == 1 && surahNumber != 9
            ? getBismillahWords(preferences.wbwLanguage)
            : null);
    final audioService = QuranAudioService();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Top Toolbar (matching Verse-by-Verse) ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  '$surahNumber:${ayah.numberInSurah}',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(width: 16),
                StreamBuilder<PlayerState>(
                  stream: audioService.ayahPlayerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing == true;
                    final isMyArabic = audioService.currentAyahNumber == ayah.number;
                    
                    return GestureDetector(
                      onTap: () {
                        if (isMyArabic && playing) {
                          audioService.pauseAyah();
                        } else {
                          audioService.playAyah(
                            ayahNumber: ayah.number,
                            surahNumber: surahNumber,
                            ayahInSurah: ayah.numberInSurah,
                          );
                        }
                      },
                      child: Icon(
                        isMyArabic && playing ? Icons.pause : Icons.play_arrow_outlined,
                        color: Colors.grey,
                        size: 24,
                      ),
                    );
                  },
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    showReciterSelectionSheet(context);
                  },
                  child: const Icon(Icomoon.reciter, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 16),
                GestureDetector(onTap: onBookmarkToggle, child: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.grey, size: 20)),
              ],
            ),
          ),

          // ─── Word-by-Word Grid (RTL) ───────────
          if (words != null && words.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: WordByWordGrid(
                words: words,
                preferences: preferences,
                wordColors: wordColors,
              ),
            )
          else
          // Fallback: full Arabic text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                ayah.text.cleanArabic,
                style: TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontSize: preferences.arabicFontSize,
                  height: 2.0,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),

          // ─── Full Translation at bottom ────────
          if (ayah.translation != null && ayah.translation!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                ayah.translation!,
                textAlign: preferences.selectedTranslation.startsWith('ar') || preferences.selectedTranslation.startsWith('ur') ? TextAlign.right : TextAlign.left,
                textDirection: preferences.selectedTranslation.startsWith('ar') || preferences.selectedTranslation.startsWith('ur') ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                  fontFamily: preferences.selectedTranslation.startsWith('ur') 
                    ? 'Jameel Noori' 
                    : (preferences.selectedTranslation.startsWith('ar') ? 'DigitalKhatt' : null),
                  fontSize: preferences.selectedTranslation.startsWith('ar') 
                    ? preferences.translationFontSize + 4 
                    : preferences.translationFontSize,
                  height: preferences.selectedTranslation.startsWith('ar') ? 2.0 : 1.6,
                  color: Colors.black87,
                ),
              ),
            ),

          // ─── Bottom Toolbar: Tafsirs & Translations ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Wbw Language Selector',
                      barrierColor: Colors.black.withValues(alpha: 0.05),
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) {
                        return Align(
                          alignment: Alignment.center,
                          child: Material(
                            color: Colors.transparent,
                            child: BlocProvider.value(
                              value: context.read<QuranBloc>(),
                              child: const WbwLanguageSelector(),
                            ),
                          ),
                        );
                      },
                      transitionBuilder: (context, anim1, anim2, child) {
                        return FadeTransition(
                          opacity: anim1,
                          child: ScaleTransition(
                            scale: anim1,
                            child: child,
                          ),
                        );
                      },
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CustomIconsV2.translation, color: Colors.grey, size: 18),
                      SizedBox(width: 6),
                      Text('Translations', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onTafseerTap,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icomoon.tafseer, color: Colors.grey, size: 18),
                      SizedBox(width: 6),
                      Text('Tafsirs', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Word Grid — image jaise layout ─────────────────────────
class WordByWordGrid extends StatelessWidget {
  final List<AyahWord> words;
  final ReadingPreferences preferences;
  final List<Color> wordColors;

  const WordByWordGrid({
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
        runSpacing: 24,
        children: List.generate(words.length, (index) {
          final word = words[index];
          final color = wordColors[index % wordColors.length];

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _showTranslationOverlay(
              context, 
              word, 
              details.globalPosition, 
              preferences.wbwLanguage, 
              preferences.translationFontSize
            ),
            child: _WordCard(
              word: word,
              color: color,
              arabicFontSize: preferences.arabicFontSize,
              translationFontSize: preferences.translationFontSize,
              showTransliteration: preferences.showTransliteration,
              showTajweed: preferences.showTajweed,
              wbwLanguage: preferences.wbwLanguage,
            ),
          );
        }),
      ),
    );
  }

  void _showTranslationOverlay(BuildContext context, AyahWord word, Offset globalPosition, String wbwLanguage, double translationFontSize) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => entry?.remove(),
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: globalPosition.dx - 90,
              top: globalPosition.dy - 100,
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
                    );
                  },
                  child: LiquidGlassContainer(
                    width: 180,
                    borderRadius: 16,
                    isTransparent: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          word.translation ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: wbwLanguage.startsWith('ur') ? 'Jameel Noori' : (wbwLanguage.startsWith('ar') ? 'DigitalKhatt' : null),
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (word.transliteration != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            word.transliteration!,
                            style: const TextStyle(
                              color: Color(0xFF90BDE7),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(entry);
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
  final String wbwLanguage;

  const _WordCard({
    required this.word,
    required this.color,
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.showTransliteration,
    required this.showTajweed,
    required this.wbwLanguage,
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
                      fontFamily: 'UthmanicHafs',
                      height: 1.8,
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Text(
              word.arabic.cleanArabic,
              style: TextStyle(
                color: color,
                fontSize: arabicFontSize,
                fontFamily: 'UthmanicHafs',
                height: 1.8,
              ),
              textDirection: TextDirection.rtl,
            ),

          // Transliteration (Golden color)
          if (showTransliteration && word.transliteration != null)
            Text(
              word.transliteration!,
              style: TextStyle(
                color: const Color(0xFF90BDE7), // Golden color defined in app
                fontSize: translationFontSize - 1,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

          // Word Translation (selected wbw language)
          if (word.translation != null && word.translation!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                word.translation!,
                style: TextStyle(
                  fontFamily: wbwLanguage.startsWith('ur')
                      ? 'Jameel Noori'
                      : (wbwLanguage.startsWith('ar') ? 'DigitalKhatt' : null),
                  fontSize: translationFontSize - 2,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                  height: wbwLanguage.startsWith('ur') || wbwLanguage.startsWith('ar') ? 1.6 : 1.3,
                ),
                textAlign: TextAlign.center,
                textDirection: wbwLanguage.startsWith('ur') || wbwLanguage.startsWith('ar')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

        ],
      ),
    );
  }
}