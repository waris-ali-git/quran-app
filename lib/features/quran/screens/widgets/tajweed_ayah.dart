import 'package:flutter/material.dart';
import '../../models/ayah.dart';
import '../../models/reading_mode.dart';
import '../../services/tajweed_service.dart';
import '../../services/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Tajweed Mode Ayah Widget
/// Arabic text mein Tajweed rules ke colors apply hote hain
/// Har rule ka alag color hai, neeche legend bhi show karta hai
class TajweedAyahWidget extends StatelessWidget {
  final Ayah ayah;
  final int surahNumber;
  final ReadingPreferences preferences;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onVisible;
  final VoidCallback onTafseerTap;

  const TajweedAyahWidget({
    super.key,
    required this.ayah,
    required this.surahNumber,
    required this.preferences,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    this.onVisible,
    required this.onTafseerTap,
  });

  @override
  Widget build(BuildContext context) {
    // Tajweed segments banao — API se ya word-level se
    final allSegments = _buildTajweedSegments();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ayah number + bookmark
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _AyahBadge(number: ayah.numberInSurah),
                const Spacer(),
                // Audio Play Button
                StreamBuilder<PlayerState>(
                  stream: QuranAudioService().playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;
                    
                    final currentUrl = QuranAudioService().currentUrl;
                    final isMyAyah = currentUrl == ayah.audioUrl;

                    if (isMyAyah && (processingState == ProcessingState.loading || processingState == ProcessingState.buffering)) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    return IconButton(
                      icon: Icon(
                        isMyAyah && playing == true ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: isMyAyah && playing == true ? Colors.amber[800] : Colors.blueGrey,
                        size: 28,
                      ),
                      onPressed: () {
                        if (ayah.audioUrl != null) {
                          if (isMyAyah && playing == true) {
                            QuranAudioService().pause();
                          } else {
                            QuranAudioService().playAyah(ayah.audioUrl!);
                          }
                        }
                      },
                    );
                  },
                ),
                // Tafseer Button
                IconButton(
                  icon: const Icon(Icons.menu_book, color: Colors.blueGrey, size: 24),
                  onPressed: onTafseerTap,
                  tooltip: 'Tafseer',
                ),
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

          // Colored Tajweed Arabic text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: RichText(
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              text: TextSpan(
                children: ayah.tajweedText != null
                    ? TajweedService.parseTajweedTextToSpans(
                        ayah.tajweedText!,
                        preferences.arabicFontSize,
                        'AmiriQuran',
                      )
                    : allSegments.map((seg) {
                        return TextSpan(
                          text: seg.text,
                          style: TextStyle(
                            color: TajweedService.getTajweedColor(seg.rule),
                            fontSize: preferences.arabicFontSize,
                            fontFamily: 'AmiriQuran',
                            height: 2.0,
                          ),
                        );
                      }).toList(),
              ),
            ),
          ),

          // Transliteration
          if (preferences.showTransliteration && ayah.transliteration != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                ayah.transliteration!,
                style: TextStyle(
                  fontSize: preferences.translationFontSize - 2,
                  color: Colors.blueGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Translation
          if (ayah.translation != null && ayah.translation!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F8E9),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                ayah.translation!,
                style: TextStyle(
                  fontSize: preferences.translationFontSize,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Words ke Tajweed segments combine karo ek list mein
  List<TajweedSegment> _buildTajweedSegments() {
    final words = ayah.ayahWords;
    if (words == null || words.isEmpty) {
      // Fallback: pure text ko single segment banana
      return [TajweedSegment(text: ayah.text, rule: TajweedRule.none)];
    }

    final segments = <TajweedSegment>[];
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.tajweedSegments != null && word.tajweedSegments!.isNotEmpty) {
        segments.addAll(word.tajweedSegments!);
      } else {
        segments.add(TajweedSegment(text: word.arabic, rule: TajweedRule.none));
      }
      // Words ke beech space add karo (last word ke baad nahi)
      if (i < words.length - 1) {
        segments.add(const TajweedSegment(text: ' ', rule: TajweedRule.none));
      }
    }
    return segments;
  }
}

// ─────────────────────────────────────────────
// TAJWEED LEGEND WIDGET (Screen pe show karo)
// ─────────────────────────────────────────────

class TajweedLegendWidget extends StatelessWidget {
  const TajweedLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final rules = TajweedService.getAllRules();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تجوید رنگوں کی علامت',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: rules
                .where((r) => r != TajweedRule.none)
                .map((rule) => _LegendItem(rule: rule))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final TajweedRule rule;

  const _LegendItem({required this.rule});

  @override
  Widget build(BuildContext context) {
    final color = TajweedService.getTajweedColor(rule);
    final nameUrdu = TajweedService.getTajweedRuleNameUrdu(rule);
    final nameEn = TajweedService.getTajweedRuleNameEnglish(rule);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          nameUrdu.isNotEmpty ? '$nameUrdu ($nameEn)' : nameEn,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _AyahBadge extends StatelessWidget {
  final int number;

  const _AyahBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1B5E20)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '($number)',
        style: const TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}