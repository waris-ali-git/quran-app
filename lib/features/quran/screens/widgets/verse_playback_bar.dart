import 'package:flutter/material.dart';
import '../../services/verse_by_verse_controller.dart';
import '../../services/audio_service.dart';
import '../../services/ibn_kathir_audio_data.dart';

/// Floating bottom bar shown during active verse-by-verse playback.
/// Shows current ayah, active step, playback controls, and a theme-styled "Listen Tafseer" button.
class VersePlaybackBar extends StatelessWidget {
  final VerseByVerseController controller;
  final String? surahName;
  final VoidCallback onSettingsTap;
  final VoidCallback onClose;
  final VoidCallback? onBarTap;

  const VersePlaybackBar({
    super.key,
    required this.controller,
    this.surahName,
    required this.onSettingsTap,
    required this.onClose,
    this.onBarTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        if (!state.isActive) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF90BDE7).withValues(alpha: 0.2),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ─── Step Indicator (Responsive) & Listen Tafseer Button ───
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onBarTap,
                          child: _StepIndicator(step: state.step),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ─── Listen Tafseer Button (Blue BG, White Text) ───
                      GestureDetector(
                        onTap: () {
                          final surahNum = state.surahNumber;
                          final url = ibneKathirTafseerAudioUrls[surahNum];
                          if (url != null) {
                            QuranAudioService().playTafseer(
                              url: url,
                              surahName: surahName != null ? 'Surah $surahName' : 'Surah $surahNum',
                              scholarName: 'Tafsir Ibn Kathir',
                              surahNumber: surahNum,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tafseer audio not available for this Surah.')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6FA8D8),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6FA8D8).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.headphones_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Listen Tafseer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ─── Main controls row ──────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onBarTap,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ayah ${state.currentAyahInSurah} of ${state.totalAyahs}',
                                    style: const TextStyle(
                                      color: Color(0xFF6FA8D8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _stepLabel(state.step, controller.config),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Controls
                      GestureDetector(
                        onTap: () => controller.cycleSpeed(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF90BDE7).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF90BDE7).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${state.speed}x',
                            style: const TextStyle(
                              color: Color(0xFF6FA8D8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ControlButton(
                        icon: Icons.skip_previous_rounded,
                        tooltip: 'Previous Ayah',
                        onTap: () => controller.skipToPrev(),
                      ),
                      const SizedBox(width: 4),
                      _PlayPauseButton(
                        isPlaying: state.isPlaying,
                        onTap: () => controller.togglePlayPause(),
                      ),
                      const SizedBox(width: 4),
                      _ControlButton(
                        icon: Icons.skip_next_rounded,
                        tooltip: 'Next Ayah',
                        onTap: () => controller.skipToNext(),
                      ),
                      const SizedBox(width: 4),
                      _ControlButton(
                        icon: Icons.settings_rounded,
                        tooltip: 'Settings',
                        onTap: onSettingsTap,
                      ),
                      const SizedBox(width: 4),
                      _ControlButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        onTap: () {
                          controller.stop();
                          onClose();
                        },
                      ),
                    ],
                  ),
                  
                  // ─── Progress Slider ────────────────────────
                  const SizedBox(height: 4),
                  _AudioProgressSlider(controller: controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _stepLabel(VersePlaybackStep step, VerseByVerseConfig config) {
    switch (step) {
      case VersePlaybackStep.recitation:
        return '🎙️ Recitation — ${config.reciter.name}';
      case VersePlaybackStep.translation:
        return '📖 Translation — ${config.translationEdition.translatorName}';
      case VersePlaybackStep.tafseer:
        return '📚 Tafseer';
      case VersePlaybackStep.idle:
        return 'Starting...';
    }
  }
}

// ─────────────────────────────────────────────
// Step Indicator
// ─────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final VersePlaybackStep step;

  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(
          label: 'Recitation',
          isActive: step == VersePlaybackStep.recitation,
          isPast: step == VersePlaybackStep.translation,
        ),
        Expanded(
          child: _StepLine(active: step == VersePlaybackStep.translation),
        ),
        _StepDot(
          label: 'Translation',
          isActive: step == VersePlaybackStep.translation,
          isPast: false,
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isPast;

  const _StepDot({required this.label, required this.isActive, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? const Color(0xFF90BDE7)
        : isPast
            ? const Color(0xFF90BDE7).withValues(alpha: 0.6)
            : Colors.grey[300]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 10 : 7,
          height: isActive ? 10 : 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [BoxShadow(color: const Color(0xFF90BDE7).withValues(alpha: 0.5), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF6FA8D8) : Colors.grey[400],
            fontSize: 9,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 14),
      color: active ? const Color(0xFF90BDE7) : Colors.grey[200],
    );
  }
}

// ─────────────────────────────────────────────
// Control Button
// ─────────────────────────────────────────────
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _ControlButton({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: tooltip ?? '',
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: const Color(0xFF6FA8D8), size: 22),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Play/Pause Button (larger, golden)
// ─────────────────────────────────────────────
class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayPauseButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF90BDE7), Color(0xFF6FA8D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF90BDE7).withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _AudioProgressSlider extends StatelessWidget {
  final VerseByVerseController controller;

  const _AudioProgressSlider({required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: controller.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: controller.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            double value = 0;
            if (duration.inMilliseconds > 0) {
              value = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
            }

            return Container(
              height: 12,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: const Color(0xFF90BDE7),
                  inactiveTrackColor: Colors.grey[200],
                  thumbColor: const Color(0xFF6FA8D8),
                  overlayColor: const Color(0xFF90BDE7).withValues(alpha: 0.1),
                ),
                child: Slider(
                  value: value,
                  onChanged: (v) {
                    final newPos = Duration(milliseconds: (v * duration.inMilliseconds).toInt());
                    controller.seek(newPos);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
