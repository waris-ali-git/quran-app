import 'package:just_audio/just_audio.dart';

class QuranAudioService {
  final AudioPlayer _player = AudioPlayer();

  // Singleton pattern (Optional but good for audio service)
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;
  QuranAudioService._internal();

  // Getters for player state
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  
  // Current playing ayah URL to check state
  String? _currentUrl;
  String? get currentUrl => _currentUrl;

  /// Ayah play karein
  Future<void> playAyah(String url) async {
    try {
      if (_currentUrl == url && _player.playing) {
        // Already playing same ayah
        return;
      } else if (_currentUrl == url && !_player.playing) {
        // Paused, resume
        await _player.play();
      } else {
        // New ayah
        _currentUrl = url;
        await _player.setUrl(url);
        await _player.play();
      }
    } catch (e) {
      print("Audio Error: $e");
      // Handle error (e.g. network issue)
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
  }
  
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _player.dispose();
  }
}
