import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/ayah.dart';
import '../../models/reading_mode.dart';
import '../../services/tajweed_service.dart';
import '../../state/quran_bloc.dart';
import '../../../../shared/icons/icomoon.dart';
import '../../../../shared/icons/custom_icons_v2.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/widgets/translated_text.dart';
import '../widgets/reciter_selection_sheet.dart';
import '../reader_screen.dart';
import '../translation_selection_screen.dart';

/// Tajweed Mode Ayah Widget
class TajweedAyahWidget extends StatelessWidget {
  final Ayah ayah;
  final int surahNumber;
  final ReadingPreferences preferences;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onVisible;
  final VoidCallback onTafseerTap;
  final VoidCallback? onVbVPlay;
  final VoidCallback? onVbVPause;
  final bool isVbVActive;
  final bool isVbVPlaying;
  final VoidCallback? onReciterChanged;

  const TajweedAyahWidget({
    super.key,
    required this.ayah,
    required this.surahNumber,
    required this.preferences,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    this.onVisible,
    required this.onTafseerTap,
    this.onVbVPlay,
    this.onVbVPause,
    this.isVbVActive = false,
    this.isVbVPlaying = false,
    this.onReciterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final allSegments = _buildTajweedSegments();

    String? translationText = ayah.translation;
    if (ayah.numberInSurah == 1 && surahNumber != 1 && surahNumber != 9 && translationText != null && translationText.isNotEmpty) {
      translationText = cleanBismillahTranslation(translationText);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isVbVActive ? const Color(0xFFEBF4FD) : Colors.white,
        border: Border(
          bottom: const BorderSide(color: Color(0xFFEEEEEE)),
          left: isVbVActive
              ? const BorderSide(color: Color(0xFF90BDE7), width: 4)
              : BorderSide.none,
        ),
        boxShadow: isVbVActive
            ? [const BoxShadow(color: Color(0x2290BDE7), blurRadius: 8, offset: Offset(2, 0))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  '$surahNumber:${ayah.numberInSurah}',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    if (isVbVActive && isVbVPlaying) {
                      onVbVPause?.call();
                    } else {
                      onVbVPlay?.call();
                    }
                  },
                  child: Icon(
                    isVbVActive && isVbVPlaying ? Icons.pause : Icons.play_arrow_outlined,
                    color: isVbVActive ? const Color(0xFF90BDE7) : Colors.grey,
                    size: 24,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await showReciterSelectionSheet(context);
                    onReciterChanged?.call();
                  },
                  child: const Icon(Icomoon.reciter, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 16),
                GestureDetector(onTap: onBookmarkToggle, child: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.grey, size: 20)),
              ],
            ),
          ),

          // Colored Tajweed Arabic text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  text: TextSpan(
                    children: ayah.tajweedText != null
                        ? TajweedService.parseTajweedTextToSpans(
                            ayah.tajweedText!,
                            preferences.arabicFontSize,
                            'TajweedFont',
                          )
                        : allSegments.map((seg) {
                            return TextSpan(
                              text: seg.text,
                              style: TextStyle(
                                color: TajweedService.getTajweedColor(seg.rule),
                                fontSize: preferences.arabicFontSize,
                                fontFamily: 'TajweedFont',
                                height: 2.0,
                              ),
                            );
                          }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Tajweed controls row — palette (toggle OFF) + legend (show list)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Palette icon — tap to turn tajweed OFF
                    GestureDetector(
                      onTap: () {
                        if (preferences.showTajweed) {
                          context.read<QuranBloc>().add(const ToggleTajweedEvent());
                        }
                        if (preferences.displayMode == ReadingDisplayMode.tajweed) {
                          context.read<QuranBloc>().add(const ChangeReadingModeEvent(
                            mode: ReadingDisplayMode.arabicWithTranslation,
                          ));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF90BDE7),
                        ),
                        child: const Icon(
                          Icons.palette,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Legend icon — tap to show color guide
                    GestureDetector(
                      onTap: () => showTajweedLegendDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF90BDE7).withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.format_list_bulleted,
                          size: 16,
                          color: Color(0xFF90BDE7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transliteration
          if (preferences.showTransliteration && ayah.transliteration != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
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
          if (translationText != null && translationText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                translationText,
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

          // Bottom Toolbar: Translations & Tafsirs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) => BlocProvider.value(
                        value: context.read<QuranBloc>(),
                        child: const TranslationSelectionScreen(),
                      ),
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
                const SizedBox(width: 24),
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

  List<TajweedSegment> _buildTajweedSegments() {
    final words = ayah.ayahWords;
    if (words == null || words.isEmpty) {
      return [TajweedSegment(text: ayah.text.cleanArabic, rule: TajweedRule.none)];
    }

    final segments = <TajweedSegment>[];
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.tajweedSegments != null && word.tajweedSegments!.isNotEmpty) {
        segments.addAll(word.tajweedSegments!);
      } else {
        segments.add(TajweedSegment(text: word.arabic.cleanArabic, rule: TajweedRule.none));
      }
      if (i < words.length - 1) {
        segments.add(const TajweedSegment(text: ' ', rule: TajweedRule.none));
      }
    }
    return segments;
  }
}

// ─────────────────────────────────────────────
// PUBLIC: Show Tajweed Legend Dialog
// ─────────────────────────────────────────────
void showTajweedLegendDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tajweed Legend',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim1, anim2) {
      return const Align(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: TajweedLegendDialogWidget(),
        ),
      );
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────
// TAJWEED LEGEND DIALOG WIDGET (public, reusable)
// ─────────────────────────────────────────────
class TajweedLegendDialogWidget extends StatelessWidget {
  const TajweedLegendDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final rules = TajweedService.getAllRules()
        .where((r) => r != TajweedRule.none)
        .toList();

    return LiquidGlassContainer(
      width: 270,
      height: 410,
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF90BDE7).withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.palette, color: Color(0xFF90BDE7), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TranslatedText(
                  'Tajweed Color Guide',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.black45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 8),
          // ── Scrollable color rows ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: rules.map((rule) => _TajweedRow(rule: rule)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TajweedRow extends StatelessWidget {
  final TajweedRule rule;
  const _TajweedRow({required this.rule});

  @override
  Widget build(BuildContext context) {
    final color = TajweedService.getTajweedColor(rule);
    final nameEn = TajweedService.getTajweedRuleNameEnglish(rule);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Color swatch
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // English rule name (translatable)
          Expanded(
            child: TranslatedText(
              nameEn,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1C1C1E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Arabic sample in rule color
          Text(
            'نَ',
            style: TextStyle(
              fontFamily: 'TajweedFont',
              fontSize: 18,
              color: color,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAJWEED LEGEND WIDGET (legacy inline widget)
// ─────────────────────────────────────────────
class TajweedLegendWidget extends StatelessWidget {
  const TajweedLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const TajweedLegendDialogWidget();
  }
}
