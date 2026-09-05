import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_service.dart';
import '../services/tafseer_service.dart';
import '../../../core/di.dart';
import '../services/verse_by_verse_controller.dart';

/// A persistent floating mini-player for Tafseer audio.
/// Appears whenever [QuranAudioService.hasTafseerAudio] is true.
/// Should be placed in a [Stack] at the bottom of the parent screen.
class GlobalTafseerPlayerWidget extends StatefulWidget {
  final VoidCallback? onBarTap;

  const GlobalTafseerPlayerWidget({super.key, this.onBarTap});

  @override
  State<GlobalTafseerPlayerWidget> createState() =>
      _GlobalTafseerPlayerWidgetState();
}

class _GlobalTafseerPlayerWidgetState extends State<GlobalTafseerPlayerWidget>
    with SingleTickerProviderStateMixin {
  final _audioService = QuranAudioService();
  late TafseerService _tafseerService;

  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _hasAudio = false;
  bool _vbvActive = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _tafseerService = sl<TafseerService>();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _subs.add(_audioService.tafseerPlayerStateStream.listen((state) {
      if (!mounted) return;
      final hasAudio = _audioService.hasTafseerAudio;
      setState(() {
        _isPlaying = state.playing;
        _isLoading = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        _hasAudio = hasAudio;

        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _isLoading = false;
          _position = Duration.zero;
          _audioService.stopTafseer();
        }
      });
      if (hasAudio) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }));

    _subs.add(_audioService.tafseerPositionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    }));

    _subs.add(_audioService.tafseerDurationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    }));

    _subs.add(_audioService.tafseerSpeedStream.listen((speed) {
      if (mounted) setState(() => _speed = speed);
    }));

    // Listen to VbV state to hide this player if VbV starts
    VerseByVerseController().addListener(_onVbvChanged);
    _vbvActive = VerseByVerseController().state.isActive;

    // Sync initial state
    _hasAudio = _audioService.hasTafseerAudio;
    _isPlaying = _audioService.isTafseerPlaying;
    if (_hasAudio) {
      _slideController.value = 1.0;
    } else {
      _slideController.value = 0.0;
    }
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    VerseByVerseController().removeListener(_onVbvChanged);
    _slideController.dispose();
    super.dispose();
  }

  void _onVbvChanged() {
    if (!mounted) return;
    final isActive = VerseByVerseController().state.isActive;
    if (isActive != _vbvActive) {
      setState(() => _vbvActive = isActive);
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _audioService.pauseTafseer();
    } else {
      final url = _audioService.currentTafseerUrl;
      if (url != null) {
        _audioService.playTafseer(
          url: url,
          surahName: _audioService.tafseerSurahName ?? '',
          scholarName: _audioService.tafseerScholarName ?? '',
          surahNumber: _audioService.tafseerSurahNumber,
          sourceId: _audioService.tafseerSourceId,
        );
      }
    }
  }

  void _stop() {
    _audioService.stopTafseer();
    setState(() {
      _hasAudio = false;
      _isPlaying = false;
    });
    _slideController.reverse();
  }

  void _cycleSpeed() {
    final newSpeed =
        _speed >= 2.0 ? 0.75 : (_speed == 0.75 ? 1.0 : _speed + 0.25);
    _audioService.setTafseerSpeed(newSpeed);
  }

  void _showSegmentedPartsSheet(BuildContext context) {
    final sourceId = _audioService.tafseerSourceId;
    final surahNumber = _audioService.tafseerSurahNumber;
    if (sourceId == null || surahNumber == null) return;

    final List<TafseerAudioSegment> parts;
    final String sourceLabel;

    if (sourceId == 'ur-taqi-usmani-audio') {
      parts = _tafseerService.getTaqiUsmaniSegmentsForSurah(surahNumber);
      sourceLabel = 'Mufti Taqi Usmani';
    } else {
      parts = _tafseerService.getTanzeemSegmentsForSurah(surahNumber);
      sourceLabel = 'Dr. Israr Ahmed (Tanzeem.org)';
    }

    if (parts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No parts found for this Surah.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: parts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, index) {
              final p = parts[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor:
                      const Color(0xFF90BDE7).withValues(alpha: 0.1),
                  child: Text(
                    '${p.part}',
                    style: const TextStyle(
                        color: Color(0xFF90BDE7),
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
                title: Text(p.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Ayah ${p.startAyah}${p.endAyah == null ? ' - End' : ' - ${p.endAyah}'}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.play_arrow),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    setState(() => _isLoading = true);
                    await _audioService.playTafseer(
                      url: p.url,
                      surahName:
                          '${_audioService.tafseerSurahName} - ${p.title}',
                      scholarName: sourceLabel,
                      surahNumber: surahNumber,
                      sourceId: sourceId,
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  String _fmt(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  bool get _hasSegments {
    final id = _audioService.tafseerSourceId;
    return id == 'ur-israr-tanzeem-04198' ||
        id == 'ur-tafsir-bayan-ul-quran' ||
        id == 'ur-taqi-usmani-audio';
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAudio || _vbvActive) return const SizedBox.shrink();

    return SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: widget.onBarTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4FBFE),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF90BDE7).withValues(alpha: 0.15),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Tafseer icon badge
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF90BDE7).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book,
                            color: Color(0xFF90BDE7), size: 20),
                      ),
                      const SizedBox(width: 10),
                      // Track info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _audioService.tafseerScholarName ?? 'Tafseer',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF90BDE7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _audioService.tafseerSurahName ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Speed button
                      GestureDetector(
                        onTap: _cycleSpeed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF90BDE7).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_speed}x',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF90BDE7),
                            ),
                          ),
                        ),
                      ),
                      if (_hasSegments)
                        IconButton(
                          icon: const Icon(Icons.list_alt_rounded,
                              color: Color(0xFF90BDE7), size: 20),
                          tooltip: 'All Parts',
                          onPressed: () => _showSegmentedPartsSheet(context),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      // Play/Pause
                      IconButton(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF90BDE7)))
                            : Icon(
                                _isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_filled_rounded,
                                color: const Color(0xFF90BDE7),
                                size: 34,
                              ),
                        onPressed: _togglePlayPause,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                      // Close
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.grey, size: 20),
                        onPressed: _stop,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (_duration.inMilliseconds > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(_fmt(_position),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 10),
                            ),
                            child: Slider(
                              value: _position.inMilliseconds.toDouble().clamp(
                                  0, _duration.inMilliseconds.toDouble()),
                              max: _duration.inMilliseconds.toDouble(),
                              activeColor: const Color(0xFF90BDE7),
                              inactiveColor: Colors.grey[200],
                              onChanged: (val) => _audioService.seekTafseer(
                                  Duration(milliseconds: val.toInt())),
                            ),
                          ),
                        ),
                        Text(_fmt(_duration),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
    );
  }
}
