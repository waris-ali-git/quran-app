import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_service.dart';
import '../services/preferences_service.dart';
import '../services/word_timing_service.dart';
import '../services/surah_recitation_controller.dart';
import '../services/verse_by_verse_controller.dart';
import '../services/ibn_kathir_audio_data.dart';
import '../services/tajweed_service.dart';
import '../state/quran_bloc.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../models/reading_mode.dart';
import '../models/translation_audio_edition.dart';
import '../widgets/tafseer_bottom_sheet.dart';
import 'widgets/reading_settings_sheet.dart';
import 'widgets/tajweed_ayah.dart';
import 'widgets/word_by_word_ayah.dart';
import 'widgets/reciter_selection_sheet.dart';
import 'widgets/mushaf_page_preview.dart';
import 'widgets/surah_skeleton.dart';
import 'widgets/verse_playback_bar.dart';
import 'widgets/verse_playback_settings_sheet.dart';
import '../widgets/global_tafseer_player.dart';
import '../../../../shared/icons/icomoon.dart';
import '../../../../shared/icons/custom_icons_v2.dart';
import 'translation_selection_screen.dart';
import 'package:quran_app/core/widgets/no_internet_widget.dart';

class ReaderScreen extends StatefulWidget {
  final Surah surah;
  final ReadingDisplayMode initialMode;
  final int? initialAyah;
  final bool startVbvOnLoad;

  const ReaderScreen({
    super.key,
    required this.surah,
    required this.initialMode,
    this.initialAyah,
    this.startVbvOnLoad = false,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);
  Timer? _lastReadDebouncer;
  Timer? _scrollPauseTimer;
  bool _showMarkAsReadOverlay = false;
  int _overlayTriggerCount = 0; // limit to first 3 times per session

  int _currentPage = 1;
  int _currentJuz = 1;
  int _currentHizb = 1;

  // ─── Surah Recitation (Word-Level Highlighting) ───
  late SurahRecitationController _recitationController;
  bool _recitationLoaded = false;

  // Dedicated player for bismillah audio (played before chapter recitation)
  // Initialized in initState to avoid platform-channel calls during widget construction.
  AudioPlayer? _bismillahPlayer;
  bool _bismillahPlaying = false;

  // ─── Verse-by-Verse Sequential Playback ───────────
  late VerseByVerseController _vbvController;
  int _lastVbVAyah = -1;
  /// GlobalKeys per ayah index so we can scroll to the active card.
  final Map<int, GlobalKey> _ayahKeys = {};

  GlobalKey _keyForAyah(int ayahInSurah) {
    return _ayahKeys.putIfAbsent(ayahInSurah, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    _currentPage = widget.surah.ayahs?.isNotEmpty == true ? widget.surah.ayahs!.first.page : 1;
    _currentJuz = widget.surah.ayahs?.isNotEmpty == true ? widget.surah.ayahs!.first.juz : 1;
    _currentHizb = widget.surah.ayahs?.isNotEmpty == true ? (widget.surah.ayahs!.first.hizbQuarter ~/ 4 == 0 ? 1 : widget.surah.ayahs!.first.hizbQuarter ~/ 4) : 1;

    // Initialize recitation controller
    _recitationController = SurahRecitationController(
      GetIt.instance<WordTimingService>(),
    );
    _recitationController.addListener(_onRecitationUpdate);

    // Initialize bismillah player in initState (not at field level)
    // to avoid MissingPluginException during widget construction.
    _bismillahPlayer = AudioPlayer();

    // Initialize verse-by-verse controller with saved preferences
    final vbvPrefs = PreferencesService();
    final savedEditionId = vbvPrefs.getVbvTranslationEditionId();
    final savedEdition = TranslationAudioEdition.findById(savedEditionId)
        ?? TranslationAudioEdition.defaultEdition;

    _vbvController = VerseByVerseController();

    // Defer updateConfig to post-frame to avoid notifyListeners() during build,
    // which causes "setState() called during build" assertion error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vbvController.updateConfig(VerseByVerseConfig(
        reciter: QuranAudioService().selectedReciter,
        translationEdition: savedEdition,
        playTranslation: vbvPrefs.getVbvPlayTranslation(),
        playTafseer: vbvPrefs.getVbvPlayTafseer(),
        tafseerAudioUrlResolver: (surahNumber) {
          return ibneKathirTafseerAudioUrls[surahNumber];
        },
      ));
    });

    _vbvController.addListener(_onVbVUpdate);

    // Delay preload to post-frame so it doesn't trigger setState during initState
    // (loadChapter calls notifyListeners synchronously on _isLoading = true)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _preloadRecitationData();
    });

    _loadSurah();
    _scrollController.addListener(_onScroll);

    if (widget.initialAyah != null && widget.initialAyah! > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_scrollController.hasClients) {
          final estimatedTargetListIndex = widget.initialAyah! - 1; 
          final estimatedOffset = 100.0 + (estimatedTargetListIndex * 150.0);
          final maxOffset = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(estimatedOffset.clamp(0.0, maxOffset));

          // Wait a brief moment to allow slivers to render
          await Future.delayed(const Duration(milliseconds: 100));

          final key = _ayahKeys[widget.initialAyah!];
          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.2, // Show near the top with some padding
            );
          }
        }
        final isActiveAndPlayingSameSurah = _vbvController.state.isActive && _vbvController.state.surahNumber == widget.surah.number;
        if (widget.startVbvOnLoad && widget.surah.ayahs != null && !isActiveAndPlayingSameSurah) {
          _vbvController.start(
            surahNumber: widget.surah.number,
            startAyah: widget.initialAyah!,
            totalAyahs: widget.surah.numberOfAyahs,
          );
        }
      });
    } else if (widget.startVbvOnLoad && widget.surah.ayahs != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final isActiveAndPlayingSameSurah = _vbvController.state.isActive && _vbvController.state.surahNumber == widget.surah.number;
        if (!isActiveAndPlayingSameSurah) {
          _vbvController.start(
            surahNumber: widget.surah.number,
            startAyah: widget.initialAyah ?? 1,
            totalAyahs: widget.surah.numberOfAyahs,
          );
        }
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0) {
      _scrollProgress.value = (currentScroll / maxScroll).clamp(0.0, 1.0);

      // Update page/juz header — setState only when values actually change
      final state = context.read<QuranBloc>().state;
      List<Ayah>? ayahs;
      if (state is SurahLoaded) ayahs = state.surah.ayahs;
      if (state is SurahWordByWordLoaded) ayahs = state.ayahs;

      if (ayahs != null && ayahs.isNotEmpty) {
        final approxIndex = (_scrollProgress.value * (ayahs.length - 1)).round();
        if (approxIndex >= 0 && approxIndex < ayahs.length) {
          final visibleAyah = ayahs[approxIndex];
          final newPage = visibleAyah.page;
          final newJuz  = visibleAyah.juz;
          final newHizb = visibleAyah.hizbQuarter ~/ 4 == 0 ? 1 : visibleAyah.hizbQuarter ~/ 4;

          // Merge both setState calls into one to avoid double rebuild
          final overlayWasShown = _showMarkAsReadOverlay;
          final pageChanged = newPage != _currentPage || newJuz != _currentJuz;
          if (pageChanged || overlayWasShown) {
            setState(() {
              if (pageChanged) {
                _currentPage = newPage;
                _currentJuz  = newJuz;
                _currentHizb = newHizb;
              }
              if (overlayWasShown) _showMarkAsReadOverlay = false;
            });
          }
        }
      } else if (_showMarkAsReadOverlay) {
        setState(() => _showMarkAsReadOverlay = false);
      }
    } else {
      _scrollProgress.value = 0.0;
    }

    // Check for pause to show overlay
    _scrollPauseTimer?.cancel();
    if (_overlayTriggerCount < 3 &&
        _scrollProgress.value > 0.5 &&
        widget.initialMode == ReadingDisplayMode.arabicOnly) {
      _scrollPauseTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted && _scrollProgress.value > 0.5) {
          setState(() {
            _showMarkAsReadOverlay = true;
            _overlayTriggerCount++;
          });
          Timer(const Duration(seconds: 3), () {
            if (mounted && _showMarkAsReadOverlay) {
              setState(() => _showMarkAsReadOverlay = false);
            }
          });
        }
      });
    }
  }

  void _loadSurah() {
    final bloc = context.read<QuranBloc>();
    if (widget.initialMode == ReadingDisplayMode.wordByWord) {
      bloc.add(LoadSurahWordByWordEvent(surahNumber: widget.surah.number));
    } else {
      bloc.add(LoadSurahEvent(surahNumber: widget.surah.number));
    }
  }

  bool _lastRecitationPlaying = false;

  void _onRecitationUpdate() {
    if (!mounted) return;
    // Only rebuild if playing state changed — the 50ms timer fires 20x/sec
    // so we avoid full rebuilds unless the FAB icon actually needs to change.
    final nowPlaying = _recitationController.state.isPlaying;
    final isLoading = _recitationController.isLoading;
    if (nowPlaying != _lastRecitationPlaying || isLoading) {
      _lastRecitationPlaying = nowPlaying;
      setState(() {});
    }
  }

  int _lastVbVAyahForRebuild = -1;
  bool _lastVbVPlaying = false;

  void _onVbVUpdate() {
    if (!mounted) return;
    final vbvState = _vbvController.state;

    // Persist last-listened position
    if (vbvState.isActive && vbvState.surahNumber > 0 && vbvState.currentAyahInSurah > 0) {
      context.read<QuranBloc>().add(SaveLastListenedVbvEvent(
        surahNumber: vbvState.surahNumber,
        ayahNumber: vbvState.currentAyahInSurah,
      ));

      // Auto-scroll when ayah advances
      if (vbvState.surahNumber == widget.surah.number &&
          _lastVbVAyah != vbvState.currentAyahInSurah) {
        _lastVbVAyah = vbvState.currentAyahInSurah;
        _onVbVAyahChanged(_lastVbVAyah);
      }
    }

    // Only rebuild if something visually meaningful changed
    final ayahChanged = vbvState.currentAyahInSurah != _lastVbVAyahForRebuild;
    final playingChanged = vbvState.isPlaying != _lastVbVPlaying;
    if (ayahChanged || playingChanged || !vbvState.isActive) {
      _lastVbVAyahForRebuild = vbvState.currentAyahInSurah;
      _lastVbVPlaying = vbvState.isPlaying;
      setState(() {});
    }
  }

  /// Called by VbV controller when ayah advances — auto-scroll to the new card.
  void _onVbVAyahChanged(int ayahInSurah) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final key = _ayahKeys[ayahInSurah];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.2, // show near the top with some padding
        );
      } else if (_scrollController.hasClients) {
        // Fallback: Jump to an estimated offset if the item is off-screen/unbuilt
        final estimatedTargetListIndex = ayahInSurah - 1; 
        final estimatedOffset = 100.0 + (estimatedTargetListIndex * 150.0);
        final maxOffset = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(estimatedOffset.clamp(0.0, maxOffset));

        await Future.delayed(const Duration(milliseconds: 100));
        
        final newKey = _ayahKeys[ayahInSurah];
        if (newKey?.currentContext != null) {
          Scrollable.ensureVisible(
            newKey!.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.2,
          );
        }
      }
    });
  }

  void _showVersePlaybackSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VersePlaybackSettingsSheet(
        initialConfig: _vbvController.config,
        onConfigChanged: (config) {
          _vbvController.updateConfig(config);
          // Persist user choices
          PreferencesService()
            ..setVbvTranslationEditionId(config.translationEdition.id)
            ..setVbvPlayTranslation(config.playTranslation)
            ..setVbvPlayTafseer(config.playTafseer);
            
          // Instantly sync the visual translation text with the newly selected audio translation
          context.read<QuranBloc>().add(
            ChangeTranslationEvent(edition: config.translationEdition.textEditionId),
          );
        },
      ),
    );
  }

  /// Pre-load chapter audio + word-timing segments in background
  /// so that play button is instant (no loading delay).
  Future<void> _preloadRecitationData() async {
    if (_recitationLoaded) return;
    final reciterId = QuranAudioService().selectedReciter.id;
    final ok = await _recitationController.loadChapter(
      widget.surah.number,
      reciterId: reciterId,
    );
    if (ok) _recitationLoaded = true;
  }

  @override
  void dispose() {
    _recitationController.removeListener(_onRecitationUpdate);
    _recitationController.dispose();
    _bismillahPlayer?.dispose();
    _vbvController.removeListener(_onVbVUpdate);
    _lastReadDebouncer?.cancel();
    _scrollPauseTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuranBloc>().state;
    ReadingPreferences preferences = const ReadingPreferences();
    if (state is SurahLoaded) {
      preferences = state.preferences;
    } else if (state is SurahWordByWordLoaded) {
      preferences = state.preferences;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(context, preferences),
      body: _wrapWithGlobalPlayer(
        BlocConsumer<QuranBloc, QuranState>(
        listener: (context, state) {
          if (state is BookmarkUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isBookmarked ? '✔ بک مارک یو گئیا' : 'بک مارک ہٹا دیا',
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: const Color(0xFF90BDE7),
              ),
            );
          }
        },
        builder: (context, state) {
          // Progressive streaming state — show loaded ayahs + skeleton cards for the rest
          if (state is SurahStreaming) {
            return _buildStreamingContent(context, state);
          }


          if (state is QuranError) {
            return NoInternetWidget(
              message: state.message,
              onRetry: _loadSurah,
            );
          }

          if (state is SurahLoaded) {
            return Stack(
              children: [
                _buildSurahContent(
                  context,
                  state.surah,
                  state.preferences,
                  state.bookmarks,
                  state.bismillahAyah,
                ),
                if (_showMarkAsReadOverlay)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF90BDE7).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                          ]
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Tap any Ayah circle to mark as read',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          if (state is SurahWordByWordLoaded) {
            return _buildWordByWordContent(
              context,
              state.surahMeta,
              state.ayahs,
              state.preferences,
              state.bookmarks,
              state.bismillahAyah,
            );
          }

          // Fallback: still loading (initial QuranLoading or state not yet emitted)
          return _buildLoadingSkeletons();
        },
      ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // Helper to wrap entire Scaffold body with floating player
  Widget _wrapWithGlobalPlayer(Widget body) {
    return Stack(
      children: [
        body,
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GlobalTafseerPlayerWidget(),
        ),
      ],
    );
  }

  void _scrollToActiveAyah() {
    final activeAyah = _vbvController.state.currentAyahInSurah;
    final key = _ayahKeys[activeAyah];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.1, // Show a bit of the top
      );
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // BOTTOM BAR — shows VbV bar when active, else tafseer player
  // ────────────────────────────────────────────────────────────────────────
  Widget? _buildBottomBar() {
    final vbvActive = _vbvController.state.isActive;
    if (vbvActive) {
      return VersePlaybackBar(
        controller: _vbvController,
        surahName: widget.surah.englishName,
        onSettingsTap: _showVersePlaybackSettings,
        onClose: () => setState(() {}),
        onBarTap: _scrollToActiveAyah,
      );
    }
    return null;
  }

  // ────────────────────────────────────────────────────────────────────────
  // APP BAR
  // ────────────────────────────────────────────────────────────────────────
  AppBar _buildAppBar(BuildContext context, ReadingPreferences preferences) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black87),
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark_border, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Page $_currentPage',
                  style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            Text(
              'Juz $_currentJuz / Hizb $_currentHizb',
              style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(62.0),
        child: Column(
          children: [
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${widget.surah.number}. ${widget.surah.englishName}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // ─── Segmented Mode Toggle ───
                  _buildModeSelector(preferences),
                  const Spacer(),
                  IconButton(
                    iconSize: 17,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    icon: const Icon(Icons.settings, color: Color(0xFF00BFA5)),
                    tooltip: 'Settings',
                    onPressed: () => _showSettingsSheet(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ValueListenableBuilder<double>(
              valueListenable: _scrollProgress,
              builder: (context, progress, child) {
                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B8FB5)),
                  minHeight: 2.0,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // SHOW TAFSEER
  // ────────────────────────────────────────────────────────────────────────
  void _showTafseer(BuildContext context, Ayah ayah) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TafseerBottomSheet(
        ayah: ayah,
        surahNumber: widget.surah.number,
        surahName: widget.surah.name,
        totalAyahs: widget.surah.ayahs?.length ?? 286,
      ),
    ).then((_) {
      // Refresh to ensure persistent player shows up if started
      setState((){});
    });
  }

  Widget _buildModeSelector(ReadingPreferences preferences) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeIcon(ReadingDisplayMode.arabicWithTranslation, Icons.format_list_bulleted, preferences.displayMode),
          _modeIcon(ReadingDisplayMode.arabicOnly, Icomoon.arabicOnly, preferences.displayMode),
          _modeIcon(ReadingDisplayMode.wordByWord, CustomIconsV2.wordByWord, preferences.displayMode),
        ],
      ),
    );
  }

  Widget _modeIcon(ReadingDisplayMode mode, IconData icon, ReadingDisplayMode current) {
    final isSelected = current == mode;
    return GestureDetector(
      onTap: () {
        context.read<QuranBloc>().add(ChangeReadingModeEvent(mode: mode));
        if (mode == ReadingDisplayMode.wordByWord) {
          context.read<QuranBloc>().add(LoadSurahWordByWordEvent(surahNumber: widget.surah.number));
        } else {
          context.read<QuranBloc>().add(LoadSurahEvent(surahNumber: widget.surah.number));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF90BDE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : Colors.black54,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // ARABIC + TRANSLATION  /  TAJWEED mode
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildSurahContent(
      BuildContext context,
      Surah surah,
      ReadingPreferences prefs,
      List<String> bookmarks,
      Ayah? bismillahAyah,
      ) {
    
    // Preview for Arabic Only mode using the Mushaf Layout
    if (prefs.displayMode == ReadingDisplayMode.arabicOnly) {
      return Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            cacheExtent: 500,
            slivers: [
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: MushafPagePreview(
                  surah: surah,
                  recitationController: _recitationController,
                  onAyahMarkerTap: (ayahNumber) {
                    context.read<QuranBloc>().add(
                      SaveLastReadEvent(
                        surahNumber: surah.number,
                        ayahNumber: ayahNumber,
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Saved Surah ${surah.englishName}, Ayah $ayahNumber as last read'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: const Color(0xFF6B8FB5),
                      ),
                    );
                  },
                ),
              )),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
          // ─── Golden Play FAB ───
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: _buildRecitationFab(),
            ),
          ),
        ],
      );
    }

    final ayahs = surah.ayahs ?? [];

    return CustomScrollView(
      controller: _scrollController,
      cacheExtent: 500, // Pre-render 500px above/below viewport
      slivers: [
        // Bismillah header / full card
        SliverToBoxAdapter(
          child: _buildTopBismillahHeader(
            surahNumber: surah.number,
            totalAyahs: surah.numberOfAyahs,
            preferences: prefs,
            bismillahAyah: bismillahAyah,
          ),
        ),

        // Ayahs
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final ayah = ayahs[index];
              final isBookmarked = bookmarks.contains(
                '${surah.number}:${ayah.numberInSurah}',
              );

              // Tajweed mode
              if (prefs.displayMode == ReadingDisplayMode.tajweed ||
                  prefs.showTajweed) {
                final vbvState = _vbvController.state;
                final isActiveVbV = vbvState.isActive &&
                    vbvState.surahNumber == surah.number &&
                    vbvState.currentAyahInSurah == ayah.numberInSurah;
                return RepaintBoundary(
                  child: TajweedAyahWidget(
                    key: _keyForAyah(ayah.numberInSurah),
                    ayah: ayah,
                    surahNumber: surah.number,
                    preferences: prefs,
                    isBookmarked: isBookmarked,
                    onBookmarkToggle: () => _toggleBookmark(
                      context,
                      surah.number,
                      ayah.numberInSurah,
                      isBookmarked,
                    ),
                    onVisible: () {
                      _lastReadDebouncer?.cancel();
                      _lastReadDebouncer = Timer(const Duration(seconds: 2), () {
                        context.read<QuranBloc>().add(
                          SaveLastReadEvent(
                            surahNumber: surah.number,
                            ayahNumber: ayah.numberInSurah,
                          ),
                        );
                      });
                    },
                    onTafseerTap: () => _showTafseer(context, ayah),
                    isVbVActive: isActiveVbV,
                    isVbVPlaying: vbvState.isPlaying,
                    onVbVPlay: () {
                      if (isActiveVbV && vbvState.isPaused) {
                        _vbvController.resume();
                      } else {
                        QuranAudioService().stopAyah();
                        QuranAudioService().stopTafseer();
                        _vbvController.start(
                          surahNumber: surah.number,
                          startAyah: ayah.numberInSurah,
                          totalAyahs: ayahs.length,
                        );
                      }
                    },
                    onVbVPause: () {
                      _vbvController.pause();
                    },
                    onReciterChanged: () {
                      _vbvController.updateConfig(
                        _vbvController.config.copyWith(reciter: QuranAudioService().selectedReciter)
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                );
              }

              // Arabic Only / Arabic + Translation
              final vbvState = _vbvController.state;
              final isActiveVbV = vbvState.isActive &&
                  vbvState.surahNumber == surah.number &&
                  vbvState.currentAyahInSurah == ayah.numberInSurah;
              return _StandardAyahCard(
                key: _keyForAyah(ayah.numberInSurah),
                ayah: ayah,
                surahNumber: surah.number,
                preferences: prefs,
                isBookmarked: isBookmarked,
                onBookmarkToggle: () => _toggleBookmark(
                  context,
                  surah.number,
                  ayah.numberInSurah,
                  isBookmarked,
                ),
                onTafseerTap: () => _showTafseer(context, ayah),
                isVbVActive: isActiveVbV,
                isVbVPlaying: vbvState.isPlaying,
                onVbVPlay: () {
                  if (isActiveVbV && vbvState.isPaused) {
                    _vbvController.resume();
                  } else {
                    QuranAudioService().stopAyah();
                    QuranAudioService().stopTafseer();
                    _vbvController.start(
                      surahNumber: surah.number,
                      startAyah: ayah.numberInSurah,
                      totalAyahs: ayahs.length,
                    );
                  }
                },
                onVbVPause: () {
                  _vbvController.pause();
                },
                onReciterChanged: () {
                  _vbvController.updateConfig(
                    _vbvController.config.copyWith(reciter: QuranAudioService().selectedReciter)
                  );
                  if (mounted) setState(() {});
                },
              );
            },
            childCount: ayahs.length,
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  // ─── Bismillah URL builder ──────────────────────────────────────────────
  // Returns the Surah 1 Ayah 1 audio URL for the selected reciter.
  String _getBismillahUrl() {
    final id = QuranAudioService().selectedReciter.id;
    const cdnPaths = <String, String>{
      'alafasy':         'ar.alafasy',
      'mahermuaiqly':    'ar.mahermuaiqly',
      'husary':          'ar.husary',
      'husary_mujawwad': 'ar.husarymujawwad',
      'hudhaify':        'ar.hudhaify',
      'muhammadayyoub':  'ar.muhammadayyoub',
      'muhammadjibreel': 'ar.muhammadjibreel',
      'ahmedajamy':      'ar.ahmedajamy',
      'shaatree':        'ar.shaatree',
    };
    const quranComPaths = <String, String>{
      'abdulbasit_mujawwad': 'AbdulBaset/Mujawwad/mp3',
      'abdulbasit_murattal': 'AbdulBaset/Murattal/mp3',
      'sudais':              'Sudais/mp3',
      'shuraim':             'Shuraym/mp3',
      'hanirifai':           'Rifai/mp3',
      'minshawi_mujawwad':   'Minshawi/Mujawwad/mp3',
      'minshawi_murattal':   'Minshawi/Murattal/mp3',
    };
    if (cdnPaths.containsKey(id)) {
      return 'https://cdn.islamic.network/quran/audio/128/${cdnPaths[id]}/1.mp3';
    }
    if (quranComPaths.containsKey(id)) {
      return 'https://verses.quran.com/${quranComPaths[id]}/001001.mp3';
    }
    return 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3';
  }

  // ─── Play bismillah then start chapter recitation ───────────────────────
  Future<void> _playBismillahThenRecite() async {
    final surahNum = widget.surah.number;
    final needsBismillah = surahNum != 1 && surahNum != 9;

    if (needsBismillah && _bismillahPlayer != null) {
      try {
        _bismillahPlaying = true;
        if (mounted) setState(() {});

        await _bismillahPlayer!.setUrl(_getBismillahUrl());
        await _bismillahPlayer!.play();

        await _bismillahPlayer!.playerStateStream.firstWhere(
          (s) => s.processingState == ProcessingState.completed || !s.playing,
        );
      } catch (e) {
        debugPrint('⚠️ Bismillah playback failed: $e');
      } finally {
        _bismillahPlaying = false;
        await _bismillahPlayer?.stop();
        if (mounted) setState(() {});
      }
    }

    if (mounted) _recitationController.play();
  }

  // ────────────────────────────────────────────────────────────────────────
  // GOLDEN PLAY FAB (Arabic Only Mode)
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildRecitationFab() {
    final isPlaying = _recitationController.state.isPlaying;
    final isLoading = _recitationController.isLoading;
    final isActive = isPlaying || _bismillahPlaying;

    return GestureDetector(
      onTap: () {
        if (isLoading) return;
        if (!_recitationLoaded) return;

        if (isActive) {
          // Stop everything — bismillah and chapter
          _bismillahPlayer?.stop();
          _bismillahPlaying = false;
          _recitationController.pause();
          setState(() {});
        } else {
          // Play bismillah first, then chapter
          _playBismillahThenRecite();
        }
      },
      onLongPress: () {
        _bismillahPlayer?.stop();
        _bismillahPlaying = false;
        _recitationController.stop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: isActive ? 64 : 56,
        height: isActive ? 64 : 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF90BDE7), Color(0xFF6FA8D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF90BDE7).withValues(alpha: isActive ? 0.5 : 0.3),
              blurRadius: isActive ? 20 : 12,
              spreadRadius: isActive ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(isActive),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
        ),
      ),
    );
  }


  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  // WORD-BY-WORD mode (exactly image jaisa)
  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildWordByWordContent(
      BuildContext context,
      Surah surahMeta,
      List<Ayah> ayahs,
      ReadingPreferences prefs,
      List<String> bookmarks,
      Ayah? bismillahAyah,
      ) {

    return CustomScrollView(
      controller: _scrollController,
      cacheExtent: 500, // Pre-render 500px above/below viewport
      slivers: [
        SliverToBoxAdapter(
          child: _buildTopBismillahHeader(
            surahNumber: surahMeta.number,
            totalAyahs: surahMeta.numberOfAyahs,
            preferences: prefs,
            bismillahAyah: bismillahAyah,
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final ayah = ayahs[index];
              final isBookmarked = bookmarks.contains(
                '${surahMeta.number}:${ayah.numberInSurah}',
              );

              return RepaintBoundary(
                child: WordByWordAyahWidget(
                  ayah: ayah,
                  surahNumber: surahMeta.number,
                  preferences: prefs,
                  isBookmarked: isBookmarked,
                  onBookmarkToggle: () => _toggleBookmark(
                    context,
                    surahMeta.number,
                    ayah.numberInSurah,
                    isBookmarked,
                  ),
                  onTafseerTap: () => _showTafseer(context, ayah),
                ),
              );
            },
            childCount: ayahs.length,
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  // STREAMING STATE: Real ayahs + skeleton cards
  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildStreamingContent(BuildContext context, SurahStreaming state) {
    final loadedAyahs = state.loadedAyahs;
    final remainingCount = state.remainingAyahs;
    final surah = state.surahMeta;
    final prefs = state.preferences;
    final bookmarks = state.bookmarks;
    final bismillahAyah = state.bismillahAyah;


    return CustomScrollView(
      controller: _scrollController,
      cacheExtent: 500,
      slivers: [
        // Bismillah header / full card
        SliverToBoxAdapter(
          child: _buildTopBismillahHeader(
            surahNumber: surah.number,
            totalAyahs: surah.numberOfAyahs,
            preferences: prefs,
            bismillahAyah: bismillahAyah,
          ),
        ),

        // Already loaded ayahs — render normally
        if (loadedAyahs.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final ayah = loadedAyahs[index];
                final isBookmarked = bookmarks.contains('${surah.number}:${ayah.numberInSurah}');
                final vbvState = _vbvController.state;
                final isActiveVbV = vbvState.isActive &&
                    vbvState.surahNumber == surah.number &&
                    vbvState.currentAyahInSurah == ayah.numberInSurah;
                return _StandardAyahCard(
                  key: _keyForAyah(ayah.numberInSurah),
                  ayah: ayah,
                  surahNumber: surah.number,
                  preferences: prefs,
                  isBookmarked: isBookmarked,
                  onBookmarkToggle: () => _toggleBookmark(
                    context, surah.number, ayah.numberInSurah, isBookmarked,
                  ),
                  onTafseerTap: () => _showTafseer(context, ayah),
                  isVbVActive: isActiveVbV,
                  isVbVPlaying: vbvState.isPlaying,
                  onVbVPlay: () {
                    if (isActiveVbV && vbvState.isPaused) {
                      _vbvController.resume();
                    } else {
                      QuranAudioService().stopAyah();
                      QuranAudioService().stopTafseer();
                      final totalAyahs = loadedAyahs.length;
                      _vbvController.start(
                        surahNumber: surah.number,
                        startAyah: ayah.numberInSurah,
                        totalAyahs: totalAyahs,
                      );
                    }
                  },
                  onVbVPause: () {
                    _vbvController.pause();
                  },
                  onReciterChanged: () {
                    _vbvController.updateConfig(
                      _vbvController.config.copyWith(reciter: QuranAudioService().selectedReciter)
                    );
                    if (mounted) setState(() {});
                  },
                );
              },
              childCount: loadedAyahs.length,
              addRepaintBoundaries: true,
            ),
          ),

        // Skeleton placeholders for remaining ayahs
        if (remainingCount > 0)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const SurahSkeletonCard(),
              childCount: remainingCount,
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  // FALLBACK LOADING SKELETONS (pure skeleton)
  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildLoadingSkeletons() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        const SliverToBoxAdapter(child: BismillahSkeletonHeader()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const SurahSkeletonCard(),
            childCount: 8, // Show 8 placeholder cards
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Widget _buildTopBismillahHeader({
    required int surahNumber,
    required int totalAyahs,
    required ReadingPreferences preferences,
    required Ayah? bismillahAyah,
  }) {
    if (surahNumber == 1 || surahNumber == 9) {
      return const SizedBox.shrink();
    }
    if (bismillahAyah != null) {
      return _BismillahAyahCard(
        ayah: bismillahAyah,
        surahNumber: surahNumber,
        totalAyahs: totalAyahs,
        preferences: preferences,
        onTafseerTap: () => _showTafseer(context, bismillahAyah),
        vbvController: _vbvController,
        onReciterChanged: () {
          _vbvController.updateConfig(
            _vbvController.config.copyWith(reciter: QuranAudioService().selectedReciter),
          );
          if (mounted) setState(() {});
        },
      );
    }
    return const BismillahSkeletonHeader();
  }

  void _toggleBookmark(
      BuildContext context,
      int surahNumber,
      int ayahNumber,
      bool isCurrentlyBookmarked,
      ) {
    if (isCurrentlyBookmarked) {
      context.read<QuranBloc>().add(
        RemoveBookmarkEvent(surahNumber: surahNumber, ayahNumber: ayahNumber),
      );
    } else {
      context.read<QuranBloc>().add(
        BookmarkAyahEvent(surahNumber: surahNumber, ayahNumber: ayahNumber),
      );
    }
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<QuranBloc>(),
        child: ReadingSettingsSheet(
          onModeChanged: (mode) {
            context.read<QuranBloc>().add(ChangeReadingModeEvent(mode: mode));
            // Reload if switching to/from word-by-word
            if (mode == ReadingDisplayMode.wordByWord) {
              context.read<QuranBloc>().add(
                LoadSurahWordByWordEvent(surahNumber: widget.surah.number),
              );
            } else {
              context.read<QuranBloc>().add(
                LoadSurahEvent(surahNumber: widget.surah.number),
              );
            }
          },
        ),
      ),
    );
  }
}

String cleanBismillahTranslation(String text) {
  final patterns = [
    RegExp(r'^In the name of Allah, the Entirely Merciful, the Especially Merciful[.:٫]?\s*', caseSensitive: false),
    RegExp(r'^In the name of Allah, Most Gracious, Most Merciful[.:٫]?\s*', caseSensitive: false),
    RegExp(r'^In the name of Allah, the Most Gracious, the Most Merciful[.:٫]?\s*', caseSensitive: false),
    RegExp(r'^In the name of Allah, the Beneficent, the Merciful[.:٫]?\s*', caseSensitive: false),
    RegExp(r'^In the name of Allah, the Compassionate, the Merciful[.:٫]?\s*', caseSensitive: false),
    RegExp(r'^In the name of Allah, the Most Beneficent, the Most Merciful[.:٫]?\s*', caseSensitive: false),
    RegExp(r'^In the Name of Allah, the Most Gracious, the Most Merciful[.:٫]?\s*', caseSensitive: false),
    RegExp(r'^In the Name of Allah, the Most Beneficent, the Most Merciful[.:٫]?\s*', caseSensitive: false),
    RegExp(r'^شروع اللہ کے نام سے جو بڑا مہربان نہایت رحم والا ہے[۔.\s]*'),
    RegExp(r'^شروع اللہ کے نام سے جو بے حد مہربان نہایت رحم والا ہے[۔.\s]*'),
    RegExp(r'^اللہ کے نام سے جو بڑا مہربان نہایت رحم والا ہے[۔.\s]*'),
    RegExp(r'^اللہ کے نام سے جو بے حد مہربان نہایت رحم والا ہے[۔.\s]*'),
    RegExp(r'^اللہ کے نام سے جو رحمن و رحیم ہے[۔.\s]*'),
    RegExp(r'^اللہ کے نام سے جو کہ بڑا مہربان نہایت رحم والا ہے[۔.\s]*'),
  ];

  String cleaned = text;
  for (final p in patterns) {
    if (p.hasMatch(cleaned)) {
      cleaned = cleaned.replaceFirst(p, '').trim();
      break;
    }
  }
  return cleaned;
}

String cleanBismillahArabic(String rawText) {
  String text = rawText.cleanArabic;
  const bismillahVariants = [
    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
    'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
    'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِيمِ',
    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
    'بِسمِ اللَّهِ الرَّحمٰنِ الرَّحيمِ',
    'بسم الله الرحمن الرحيم',
    '﷽',
  ];
  for (final variant in bismillahVariants) {
    final cleanB = variant.cleanArabic;
    if (text.startsWith(cleanB)) {
      text = text.substring(cleanB.length).trim();
      break;
    }
  }
  if (text.startsWith('۠') || text.startsWith('ۖ')) {
    text = text.substring(1).trim();
  }
  return text;
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
// BISMILLAH HEADER
// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
class _BismillahHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: const Text(
        'Ã˜Â¨Ã™ÂÃ˜Â³Ã™â€™Ã™â€¦Ã™Â Ã™Â±Ã™â€žÃ™â€žÃ™â€˜Ã™Å½Ã™â€¡Ã™Â Ã™Â±Ã™â€žÃ˜Â±Ã™â€˜Ã™Å½Ã˜Â­Ã™â€™Ã™â€¦Ã™Å½Ã™Â°Ã™â€ Ã™Â Ã™Â±Ã™â€žÃ˜Â±Ã™â€˜Ã™Å½Ã˜Â­Ã™ÂÃ™Å Ã™â€¦Ã™Â',
        style: TextStyle(
          fontFamily: 'Thuluth',
          fontSize: 32,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
// BISMILLAH FULL AYAH CARD
// Shows Surah 1:1 with all features at top of each surah (except 1 & 9)
// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
class _BismillahAyahCard extends StatelessWidget {
  final Ayah ayah;
  final int surahNumber;   // current surah being read
  final int totalAyahs;    // total ayahs of the current surah
  final ReadingPreferences preferences;
  final VoidCallback onTafseerTap;
  final VerseByVerseController vbvController;
  final VoidCallback? onReciterChanged;

  const _BismillahAyahCard({
    required this.ayah,
    required this.surahNumber,
    required this.totalAyahs,
    required this.preferences,
    required this.onTafseerTap,
    required this.vbvController,
    this.onReciterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String ayahText = ayah.text.cleanArabic;
    final String? translationText = ayah.translation;
    final vbvState = vbvController.state;
    // Active when the current surah is playing and we're on ayah 1
    final isActiveVbV = vbvState.isActive &&
        vbvState.surahNumber == surahNumber &&
        vbvState.currentAyahInSurah == 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isActiveVbV ? const Color(0xFFEBF4FD) : Colors.white,
        border: Border(
          bottom: const BorderSide(color: Color(0xFFEEEEEE)),
          left: isActiveVbV
              ? const BorderSide(color: Color(0xFF90BDE7), width: 4)
              : BorderSide.none,
        ),
        boxShadow: isActiveVbV
            ? [const BoxShadow(color: Color(0x2290BDE7), blurRadius: 8, offset: Offset(2, 0))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top toolbar Ã¢â‚¬â€ matches _StandardAyahCard exactly
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                // Play / Pause button
                GestureDetector(
                  onTap: () {
                    if (isActiveVbV && vbvState.isPlaying) {
                      vbvController.pause();
                    } else if (isActiveVbV && vbvState.isPaused) {
                      vbvController.resume();
                    } else {
                      QuranAudioService().stopAyah();
                      QuranAudioService().stopTafseer();
                      // Start from ayah 1 of the CURRENT surah
                      vbvController.start(
                        surahNumber: surahNumber,
                        startAyah: 1,
                        totalAyahs: totalAyahs,
                      );
                    }
                  },
                  child: Icon(
                    isActiveVbV && vbvState.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow_outlined,
                    color: isActiveVbV ? const Color(0xFF90BDE7) : Colors.grey,
                    size: 24,
                  ),
                ),
                const Spacer(),
                // Reciter selection
                GestureDetector(
                  onTap: () async {
                    await showReciterSelectionSheet(context);
                    onReciterChanged?.call();
                  },
                  child: const Icon(Icomoon.reciter, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 16),
                // Bookmark not needed for bismillah – just spacer to align
              ],
            ),
          ),

          // Arabic text (RTL) — Word-by-Word, Tajweed, or Standard
          if (preferences.displayMode == ReadingDisplayMode.wordByWord)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: WordByWordGrid(
                words: (ayah.ayahWords != null && ayah.ayahWords!.isNotEmpty)
                    ? ayah.ayahWords!
                    : getBismillahWords(preferences.wbwLanguage),
                preferences: preferences,
                wordColors: WordByWordAyahWidget.wordColors,
              ),
            )
          else if (preferences.displayMode == ReadingDisplayMode.tajweed || preferences.showTajweed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    text: TextSpan(
                      children: ayah.tajweedText != null
                          ? TajweedService.parseTajweedTextToSpans(
                              ayah.tajweedText!,
                              preferences.arabicFontSize,
                              'TajweedFont',
                            )
                          : _buildBismillahTajweedSegments(ayah).map((seg) {
                              return TextSpan(
                                text: seg.text,
                                style: TextStyle(
                                  color: TajweedService.getTajweedColor(seg.rule),
                                  fontSize: preferences.arabicFontSize,
                                  fontFamily: 'TajweedFont',
                                  height: 2.0,
                                ),
                              );
                            }).toList(),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ayahText,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'UthmanicHafs',
                      fontSize: preferences.arabicFontSize,
                      height: 2.0,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),

          // Transliteration
          if (preferences.showTransliteration && ayah.transliteration != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                ayah.transliteration!,
                style: TextStyle(
                  fontSize: preferences.translationFontSize - 2,
                  color: Colors.blueGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Translation
          if (preferences.displayMode != ReadingDisplayMode.arabicOnly &&
              translationText != null &&
              translationText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                translationText,
                textAlign: preferences.selectedTranslation.startsWith('ar') ||
                        preferences.selectedTranslation.startsWith('ur')
                    ? TextAlign.right
                    : TextAlign.left,
                textDirection: preferences.selectedTranslation.startsWith('ar') ||
                        preferences.selectedTranslation.startsWith('ur')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: TextStyle(
                  fontFamily: preferences.selectedTranslation.startsWith('ur')
                      ? 'Jameel Noori'
                      : (preferences.selectedTranslation.startsWith('ar')
                          ? 'DigitalKhatt'
                          : null),
                  fontSize: preferences.selectedTranslation.startsWith('ar')
                      ? preferences.translationFontSize + 4
                      : preferences.translationFontSize,
                  height: preferences.selectedTranslation.startsWith('ar') ? 2.0 : 1.6,
                  color: Colors.black87,
                ),
              ),
            ),

          // Bottom toolbar: Tafsirs & Translations
          if (preferences.displayMode != ReadingDisplayMode.arabicOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => BlocProvider.value(
                          value: context.read<QuranBloc>(),
                          child: const TranslationSelectionScreen(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CustomIconsV2.translation, color: Colors.grey, size: 18),
                        SizedBox(width: 6),
                        Text('Translations',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  InkWell(
                    onTap: onTafseerTap,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icomoon.tafseer, color: Colors.grey, size: 18),
                        SizedBox(width: 6),
                        Text('Tafsirs',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<TajweedSegment> _buildBismillahTajweedSegments(Ayah ayah) {
    final words = ayah.ayahWords;
    if (words == null || words.isEmpty) {
      return [TajweedSegment(text: ayah.text.cleanArabic, rule: TajweedRule.none)];
    }

    final segments = <TajweedSegment>[];
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.tajweedSegments != null && word.tajweedSegments!.isNotEmpty) {
        segments.addAll(word.tajweedSegments!);
      } else {
        segments.add(TajweedSegment(text: word.arabic.cleanArabic, rule: TajweedRule.none));
      }
      if (i < words.length - 1) {
        segments.add(const TajweedSegment(text: ' ', rule: TajweedRule.none));
      }
    }
    return segments;
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
// STANDARD AYAH CARD  (Arabic Only / Arabic+Translation)
// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
class _StandardAyahCard extends StatelessWidget {
  final Ayah ayah;
  final int surahNumber;
  final ReadingPreferences preferences;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onTafseerTap;
  final VoidCallback? onVbVPlay;
  final VoidCallback? onVbVPause;
  final bool isVbVActive; // this ayah is currently playing in v-b-v mode
  final bool isVbVPlaying; // is v-b-v currently playing
  final VoidCallback? onReciterChanged;

  const _StandardAyahCard({
    Key? key,
    required this.ayah,
    required this.surahNumber,
    required this.preferences,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onTafseerTap,
    this.onVbVPlay,
    this.onVbVPause,
    this.isVbVActive = false,
    this.isVbVPlaying = false,
    this.onReciterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String ayahText = ayah.text.cleanArabic;
    String? translationText = ayah.translation;

    if (ayah.numberInSurah == 1 && surahNumber != 1 && surahNumber != 9) {
      ayahText = cleanBismillahArabic(ayah.text);
      if (translationText != null && translationText.isNotEmpty) {
        translationText = cleanBismillahTranslation(translationText);
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isVbVActive ? const Color(0xFFEBF4FD) : Colors.white,
        border: Border(
          bottom: const BorderSide(color: Color(0xFFEEEEEE)),
          left: isVbVActive
              ? const BorderSide(color: Color(0xFF90BDE7), width: 4)
              : BorderSide.none,
        ),
        boxShadow: isVbVActive
            ? [const BoxShadow(color: Color(0x2290BDE7), blurRadius: 8, offset: Offset(2, 0))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  '$surahNumber:${ayah.numberInSurah}',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(width: 16),
                // Ã¢â€â‚¬Ã¢â€â‚¬ Verse-by-verse Play/Pause Ã¢â€â‚¬Ã¢â€â‚¬
                GestureDetector(
                  onTap: () {
                    if (isVbVActive && isVbVPlaying) {
                      onVbVPause?.call();
                    } else {
                      onVbVPlay?.call();
                    }
                  },
                  child: Icon(
                    isVbVActive && isVbVPlaying ? Icons.pause : Icons.play_arrow_outlined,
                    color: isVbVActive ? const Color(0xFF90BDE7) : Colors.grey,
                    size: 24,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await showReciterSelectionSheet(context);
                    onReciterChanged?.call();
                  },
                  child: const Icon(Icomoon.reciter, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 16),
                GestureDetector(onTap: onBookmarkToggle, child: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.grey, size: 20)),
              ],
            ),
          ),

          // Arabic text (RTL)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ayahText,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: preferences.arabicFontSize,
                    height: 2.0,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                // Tajweed color icon
                InkWell(
                  onTap: () {
                    context.read<QuranBloc>().add(ChangeReadingModeEvent(
                      mode: preferences.displayMode == ReadingDisplayMode.tajweed 
                        ? ReadingDisplayMode.arabicWithTranslation 
                        : ReadingDisplayMode.tajweed,
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: preferences.displayMode == ReadingDisplayMode.tajweed 
                          ? const Color(0xFF90BDE7)
                          : const Color(0xFF90BDE7).withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.palette,
                      size: 16,
                      color: preferences.displayMode == ReadingDisplayMode.tajweed 
                          ? Colors.white 
                          : const Color(0xFF90BDE7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Transliteration
          if (preferences.showTransliteration && ayah.transliteration != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                ayah.transliteration!,
                style: TextStyle(
                  fontSize: preferences.translationFontSize - 2,
                  color: Colors.blueGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Translation
          if (preferences.displayMode != ReadingDisplayMode.arabicOnly &&
              translationText != null &&
              translationText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                translationText,
                textAlign: preferences.selectedTranslation.startsWith('ar') || preferences.selectedTranslation.startsWith('ur') ? TextAlign.right : TextAlign.left,
                textDirection: preferences.selectedTranslation.startsWith('ar') || preferences.selectedTranslation.startsWith('ur') ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                  fontFamily: preferences.selectedTranslation.startsWith('ur') 
                    ? 'Jameel Noori' 
                    : (preferences.selectedTranslation.startsWith('ar') ? 'DigitalKhatt' : null),
                  fontSize: preferences.selectedTranslation.startsWith('ar') 
                    ? preferences.translationFontSize + 4 
                    : preferences.translationFontSize,
                  height: preferences.selectedTranslation.startsWith('ar') ? 2.0 : 1.6,
                  color: Colors.black87,
                ),
              ),
            ),

          // Bottom Toolbar: Tafsirs & Translations
          if (preferences.displayMode != ReadingDisplayMode.arabicOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => BlocProvider.value(
                          value: context.read<QuranBloc>(),
                          child: const TranslationSelectionScreen(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CustomIconsV2.translation, color: Colors.grey, size: 18),
                        SizedBox(width: 6),
                        Text('Translations', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  InkWell(
                    onTap: onTafseerTap,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icomoon.tafseer, color: Colors.grey, size: 18),
                        SizedBox(width: 6),
                        Text('Tafsirs', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
