import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/translation_audio_edition.dart';
import '../models/reciter.dart';
import 'audio_service.dart';

/// Playback step within a single ayah's sequence.
enum VersePlaybackStep {
  idle,
  recitation,
  translation,
  tafseer,
}

/// Configuration for what to play in the sequential chain.
class VerseByVerseConfig {
  final bool playRecitation;
  final bool playTranslation;
  final bool playTafseer;
  final Reciter reciter;
  final TranslationAudioEdition translationEdition;
  /// Optional: URL resolver for tafseer audio given surahNumber.
  /// Returns null if no tafseer audio is available for this surah.
  final String? Function(int surahNumber)? tafseerAudioUrlResolver;

  const VerseByVerseConfig({
    this.playRecitation = true,
    this.playTranslation = true,
    this.playTafseer = false,
    required this.reciter,
    required this.translationEdition,
    this.tafseerAudioUrlResolver,
  });

  VerseByVerseConfig copyWith({
    bool? playRecitation,
    bool? playTranslation,
    bool? playTafseer,
    Reciter? reciter,
    TranslationAudioEdition? translationEdition,
    String? Function(int surahNumber)? tafseerAudioUrlResolver,
  }) {
    return VerseByVerseConfig(
      playRecitation: playRecitation ?? this.playRecitation,
      playTranslation: playTranslation ?? this.playTranslation,
      playTafseer: playTafseer ?? this.playTafseer,
      reciter: reciter ?? this.reciter,
      translationEdition: translationEdition ?? this.translationEdition,
      tafseerAudioUrlResolver: tafseerAudioUrlResolver ?? this.tafseerAudioUrlResolver,
    );
  }
}

/// Emitted state for the verse-by-verse playback engine.
class VerseByVerseState {
  final bool isActive;           // true when v-b-v mode is on
  final bool isPlaying;
  final bool isPaused;
  final int surahNumber;
  final int currentAyahInSurah; // 1-based ayah within surah
  final int totalAyahs;
  final VersePlaybackStep step;
  final double speed;

  const VerseByVerseState({
    this.isActive = false,
    this.isPlaying = false,
    this.isPaused = false,
    this.surahNumber = 0,
    this.currentAyahInSurah = 0,
    this.totalAyahs = 0,
    this.step = VersePlaybackStep.idle,
    this.speed = 1.0,
  });

  bool get isIdle => !isActive;
  bool get isLastAyah => currentAyahInSurah >= totalAyahs;

  VerseByVerseState copyWith({
    bool? isActive,
    bool? isPlaying,
    bool? isPaused,
    int? surahNumber,
    int? currentAyahInSurah,
    int? totalAyahs,
    VersePlaybackStep? step,
    double? speed,
  }) {
    return VerseByVerseState(
      isActive: isActive ?? this.isActive,
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      surahNumber: surahNumber ?? this.surahNumber,
      currentAyahInSurah: currentAyahInSurah ?? this.currentAyahInSurah,
      totalAyahs: totalAyahs ?? this.totalAyahs,
      step: step ?? this.step,
      speed: speed ?? this.speed,
    );
  }
}

/// Converts global ayah number to (surah, ayahInSurah) — needed to build audio URLs.
/// Ayah counts per surah (standard Hafs).
const List<int> _surahAyahCounts = [
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, // 1-10
  123, 111, 43, 52, 99, 128, 111, 110, 98, 135,  // 11-20
  112, 78, 118, 64, 77, 227, 93, 88, 69, 60,     // 21-30
  34, 30, 73, 54, 45, 83, 182, 88, 75, 85,       // 31-40
  54, 53, 89, 59, 37, 35, 38, 29, 18, 45,        // 41-50
  60, 49, 62, 55, 78, 96, 29, 22, 24, 13,        // 51-60
  14, 11, 11, 18, 12, 12, 30, 52, 52, 44,        // 61-70
  28, 28, 20, 56, 40, 31, 50, 40, 46, 42,        // 71-80
  29, 19, 36, 25, 22, 17, 19, 26, 30, 20,        // 81-90
  15, 21, 11, 8, 8, 19, 5, 8, 8, 11,             // 91-100
  11, 8, 3, 9, 5, 4, 7, 3, 6, 3,                 // 101-110
  5, 4, 5, 6,                                     // 111-114
];

int _getGlobalAyahNumber(int surahNumber, int ayahInSurah) {
  int global = 0;
  for (int i = 0; i < surahNumber - 1; i++) {
    global += _surahAyahCounts[i];
  }
  return global + ayahInSurah;
}

/// Core engine for the verse-by-verse sequential playback.
///
/// Sequence per ayah:
///   [RECITATION] → [TRANSLATION] → [TAFSEER (optional)] → advance to next ayah
///
/// Each step can be independently toggled via [VerseByVerseConfig].
/// Auto-scroll is signaled via [onAyahChanged] callback so ReaderScreen
/// can animate to the right position.
class VerseByVerseController extends ChangeNotifier {
  static final VerseByVerseController _instance = VerseByVerseController._internal();
  factory VerseByVerseController() => _instance;

  VerseByVerseConfig _config;
  VerseByVerseState _state = const VerseByVerseState();

  /// Single sequential player — only one step plays at a time.
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;

  VerseByVerseState get state => _state;
  VerseByVerseConfig get config => _config;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  VerseByVerseController._internal()
      : _config = VerseByVerseConfig(
          reciter: defaultReciters.first,
          translationEdition: TranslationAudioEdition.defaultEdition,
        );

  // ─────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────

  /// Start verse-by-verse from the given ayah.
  Future<void> start({
    required int surahNumber,
    required int startAyah,
    required int totalAyahs,
  }) async {
    // Mutual exclusion: stop Tafseer if starting VbV
    QuranAudioService().stopTafseer();

    await _stopPlayer();
    _state = VerseByVerseState(
      isActive: true,
      isPlaying: true,
      isPaused: false,
      surahNumber: surahNumber,
      currentAyahInSurah: startAyah,
      totalAyahs: totalAyahs,
      step: VersePlaybackStep.idle,
    );
    notifyListeners();
    await _playCurrentStep();
  }

  /// Pause whatever is currently playing.
  Future<void> pause() async {
    if (!_state.isPlaying) return;
    _state = _state.copyWith(isPlaying: false, isPaused: true);
    notifyListeners();
    await _player.pause();
  }

  /// Resume from paused state.
  Future<void> resume() async {
    if (!_state.isPaused) return;
    _state = _state.copyWith(isPlaying: true, isPaused: false);
    notifyListeners();
    await _player.play();
  }

  /// Toggle play/pause.
  Future<void> togglePlayPause() async {
    if (_state.isPlaying) {
      await pause();
    } else if (_state.isPaused) {
      await resume();
    }
  }

  /// Cycle through playback speeds.
  void cycleSpeed() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    int currentIndex = speeds.indexOf(_state.speed);
    int nextIndex = (currentIndex + 1) % speeds.length;
    final newSpeed = speeds[nextIndex];
    
    _state = _state.copyWith(speed: newSpeed);
    _player.setSpeed(newSpeed);
    notifyListeners();
  }

  /// Seek to a specific position in the current audio.
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Stop and reset everything.
  Future<void> stop() async {
    await _stopPlayer();
    _state = const VerseByVerseState();
    notifyListeners();
  }

  /// Skip to next ayah immediately.
  Future<void> skipToNext() async {
    if (!_state.isActive) return;
    await _advanceToNextAyah();
  }

  /// Skip to previous ayah.
  Future<void> skipToPrev() async {
    if (!_state.isActive) return;
    if (_state.currentAyahInSurah <= 1) return;
    await _stopPlayer();
    _state = _state.copyWith(
      currentAyahInSurah: _state.currentAyahInSurah - 1,
      isPlaying: true,
      isPaused: false,
    );
    notifyListeners();
    await _playCurrentStep();
  }

  /// Skip the current step and move to the next one.
  Future<void> skipStep() async {
    if (!_state.isActive || !_state.isPlaying) return;
    await _stopPlayer();
    await _advanceStep();
  }

  /// Update configuration (e.g. user toggles a step).
  void updateConfig(VerseByVerseConfig newConfig) {
    _config = newConfig;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // INTERNAL PLAYBACK LOGIC
  // ─────────────────────────────────────────────

  Future<void> _playCurrentStep() async {
    if (!_state.isActive) return;

    // Determine which step to play first
    final firstStep = _firstEnabledStep();
    if (firstStep == null) {
      // Nothing enabled → just advance
      await _advanceToNextAyah();
      return;
    }
    await _playStep(firstStep);
  }

  Future<void> _playStep(VersePlaybackStep step) async {
    _state = _state.copyWith(step: step, isPlaying: true, isPaused: false);
    notifyListeners();

    String? url;
    try {
      switch (step) {
        case VersePlaybackStep.recitation:
          final globalAyah = _getGlobalAyahNumber(
            _state.surahNumber, _state.currentAyahInSurah);
          url = _config.reciter.getAyahAudioUrl(
            globalAyah,
            surahNumber: _state.surahNumber,
            ayahInSurah: _state.currentAyahInSurah,
          );
          break;

        case VersePlaybackStep.translation:
          final globalAyah = _getGlobalAyahNumber(
            _state.surahNumber, _state.currentAyahInSurah);
          url = _config.translationEdition.getAyahAudioUrl(globalAyah);
          break;

        case VersePlaybackStep.tafseer:
          url = _config.tafseerAudioUrlResolver?.call(_state.surahNumber);
          if (url == null) {
            await _advanceStep();
            return;
          }
          break;

        case VersePlaybackStep.idle:
          return;
      }

      debugPrint('▶️ V-b-V [$step] ayah ${_state.currentAyahInSurah}: $url');
      await _player.stop();
      await _player.setUrl(url);

      // Listen for completion to auto-advance
      _playerSub?.cancel();
      _playerSub = _player.playerStateStream.listen((ps) {
        if (ps.processingState == ProcessingState.completed) {
          _playerSub?.cancel();
          _playerSub = null;
          if (_state.isPlaying) {
            _advanceStep();
          }
        }
      });

      await _player.play();
    } catch (e) {
      debugPrint('❌ V-b-V step $step error: $e');
      // Skip broken step
      _playerSub?.cancel();
      _playerSub = null;
      await _advanceStep();
    }
  }

  /// Move to the next logical step in the sequence.
  Future<void> _advanceStep() async {
    if (!_state.isActive) return;

    final nextStep = _nextEnabledStepAfter(_state.step);
    if (nextStep != null) {
      await _playStep(nextStep);
    } else {
      await _advanceToNextAyah();
    }
  }

  Future<void> _advanceToNextAyah() async {
    if (_state.isLastAyah) {
      // Finished the entire surah
      await _stopPlayer();
      _state = _state.copyWith(
        isActive: false,
        isPlaying: false,
        isPaused: false,
        step: VersePlaybackStep.idle,
      );
      notifyListeners();
      return;
    }

    final nextAyah = _state.currentAyahInSurah + 1;
    _state = _state.copyWith(
      currentAyahInSurah: nextAyah,
      isPlaying: true,
      isPaused: false,
    );
    notifyListeners();

    await _playCurrentStep();
  }

  Future<void> _stopPlayer() async {
    _playerSub?.cancel();
    _playerSub = null;
    await _player.stop();
  }

  /// Returns the first step that is enabled in the config.
  VersePlaybackStep? _firstEnabledStep() {
    if (_config.playRecitation) return VersePlaybackStep.recitation;
    if (_config.playTranslation) return VersePlaybackStep.translation;
    return null;
  }

  /// Returns the next enabled step after the given one.
  VersePlaybackStep? _nextEnabledStepAfter(VersePlaybackStep current) {
    if (current == VersePlaybackStep.recitation && _config.playTranslation) {
      return VersePlaybackStep.translation;
    }
    return null;
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
