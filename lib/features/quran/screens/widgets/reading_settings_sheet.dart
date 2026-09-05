import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../state/quran_bloc.dart';
import '../../models/reading_mode.dart';
import '../translation_selection_screen.dart';
import '../widgets/tajweed_ayah.dart';
import '../../../../core/widgets/translated_text.dart';
import 'wbw_language_selector.dart';
import '../../../../shared/icons/icomoon.dart';
import '../../../../shared/icons/custom_icons_v2.dart';

/// Reading Settings Bottom Sheet
/// - Reading mode select karo
/// - Font size adjust karo
/// - Transliteration on/off
/// - Tajweed on/off
/// - Translation language change karo
class ReadingSettingsSheet extends StatelessWidget {
  final ValueChanged<ReadingDisplayMode>? onModeChanged;

  const ReadingSettingsSheet({super.key, this.onModeChanged});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranBloc, QuranState>(
      builder: (context, state) {
        ReadingPreferences prefs = const ReadingPreferences();

        if (state is SurahLoaded) prefs = state.preferences;
        if (state is SurahWordByWordLoaded) prefs = state.preferences;

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const TranslatedText(
                      'Reading Settings',
                      style: TextStyle(fontFamily: 'Jameel Noori', fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),

                    // ─── Reading Mode ───────────────────────
                    const _SectionTitle(title: 'Reading Mode'),
                    const SizedBox(height: 8),
                    _ReadingModeSelector(
                      current: prefs.displayMode,
                      onChanged: (mode) {
                        if (mode == ReadingDisplayMode.wordByWord) {
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
                                    child: WbwLanguageSelector(onModeChanged: onModeChanged),
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
                        } else {
                          context.read<QuranBloc>().add(ChangeReadingModeEvent(mode: mode));
                          onModeChanged?.call(mode);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const Divider(height: 24),

                    // ─── Tajweed Toggle ─────────────────────
                    _ToggleTile(
                      icon: Icons.palette,
                      title: 'Tajweed Color',
                      subtitle: 'Show tajweed rules with colors',
                      value: prefs.showTajweed,
                      onChanged: (_) {
                        context.read<QuranBloc>().add(const ToggleTajweedEvent());
                      },
                      onInfoTap: prefs.showTajweed
                          ? () => showTajweedLegendDialog(context)
                          : null,
                    ),

                    // ─── Transliteration Toggle ─────────────
                    _ToggleTile(
                      icon: CustomIconsV2.translation,
                      title: 'Transliteration',
                      subtitle: 'Show pronunciation in English/Roman',
                      value: prefs.showTransliteration,
                      onChanged: (_) {
                        context.read<QuranBloc>().add(const ToggleTransliterationEvent());
                      },
                    ),
                    const Divider(height: 24),

                    // ─── Arabic Font Size ───────────────────
                    const _SectionTitle(title: 'Arabic Font Size'),
                    _FontSizeSlider(
                      label: 'Arabic',
                      value: prefs.arabicFontSize,
                      min: 18,
                      max: 42,
                      previewText: 'بِسمِ اللّٰه',
                      previewFontFamily: 'DigitalKhatt',
                      onChanged: (val) {
                        context.read<QuranBloc>().add(ChangeFontSizeEvent(
                          arabicSize: val,
                          translationSize: prefs.translationFontSize,
                        ));
                      },
                    ),
                    const SizedBox(height: 12),

                    // ─── Translation Font Size ──────────────
                    const _SectionTitle(title: 'Translation Font Size'),
                    _FontSizeSlider(
                      label: 'Translation',
                      value: prefs.translationFontSize,
                      min: 12,
                      max: 24,
                      previewText: 'اللہ کے نام سے',
                      previewFontFamily: 'Jameel Noori',
                      onChanged: (val) {
                        context.read<QuranBloc>().add(ChangeFontSizeEvent(
                          arabicSize: prefs.arabicFontSize,
                          translationSize: val,
                        ));
                      },
                    ),
                    const Divider(height: 24),

                    // ─── Translation Language ───────────────
                    const _SectionTitle(title: 'Translation Language'),
                    const SizedBox(height: 8),
                    _TranslationSelector(
                      current: prefs.selectedTranslation,
                      onChanged: (edition) {
                        context.read<QuranBloc>().add(
                          ChangeTranslationEvent(edition: edition),
                        );
                      },
                    ),
                    const Divider(height: 24),

                    // (Tajweed legend moved to dialog — accessible via palette icon)

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Reading Mode Selector ─────────────────────────────────
class _ReadingModeSelector extends StatelessWidget {
  final ReadingDisplayMode current;
  final ValueChanged<ReadingDisplayMode> onChanged;

  const _ReadingModeSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final modes = [
      (ReadingDisplayMode.arabicWithTranslation, CustomIconsV2.translation, 'Arabic + Translation', 'Translation below ayah'),
      (ReadingDisplayMode.wordByWord, CustomIconsV2.wordByWord, 'Word by Word', 'Translation below each word'),
      (ReadingDisplayMode.tajweed, Icons.palette, 'Tajweed Color', 'Tajweed with colors'),
      (ReadingDisplayMode.arabicOnly, Icomoon.arabicOnly, 'Arabic Only', 'Only Arabic text'),
    ];

    return Column(
      children: modes.map((m) {
        final isSelected = current == m.$1;
        return GestureDetector(
          onTap: () => onChanged(m.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? const Color(0xFF90BDE7) : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  m.$2,
                  color: isSelected ? const Color(0xFF90BDE7) : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        m.$3,
                        style: TextStyle(
                          fontFamily: 'Jameel Noori',
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF90BDE7) : Colors.black87,
                        ),
                      ),
                      TranslatedText(
                        m.$4,
                        style: TextStyle(fontFamily: 'Jameel Noori', fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFF90BDE7)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Font Size Slider ─────────────────────────────────────
class _FontSizeSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String previewText;
  final String? previewFontFamily;
  final ValueChanged<double> onChanged;

  const _FontSizeSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.previewText,
    required this.previewFontFamily,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TranslatedText('$label: ${value.toInt()}pt'),
            const Spacer(),
            Text(
              previewText,
              style: TextStyle(
                fontSize: value.clamp(14, 30),
                fontFamily: previewFontFamily,
              ),
              textDirection: previewFontFamily != null ? TextDirection.rtl : null,
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / 2).round(),
          activeColor: const Color(0xFF90BDE7),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─── Translation Selector ─────────────────────────────────
class _TranslationSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _TranslationSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranBloc, QuranState>(
      builder: (context, state) {
        final bloc = context.read<QuranBloc>();
        final translations = bloc.availableTranslations;
        
        String displayName = current;
        if (translations.isNotEmpty) {
          try {
            final edition = translations.firstWhere((t) => t.identifier == current);
            displayName = edition.englishName;
          } catch (_) {}
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TranslationSelectionScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TranslatedText(
                    displayName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Toggle Tile ─────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onInfoTap;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF90BDE7)),
      title: TranslatedText(title, style: const TextStyle(fontFamily: 'Jameel Noori', fontWeight: FontWeight.w500)),
      subtitle: TranslatedText(subtitle, style: const TextStyle(fontFamily: 'Jameel Noori', fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info icon — only when tajweed is ON
          if (onInfoTap != null) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                key: const ValueKey('info_icon'),
                onTap: onInfoTap,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF90BDE7).withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.format_list_bulleted,
                    size: 18,
                    color: Color(0xFF90BDE7),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF90BDE7),
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ─── Section Title ───────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return TranslatedText(
      title,
      style: const TextStyle(
        fontFamily: 'Jameel Noori',
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }
}