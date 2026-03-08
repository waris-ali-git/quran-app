import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../models/reciter.dart';
import 'preferences_service.dart';

class QuranAudioService {
  final AudioPlayer _ayahPlayer = AudioPlayer();
  final AudioPlayer _tafseerPlayer = AudioPlayer();

  // Reciter management
  late Reciter _selectedReciter;
  Reciter? _selectedTafseerScholar;

  Reciter get selectedReciter => _selectedReciter;
  Reciter? get selectedTafseerScholar => _selectedTafseerScholar;

  List<Reciter> get availableReciters => defaultReciters;
  List<Reciter> get availableTafseerScholars => tafseerScholars;

  // Singleton pattern
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;
  QuranAudioService._internal() {
    // Load saved preferences
    _selectedReciter = PreferencesService().getSelectedReciter();
    _selectedTafseerScholar = PreferencesService().getSelectedTafseerScholar();

    // When one plays, pause the other to avoid overlapping audio
    _ayahPlayer.playingStream.listen((playing) {
      if (playing) _tafseerPlayer.pause();
    });
    _tafseerPlayer.playingStream.listen((playing) {
      if (playing) _ayahPlayer.pause();
    });
  }

  /// Set the preferred reciter for Quran audio and save to preferences
  Future<void> setReciter(Reciter reciter) async {
    _selectedReciter = reciter;
    await PreferencesService().setSelectedReciter(reciter);
  }

  /// Set the preferred tafseer scholar and save to preferences
  Future<void> setTafseerScholar(Reciter scholar) async {
    _selectedTafseerScholar = scholar;
    await PreferencesService().setSelectedTafseerScholar(scholar);
  }

  // ─────────────────────────────────────────────
  // AYAH AUDIO PLAYER
  // ─────────────────────────────────────────────
  Stream<PlayerState> get ayahPlayerStateStream => _ayahPlayer.playerStateStream;
  
  String? _currentAyahUrl;
  String? get currentAyahUrl => _currentAyahUrl;
  int? _currentAyahNumber;
  int? get currentAyahNumber => _currentAyahNumber;

  /// Helper to get the default translation URL for a specific ayah.
  String getTranslationAudioUrl(int ayahNumber) {
    // Hardcoded for now, can be updated to be dynamic based on user preference
    return 'https://cdn.islamic.network/quran/audio/128/ur.khan/$ayahNumber.mp3';
  }

  /// Play ayah audio - can use either URL directly or ayah number with selected reciter
  /// For Quran.com reciters, surahNumber & ayahInSurah are required to build the URL.
  Future<void> playAyah({String? url, int? ayahNumber, int? surahNumber, int? ayahInSurah}) async {
    // Determine the URL to use
    final audioUrl = url ?? (ayahNumber != null
        ? _selectedReciter.getAyahAudioUrl(ayahNumber, surahNumber: surahNumber, ayahInSurah: ayahInSurah)
        : null);

    if (audioUrl == null) {
      debugPrint("❌ No audio URL provided for ayah");
      return;
    }

    try {
      if (_currentAyahUrl == audioUrl && _ayahPlayer.playing) {
        return;
      } else if (_currentAyahUrl == audioUrl && !_ayahPlayer.playing) {
        await _ayahPlayer.play();
      } else {
        await _ayahPlayer.stop();
        _currentAyahUrl = audioUrl;
        _currentAyahNumber = ayahNumber;
        await _ayahPlayer.setUrl(audioUrl);
        await _ayahPlayer.play();
      }
    } catch (e) {
      _currentAyahUrl = null;
      _currentAyahNumber = null;
      debugPrint("Ayah audio error: $e");
    }
  }

  Future<void> pauseAyah() async => await _ayahPlayer.pause();
  
  Future<void> stopAyah() async {
    await _ayahPlayer.stop();
    _currentAyahUrl = null;
    _currentAyahNumber = null;
  }

  // ─────────────────────────────────────────────
  // TAFSEER AUDIO PLAYER
  // ─────────────────────────────────────────────
  Stream<PlayerState> get tafseerPlayerStateStream => _tafseerPlayer.playerStateStream;
  Stream<Duration> get tafseerPositionStream => _tafseerPlayer.positionStream;
  Stream<Duration?> get tafseerDurationStream => _tafseerPlayer.durationStream;
  Stream<double> get tafseerSpeedStream => _tafseerPlayer.speedStream;

  String? _currentTafseerUrl;
  String? get currentTafseerUrl => _currentTafseerUrl;

  String? tafseerSurahName;
  String? tafseerScholarName;

  Future<void> playTafseer({
    required String url,
    required String surahName,
    required String scholarName,
    List<String>? fallbackUrls,
  }) async {
    final urlsToTry = [url];
    if (fallbackUrls != null && fallbackUrls.isNotEmpty) {
      urlsToTry.addAll(fallbackUrls);
    }
    
    Exception? lastError;
    
    for (int i = 0; i < urlsToTry.length; i++) {
      final currentUrl = urlsToTry[i];
      try {
        debugPrint("🎵 Attempting to play tafseer audio from: $currentUrl (${i + 1}/${urlsToTry.length})");
        
        if (_currentTafseerUrl == currentUrl && _tafseerPlayer.playing) {
          debugPrint("✅ Audio already playing this URL");
          return;
        } else if (_currentTafseerUrl == currentUrl && !_tafseerPlayer.playing) {
          debugPrint("▶️ Resuming paused audio");
          await _tafseerPlayer.play();
          return;
        } else {
          debugPrint("🔄 Loading new audio URL...");
          await _tafseerPlayer.stop();
          _currentTafseerUrl = currentUrl;
          tafseerSurahName = surahName;
          tafseerScholarName = scholarName;
          
          // Set the URL and wait for it to load
          await _tafseerPlayer.setUrl(currentUrl);
          debugPrint("✅ Audio URL set, duration: ${_tafseerPlayer.duration}");
          
          // Play the audio
          await _tafseerPlayer.play();
          debugPrint("▶️ Audio playback started successfully from: $currentUrl");
          return; // Success!
        }
      } catch (e) {
        debugPrint("❌ Failed to load URL $currentUrl: $e");
        lastError = e is Exception ? e : Exception(e.toString());
        
        // If this is not the last URL, try the next one
        if (i < urlsToTry.length - 1) {
          debugPrint("🔄 Trying next fallback URL...");
          continue;
        }
      }
    }
    
    // All URLs failed
    _currentTafseerUrl = null;
    tafseerSurahName = null;
    tafseerScholarName = null;
    debugPrint("❌ All audio URLs failed. Last error: $lastError");
    throw lastError ?? Exception("Failed to load audio from all provided URLs");
  }

  Future<void> pauseTafseer() async => await _tafseerPlayer.pause();
  
  Future<void> stopTafseer() async {
    await _tafseerPlayer.stop();
    _currentTafseerUrl = null;
  }

  Future<void> seekTafseer(Duration position) async => await _tafseerPlayer.seek(position);
  
  Future<void> setTafseerSpeed(double speed) async => await _tafseerPlayer.setSpeed(speed);

  bool get isTafseerPlaying => _tafseerPlayer.playing;
  bool get hasTafseerAudio => _currentTafseerUrl != null;

  void dispose() {
    _ayahPlayer.dispose();
    _tafseerPlayer.dispose();
  }
}
