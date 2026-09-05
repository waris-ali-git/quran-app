import 'package:flutter/material.dart';
import '../../models/translation_audio_edition.dart';
import '../../services/verse_by_verse_controller.dart';
import '../../services/audio_service.dart';
import 'reciter_selection_sheet.dart';

/// Bottom sheet to configure verse-by-verse sequential playback.
/// Allows toggling each step and selecting translation audio edition.
class VersePlaybackSettingsSheet extends StatefulWidget {
  final VerseByVerseConfig initialConfig;
  final void Function(VerseByVerseConfig config) onConfigChanged;

  const VersePlaybackSettingsSheet({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
  });

  @override
  State<VersePlaybackSettingsSheet> createState() => _VersePlaybackSettingsSheetState();
}

class _VersePlaybackSettingsSheetState extends State<VersePlaybackSettingsSheet> {
  late VerseByVerseConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  void _update(VerseByVerseConfig updated) {
    setState(() => _config = updated);
    widget.onConfigChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF90BDE7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.queue_music_rounded, color: Color(0xFF90BDE7), size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verse-by-Verse Settings',
                        style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Configure sequential playback',
                        style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.black12, height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Step Toggles ───────────────────────
                  _SectionHeader(title: 'Playback Steps'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const ReciterSelectionSheet(),
                      );
                      // After reciter might be changed globally
                      _update(_config.copyWith(reciter: QuranAudioService().selectedReciter));
                    },
                    child: _StepToggle(
                      icon: Icons.record_voice_over_rounded,
                      label: 'Recitation',
                      subtitle: _config.reciter.name,
                      value: _config.playRecitation,
                      onChanged: (v) => _update(_config.copyWith(playRecitation: v)),
                      accentColor: const Color(0xFF90BDE7),
                      isTappable: true,
                    ),
                  ),
                  _StepToggle(
                    icon: Icons.menu_book_rounded,
                    label: 'Tafseer Audio',
                    subtitle: 'Tafsir Ibn Kathir Audio',
                    value: _config.playTafseer,
                    onChanged: (v) => _update(_config.copyWith(playTafseer: v)),
                    accentColor: const Color(0xFF7C4DFF),
                  ),
                  _StepToggle(
                    icon: Icons.translate_rounded,
                    label: 'Translation Audio',
                    subtitle: '${_config.translationEdition.flagEmoji} ${_config.translationEdition.translatorName}',
                    value: _config.playTranslation,
                    onChanged: (v) => _update(_config.copyWith(playTranslation: v)),
                    accentColor: const Color(0xFF4CAF50),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.black12, height: 1),
                  const SizedBox(height: 12),

                  // ─── Translation Audio Selection ─────────
                  _SectionHeader(title: 'Translation Audio'),
                  const SizedBox(height: 8),
                  ...TranslationAudioEdition.availableEditions.map((edition) {
                    final isSelected = _config.translationEdition.id == edition.id;
                    return _EditionTile(
                      edition: edition,
                      isSelected: isSelected,
                      onTap: () => _update(_config.copyWith(translationEdition: edition)),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Done button
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF90BDE7),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF90BDE7),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _StepToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;
  final bool isTappable;

  const _StepToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    this.isTappable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value ? accentColor.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? accentColor.withValues(alpha: 0.3) : Colors.black12,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        secondary: Icon(icon, color: value ? accentColor : Colors.black38, size: 22),
        title: Row(
          children: [
            Text(label, style: TextStyle(color: value ? Colors.black87 : Colors.black54, fontSize: 14)),
            if (isTappable) ...[
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded, size: 14, color: Colors.black38),
            ]
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.black38, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: accentColor,
        inactiveThumbColor: Colors.black26,
        inactiveTrackColor: Colors.black12,
      ),
    );
  }
}

class _EditionTile extends StatelessWidget {
  final TranslationAudioEdition edition;
  final bool isSelected;
  final VoidCallback onTap;

  const _EditionTile({required this.edition, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF90BDE7).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF90BDE7).withValues(alpha: 0.6) : Colors.black12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(edition.flagEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    edition.languageLabel,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF90BDE7) : Colors.black87,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    edition.readerName,
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF90BDE7), size: 18),
          ],
        ),
      ),
    );
  }
}
