import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/tafseer_source.dart';
import '../services/audio_service.dart';
import '../services/tafseer_service.dart';
import '../../../core/di.dart';
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
  String _selectedLanguage = TafseerSource.availableSources.first.languageLabel;

  Map<int, String> _tafseerTextMap = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _tafseerService = sl<TafseerService>();
    _loadTafseerText();
  }

  @override
  void dispose() {
    // DO NOT dispose global audio player here
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
      final map = await _tafseerService.getTafseerText(
        _selectedSource.id,
        widget.surahNumber,
        quranComTafsirId: _selectedSource.quranComTafsirId,
        quranComTranslationId: _selectedSource.quranComTranslationId,
      );
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
    if (mounted) {
      setState(() {
        _isLoadingAudio = true;
        _errorMessage = null;
      });
    }
    
    final audioService = QuranAudioService();
    // Use per-ayah audio URL for the specific ayah
    final url = _tafseerService.getPerAyahAudioUrl(
      _selectedSource,
      widget.surahNumber,
      widget.ayah.numberInSurah,
      surahName: widget.surahName,
      globalAyahNumber: widget.ayah.number, // Global ayah number for some APIs
    );
    
    debugPrint("🔍 Generated audio URL: $url");
    
    if (url != null) {
      // Get fallback URLs to try
      final fallbackUrls = _tafseerService.getFallbackUrls(
        _selectedSource,
        widget.surahNumber,
        widget.ayah.numberInSurah,
        surahName: widget.surahName,
      );
      // Remove the primary URL from fallback list
      fallbackUrls.remove(url);
      
      // If NOT currently playing this EXACT ayah's tafseer, play/load it
      if (audioService.currentTafseerUrl != url || 
          audioService.tafseerSurahName != widget.surahName ||
          audioService.tafseerScholarName != _selectedSource.name) {
         try {
           await audioService.playTafseer(
             url: url,
             surahName: widget.surahName,
             scholarName: _selectedSource.name,
             fallbackUrls: fallbackUrls,
           );
           if (mounted) {
             setState(() {
               _isLoadingAudio = false;
               _errorMessage = null;
             });
           }
         } catch (e) {
           debugPrint("❌ Error in _prepareAudio: $e");
           if (mounted) {
             setState(() {
               _isLoadingAudio = false;
               // Don't show error as blocking message - audio is optional
               // Just log it, user can still read text tafseer
               _errorMessage = null; // Clear error, audio is optional
             });
           }
           // Log error for debugging but don't block UI
           debugPrint("⚠️ Tafseer audio not available for this source. Text tafseer is still available below.");
         }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingAudio = false;
          });
        }
      }
    } else {
       if (mounted) {
          setState(() {
            _isLoadingAudio = false;
            _errorMessage = "Audio source not available for this selection.";
          });
       }
    }
  }

  void _onSourceChanged(TafseerSource? source) {
    if (source != null && source != _selectedSource) {
      QuranAudioService().stopTafseer(); // stop previous source
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

            // Header
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
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'surah${widget.surahNumber.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                      fontFamily: 'surah-name-v2-icon',
                      fontSize: 38,
                      color: Color(0xFF1B5E20),
                      fontFeatures: [FontFeature.enable('liga')],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Language filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: TafseerSource.availableLanguages.map((lang) {
                  final isSelected = _selectedLanguage == lang;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(lang, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : const Color(0xFF1B5E20))),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1B5E20),
                      backgroundColor: Colors.grey[200],
                      onSelected: (_) {
                        setState(() {
                          _selectedLanguage = lang;
                          // Auto-select first source of that language
                          final sources = TafseerSource.getSourcesByLanguage(lang);
                          if (sources.isNotEmpty && !sources.contains(_selectedSource)) {
                            _onSourceChanged(sources.first);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),

            // Tafseer source dropdown (filtered by language)
            SizedBox(
              width: double.infinity,
              child: DropdownButton<TafseerSource>(
                value: TafseerSource.getSourcesByLanguage(_selectedLanguage).contains(_selectedSource)
                    ? _selectedSource
                    : TafseerSource.getSourcesByLanguage(_selectedLanguage).first,
                onChanged: _onSourceChanged,
                isExpanded: true,
                underline: Container(height: 1, color: const Color(0xFF1B5E20)),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1B5E20)),
                items: TafseerSource.getSourcesByLanguage(_selectedLanguage).map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(
                          s.type == TafseerType.audio ? Icons.headphones :
                          s.type == TafseerType.mixed ? Icons.library_music :
                          Icons.menu_book,
                          size: 16,
                          color: const Color(0xFF1B5E20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const Divider(),

            // Audio Player Control (if applicable)
            if (_selectedSource.type == TafseerType.audio || _selectedSource.type == TafseerType.mixed)
            _buildAudioPlayer(),

            // Info message if audio source might not be available
            if (_selectedSource.type == TafseerType.audio || _selectedSource.type == TafseerType.mixed)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Tafseer audio may not be available for all sources. Text tafseer is always available below.',
                      style: TextStyle(fontSize: 11, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),

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
                                      widget.ayah.text.cleanArabic,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontFamily: 'UthmanicHafs',
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  
                                  // Tafseer Text
                                  Text(
                                    _tafseerTextMap[widget.ayah.numberInSurah] ?? "Tafseer text not available for this Ayah.",
                                    textAlign: TextAlign.justify,
                                    textDirection: const {'ur', 'ar', 'ku', 'fa', 'ps', 'sd', 'ug', 'he'}.contains(_selectedSource.language)
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                    style: TextStyle(
                                      fontSize: 18,
                                      height: 1.8,
                                      color: Colors.black87,
                                      fontFamily: const {'ur', 'ar', 'fa', 'ps', 'sd', 'ku'}.contains(_selectedSource.language)
                                          ? 'JameelNooriNastaleeq'
                                          : null,
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
    return _TafseerAudioPlayerWidget(
      ayah: widget.ayah,
      surahNumber: widget.surahNumber,
      surahName: widget.surahName,
      selectedSource: _selectedSource,
      tafseerService: _tafseerService,
      initialIsLoadingAudio: _isLoadingAudio,
      onLoadingAudioChanged: (isLoading) {
        if (mounted) {
          setState(() {
             _isLoadingAudio = isLoading;
             _errorMessage = null;
          });
        }
      },
    );
  }

}

class _TafseerAudioPlayerWidget extends StatefulWidget {
  final Ayah ayah;
  final int surahNumber;
  final String surahName;
  final TafseerSource selectedSource;
  final TafseerService tafseerService;
  final bool initialIsLoadingAudio;
  final ValueChanged<bool> onLoadingAudioChanged;

  const _TafseerAudioPlayerWidget({
    required this.ayah,
    required this.surahNumber,
    required this.surahName,
    required this.selectedSource,
    required this.tafseerService,
    required this.initialIsLoadingAudio,
    required this.onLoadingAudioChanged,
  });

  @override
  State<_TafseerAudioPlayerWidget> createState() => _TafseerAudioPlayerWidgetState();
}

class _TafseerAudioPlayerWidgetState extends State<_TafseerAudioPlayerWidget> {
  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _isLoadingAudio = widget.initialIsLoadingAudio;
    
    final audioService = QuranAudioService();
    
    audioService.tafseerPlayerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoadingAudio = state.processingState == ProcessingState.loading || 
                           state.processingState == ProcessingState.buffering;
          
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _isLoadingAudio = false;
            _position = Duration.zero;
            audioService.seekTafseer(Duration.zero);
            audioService.pauseTafseer();
          }
        });
        widget.onLoadingAudioChanged(_isLoadingAudio);
      }
    });

    audioService.tafseerPositionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    audioService.tafseerDurationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    });
    
    audioService.tafseerSpeedStream.listen((speed) {
      if (mounted) setState(() => _currentSpeed = speed);
    });
  }

  void _showTanzeemPartsSheet(BuildContext context) {
    final parts = widget.tafseerService.getTanzeemSegmentsForSurah(widget.surahNumber);
    if (parts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Tanzeem.org parts found for this Surah.'),
          duration: Duration(seconds: 2),
        ),
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
            itemBuilder: (context, index) {
              final p = parts[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                  child: Text(
                    '${p.part}',
                    style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                title: Text(p.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Ayah ${p.startAyah}${p.endAyah == null ? ' - End' : ' - ${p.endAyah}'}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.play_arrow),
                onTap: () async {
                  Navigator.of(context).pop();
                  final audioService = QuranAudioService();
                  try {
                    if (mounted) {
                      setState(() {
                        _isLoadingAudio = true;
                      });
                      widget.onLoadingAudioChanged(true);
                    }
                    await audioService.playTafseer(
                      url: p.url,
                      surahName: '${widget.surahName} - ${p.title}',
                      scholarName: 'Dr. Israr Ahmed (Tanzeem.org)',
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isLoadingAudio = false);
                      widget.onLoadingAudioChanged(false);
                    }
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTanzeemAudio = widget.selectedSource.id == 'ur-israr-tanzeem-04198' || 
                            widget.selectedSource.id == 'ur-tafsir-bayan-ul-quran';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: _isLoadingAudio 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                color: const Color(0xFF1B5E20),
                iconSize: 40,
                onPressed: () {
                  final audioService = QuranAudioService();
                  if (_isPlaying) {
                     audioService.pauseTafseer();
                  } else {
                     if (audioService.currentTafseerUrl != null) {
                       audioService.playTafseer(
                         url: audioService.currentTafseerUrl!,
                         surahName: widget.surahName,
                         scholarName: widget.selectedSource.name,
                       );
                     }
                  }
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.selectedSource.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.surahName,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (hasTanzeemAudio)
                IconButton(
                  icon: const Icon(Icons.list, color: Color(0xFF1B5E20)),
                  tooltip: 'All Parts for this Surah',
                  onPressed: () => _showTanzeemPartsSheet(context),
                ),
            ],
          ),
          if (_duration.inMilliseconds > 0)
            Row(
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                    ),
                    child: Slider(
                      value: _position.inMilliseconds.toDouble(),
                      max: _duration.inMilliseconds.toDouble(),
                      activeColor: const Color(0xFF1B5E20),
                      inactiveColor: Colors.grey[300],
                      onChanged: (val) {
                         QuranAudioService().seekTafseer(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    final newSpeed = _currentSpeed >= 2.0 ? 1.0 : _currentSpeed + 0.5;
                    QuranAudioService().setTafseerSpeed(newSpeed);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_currentSpeed}x',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
