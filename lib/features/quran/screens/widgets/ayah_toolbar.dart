import 'package:flutter/material.dart';
import '../../models/ayah.dart';
import '../../services/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AyahToolbar extends StatelessWidget {
  final Ayah ayah;
  final int surahNumber;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onTafseerTap;

  const AyahToolbar({
    super.key,
    required this.ayah,
    required this.surahNumber,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onTafseerTap,
  });

  @override
  Widget build(BuildContext context) {
    final audioService = QuranAudioService();
    final translationAudioUrl = audioService.getTranslationAudioUrl(ayah.number);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _AyahBadge(number: ayah.numberInSurah),
          const Spacer(),
          // Unified Audio Play Buttons
          StreamBuilder<PlayerState>(
            stream: audioService.ayahPlayerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;

              final isMyArabic = audioService.currentAyahNumber == ayah.number;
              final isMyTranslation = audioService.currentAyahUrl == translationAudioUrl;

              final isArabicLoading = isMyArabic && (processingState == ProcessingState.loading || processingState == ProcessingState.buffering);
              final isTranslationLoading = isMyTranslation && (processingState == ProcessingState.loading || processingState == ProcessingState.buffering);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isArabicLoading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5E20)),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            isMyArabic && playing == true ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: isMyArabic && playing == true ? Colors.amber[800] : Colors.blueGrey,
                            size: 28,
                          ),
                          tooltip: 'Play Arabic',
                          onPressed: () {
                            if (isMyArabic && playing == true) {
                              audioService.pauseAyah();
                            } else {
                              audioService.playAyah(ayahNumber: ayah.number, surahNumber: surahNumber, ayahInSurah: ayah.numberInSurah);
                            }
                          },
                        ),
                  isTranslationLoading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueGrey),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            isMyTranslation && playing == true ? Icons.pause_circle_filled : Icons.translate,
                            color: isMyTranslation && playing == true ? Colors.amber[800] : Colors.blueGrey,
                            size: 24,
                          ),
                          tooltip: 'Play Urdu Translation',
                          onPressed: () {
                            if (isMyTranslation && playing == true) {
                              audioService.pauseAyah();
                            } else {
                              audioService.playAyah(url: translationAudioUrl);
                            }
                          },
                        ),
                ],
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
        color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
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
