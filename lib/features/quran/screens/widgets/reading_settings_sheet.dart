import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../state/quran_bloc.dart';
import '../../models/reading_mode.dart';
import '../widgets/tajweed_ayah.dart';

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

                    const Text(
                      'پڑھنے کی ترتیبات',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),

                    // ─── Reading Mode ───────────────────────
                    const _SectionTitle(title: 'پڑھنے کا طریقہ'),
                    const SizedBox(height: 8),
                    _ReadingModeSelector(
                      current: prefs.displayMode,
                      onChanged: (mode) {
                        context.read<QuranBloc>().add(ChangeReadingModeEvent(mode: mode));
                        onModeChanged?.call(mode);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 24),

                    // ─── Tajweed Toggle ─────────────────────
                    _ToggleTile(
                      icon: Icons.palette,
                      title: 'تجوید رنگ',
                      subtitle: 'تجوید قواعد رنگوں سے دکھائیں',
                      value: prefs.showTajweed,
                      onChanged: (_) {
                        context.read<QuranBloc>().add(const ToggleTajweedEvent());
                      },
                    ),

                    // ─── Transliteration Toggle ─────────────
                    _ToggleTile(
                      icon: Icons.translate,
                      title: 'تلفظ (Transliteration)',
                      subtitle: 'رومن اردو میں تلفظ دکھائیں',
                      value: prefs.showTransliteration,
                      onChanged: (_) {
                        context.read<QuranBloc>().add(const ToggleTransliterationEvent());
                      },
                    ),
                    const Divider(height: 24),

                    // ─── Arabic Font Size ───────────────────
                    const _SectionTitle(title: 'عربی فونٹ کا سائز'),
                    _FontSizeSlider(
                      label: 'عربی',
                      value: prefs.arabicFontSize,
                      min: 18,
                      max: 42,
                      previewText: 'بِسۡمِ اللّٰہِ',
                      previewFontFamily: 'AmiriQuran',
                      onChanged: (val) {
                        context.read<QuranBloc>().add(ChangeFontSizeEvent(
                          arabicSize: val,
                          translationSize: prefs.translationFontSize,
                        ));
                      },
                    ),
                    const SizedBox(height: 12),

                    // ─── Translation Font Size ──────────────
                    const _SectionTitle(title: 'ترجمے کا فونٹ سائز'),
                    _FontSizeSlider(
                      label: 'ترجمہ',
                      value: prefs.translationFontSize,
                      min: 12,
                      max: 24,
                      previewText: 'اللہ کے نام سے',
                      previewFontFamily: null,
                      onChanged: (val) {
                        context.read<QuranBloc>().add(ChangeFontSizeEvent(
                          arabicSize: prefs.arabicFontSize,
                          translationSize: val,
                        ));
                      },
                    ),
                    const Divider(height: 24),

                    // ─── Translation Language ───────────────
                    const _SectionTitle(title: 'ترجمے کی زبان'),
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

                    // ─── Tajweed Legend ─────────────────────
                    if (prefs.showTajweed ||
                        prefs.displayMode == ReadingDisplayMode.tajweed) ...[
                      const _SectionTitle(title: 'تجوید رنگوں کی فہرست'),
                      const SizedBox(height: 8),
                      const TajweedLegendWidget(),
                    ],

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
      (ReadingDisplayMode.arabicWithTranslation, Icons.menu_book, 'عربی + ترجمہ', 'آیت کے نیچے ترجمہ'),
      (ReadingDisplayMode.wordByWord, Icons.text_fields, 'لفظ بہ لفظ', 'ہر لفظ کے نیچے ترجمہ'),
      (ReadingDisplayMode.tajweed, Icons.palette, 'تجوید رنگ', 'رنگوں سے تجوید'),
      (ReadingDisplayMode.arabicOnly, Icons.text_format, 'صرف عربی', 'صرف عربی متن'),
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
                color: isSelected ? const Color(0xFF1B5E20) : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  m.$2,
                  color: isSelected ? const Color(0xFF1B5E20) : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.$3,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
                        ),
                      ),
                      Text(
                        m.$4,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFF1B5E20)),
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
            Text('$label: ${value.toInt()}pt'),
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
          activeColor: const Color(0xFF1B5E20),
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
    return DropdownButtonFormField<String>(
      value: current,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: kAvailableTranslations
          .map((t) => DropdownMenuItem(
        value: t.edition,
        child: Text(t.displayName),
      ))
          .toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
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

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1B5E20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1B5E20),
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
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }
}