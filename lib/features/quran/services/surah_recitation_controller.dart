import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'word_timing_service.dart';

/// Holds the current highlight state for the mushaf.
class RecitationHighlightState {
  final int? activeAyah;
  final int? activeWordIndex;
  final Set<String> fadingWords;
  final bool isPlaying;

  const RecitationHighlightState({
    this.activeAyah,
    this.activeWordIndex,
    this.fadingWords = const {},
    this.isPlaying = false,
  });

  RecitationHighlightState copyWith({
    int? activeAyah,
    int? activeWordIndex,
    Set<String>? fadingWords,
    bool? isPlaying,
  }) {
    return RecitationHighlightState(
      activeAyah: activeAyah ?? this.activeAyah,
      activeWordIndex: activeWordIndex ?? this.activeWordIndex,
      fadingWords: fadingWords ?? this.fadingWords,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  bool isWordActive(int ayahNumberInSurah, int wordPosition) =>
      activeAyah == ayahNumberInSurah && activeWordIndex == wordPosition;

  bool isWordFading(int ayahNumberInSurah, int wordPosition) =>
      fadingWords.contains('${ayahNumberInSurah}_$wordPosition');
}

/// Controls surah-level recitation with word-level golden highlighting.
///
/// Bismillah is handled externally (in the UI layer) by playing a separate
/// AudioPlayer before calling [play()]. This keeps loadChapter() reliable.
class SurahRecitationController extends ChangeNotifier {
  final WordTimingService _timingService;
  final AudioPlayer _player = AudioPlayer();

  ChapterAudioData? _audioData;
  RecitationHighlightState _state = const RecitationHighlightState();
  Timer? _positionTimer;
  String? _prevWordKey;
  StreamSubscription<PlayerState>? _completionSub;

  RecitationHighlightState get state => _state;
  bool get isLoading => _isLoading;
  bool _isLoading = false;
  bool get isReady => _audioData != null && !_isLoading;

  SurahRecitationController(this._timingService);

  /// Load chapter audio + word timing segments. Call once before playing.
  Future<bool> loadChapter(int chapterNumber, {String reciterId = 'alafasy'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _audioData = await _timingService.getChapterAudioWithSegments(
        chapterNumber,
        reciterId: reciterId,
      );

      if (_audioData == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _player.setUrl(_audioData!.audioUrl);

      _completionSub?.cancel();
      _completionSub = _player.playerStateStream.listen((ps) {
        if (ps.processingState == ProcessingState.completed) stop();
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ SurahRecitationController.loadChapter: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> play() async {
    if (_audioData == null) return;
    _state = _state.copyWith(isPlaying: true);
    notifyListeners();

    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _updateHighlightFromPosition();
    });

    _player.play();
  }

  Future<void> pause() async {
    _positionTimer?.cancel();
    _state = RecitationHighlightState(
      activeAyah: _state.activeAyah,
      activeWordIndex: _state.activeWordIndex,
      fadingWords: const {},
      isPlaying: false,
    );
    notifyListeners();
    _player.pause();
  }

  Future<void> togglePlayPause() async {
    if (_state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stop() async {
    _positionTimer?.cancel();
    _player.stop();
    _prevWordKey = null;
    _state = const RecitationHighlightState();
    notifyListeners();
  }

  void _updateHighlightFromPosition() {
    if (_audioData == null) return;

    final posMs = _player.position.inMilliseconds;

    VerseTiming? currentVerse;
    for (final vt in _audioData!.verseTimings) {
      if (posMs >= vt.timestampFrom && posMs < vt.timestampTo) {
        currentVerse = vt;
        break;
      }
    }
    if (currentVerse == null) return;

    int? activeWord;
    for (final wt in currentVerse.wordTimings) {
      if (posMs >= wt.startMs && posMs < wt.endMs) {
        activeWord = wt.wordIndex;
        break;
      }
    }

    if (activeWord == null && currentVerse.wordTimings.isNotEmpty) {
      for (int i = currentVerse.wordTimings.length - 1; i >= 0; i--) {
        if (posMs >= currentVerse.wordTimings[i].startMs) {
          activeWord = currentVerse.wordTimings[i].wordIndex;
          break;
        }
      }
    }

    final ayahNum = currentVerse.ayahNumber;
    final newWordKey = activeWord != null ? '${ayahNum}_$activeWord' : null;

    if (newWordKey != _prevWordKey) {
      final newFading = Set<String>.from(_state.fadingWords);
      if (_prevWordKey != null) {
        newFading.add(_prevWordKey!);
        final keyToRemove = _prevWordKey!;
        Future.delayed(const Duration(seconds: 2), () {
          if (_state.fadingWords.contains(keyToRemove)) {
            final updated = Set<String>.from(_state.fadingWords)..remove(keyToRemove);
            _state = _state.copyWith(fadingWords: updated);
            notifyListeners();
          }
        });
      }

      _prevWordKey = newWordKey;
      _state = RecitationHighlightState(
        activeAyah: ayahNum,
        activeWordIndex: activeWord,
        fadingWords: newFading,
        isPlaying: true,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _completionSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
