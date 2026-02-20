import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/tafseer_source.dart';
import '../services/tafseer_service.dart';
import '../../../../core/di.dart';
import '../models/ayah.dart';

class TafseerBottomSheet extends StatefulWidget {
  final Ayah ayah;
  final int surahNumber;
  final String surahName;

  const TafseerBottomSheet({
    super.key,
    required this.ayah,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  State<TafseerBottomSheet> createState() => _TafseerBottomSheetState();
}

class _TafseerBottomSheetState extends State<TafseerBottomSheet> {
  late TafseerService _tafseerService;
  TafseerSource _selectedSource = TafseerSource.availableSources.first;
  
  Map<int, String> _tafseerTextMap = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tafseerService = sl<TafseerService>();
    _loadTafseerText();
    
    // Audio listeners
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _position = Duration.zero;
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.pause();
          }
        });
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _audioPlayer.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadTafseerText() async {
    if (_selectedSource.type == TafseerType.audio) {
      setState(() {
        _tafseerTextMap = {};
        _isLoading = false;
        _errorMessage = null; 
      });
      // Pre-load audio if needed or just prepare UI
      _prepareAudio();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final map = await _tafseerService.getTafseerText(_selectedSource.id, widget.surahNumber);
      if (mounted) {
        setState(() {
          _tafseerTextMap = map;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load Tafseer text. Please check your internet connection.";
          _isLoading = false;
        });
      }
    }
    
    // Also prepare audio if mixed type
    if (_selectedSource.type == TafseerType.mixed) {
      _prepareAudio();
    }
  }

  Future<void> _prepareAudio() async {
    // Stop previous audio
    await _audioPlayer.stop();

    final url = _tafseerService.getAudioUrl(_selectedSource, widget.surahNumber);
    if (url != null) {
      print("Attempting to play Audio URL: $url"); // Debug log available in terminal
      try {
        await _audioPlayer.setUrl(url);
      } catch (e) {
        print("Error loading audio: $e");
        if (mounted) {
          setState(() {
            _errorMessage = "Audio failed to load.\nURL: $url\nError: $e";
          });
        }
      }
    } else {
       if (mounted) {
          setState(() {
            _errorMessage = "Audio source not available for this selection.";
          });
       }
    }
  }

  void _onSourceChanged(TafseerSource? source) {
    if (source != null && source != _selectedSource) {
      setState(() {
        _selectedSource = source;
      });
      _loadTafseerText();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header & Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tafseer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                DropdownButton<TafseerSource>(
                  value: _selectedSource,
                  onChanged: _onSourceChanged,
                  alignment: Alignment.centerRight,
                  underline: Container(),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1B5E20)),
                  items: TafseerSource.availableSources.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.name,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            
            const Divider(),

            // Audio Player Control (if applicable)
            if (_selectedSource.type == TafseerType.audio || _selectedSource.type == TafseerType.mixed)
            _buildAudioPlayer(),

            if (_selectedSource.type == TafseerType.audio || _selectedSource.type == TafseerType.mixed)
            const Divider(),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                      : _selectedSource.type == TafseerType.audio
                          ? const Center(child: Text("Audio Only Mode. Use the player above.", style: TextStyle(color: Colors.grey)))
                          : SingleChildScrollView(
                              controller: controller,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Show Ayah content first for context
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F8E9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      widget.ayah.text,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontFamily: 'AmiriQuran',
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  
                                  // Tafseer Text
                                  Text(
                                    _tafseerTextMap[widget.ayah.numberInSurah] ?? "Tafseer text not available for this Ayah.",
                                    textAlign: TextAlign.justify,
                                    textDirection: _selectedSource.language == 'ur' || _selectedSource.language == 'ar' 
                                        ? TextDirection.rtl 
                                        : TextDirection.ltr,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      height: 1.8,
                                      color: Colors.black87,
                                      fontFamily: 'JameelNooriNastaleeq', // Assuming Urdu font is available, or fallback
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                iconSize: 40,
                color: const Color(0xFF1B5E20),
                onPressed: () {
                  if (_isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play();
                  }
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Surah ${widget.surahName} - Full Lecture",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _position.inSeconds.toDouble(),
                      max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (val) {
                         _audioPlayer.seek(Duration(seconds: val.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position), style: const TextStyle(fontSize: 12)),
                          Text(_formatDuration(_duration), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s";
  }
}
