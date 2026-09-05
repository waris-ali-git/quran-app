import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/language_selector_button.dart';
import '../../../core/widgets/translated_text.dart';
import '../models/ayah.dart';
import '../services/audio_service.dart';
import '../state/quran_bloc.dart';
import '../models/surah.dart';
import '../models/reading_mode.dart';
import 'reader_screen.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/widgets/no_internet_widget.dart';
import '../services/verse_by_verse_controller.dart';
import '../widgets/global_tafseer_player.dart';
import 'widgets/verse_playback_bar.dart';

class SurahListScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const SurahListScreen({super.key, this.onBack});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _lastRead;
  Map<String, dynamic>? _lastListenedVbv;
  Map<int, int> _surahProgress = {};
  List<Surah> _filteredSurahs = [];
  List<Surah> _allSurahs = [];

  @override
  void initState() {
    super.initState();
    context.read<QuranBloc>().add(const LoadSurahsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(String query) {
    if (query.isEmpty) {
      _filteredSurahs = _allSurahs;
    } else {
      _filteredSurahs = _allSurahs.where((s) {
        return s.englishName.toLowerCase().contains(query.toLowerCase()) ||
            s.name.contains(query) ||
            s.number.toString() == query;
      }).toList();
    }
  }

  void _filterSurahs(String query) {
    setState(() {
      _applyFilter(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: BlocBuilder<QuranBloc, QuranState>(
          buildWhen: (previous, current) {
            return current is SurahsLoaded ||
                current is QuranSearchResults ||
                current is QuranLoading ||
                current is QuranError;
          },
          builder: (context, state) {
            // 1. Search Results
            if (state is QuranSearchResults) {
              return _buildSearchResults(state);
            }

            if (state is SurahsLoaded) {
              _allSurahs = state.surahs;
              _lastRead = state.lastRead;
              _lastListenedVbv = state.lastListenedVbv;
              _surahProgress = state.surahProgress;
              _applyFilter(_searchController.text);
            }

            // 3. Error (only if no data)
            if (state is QuranError && _allSurahs.isEmpty) {
              return NoInternetWidget(
                message: state.message,
                onRetry: () =>
                    context.read<QuranBloc>().add(const LoadSurahsEvent()),
              );
            }

            // 4. Loading (only if no data)
            if (state is QuranLoading && _allSurahs.isEmpty) {
              return const _LoadingWidget();
            }

            // 5. Show List (from Cache or State)
            return Stack(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SearchBar(
                    controller: _searchController,
                    onChanged: _filterSurahs,
                    onSubmitted: (val) {
                      if (val.isNotEmpty) {
                        context
                            .read<QuranBloc>()
                            .add(SearchQuranEvent(query: val));
                      }
                    },
                    onBack: widget.onBack,
                  ),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              if ((_lastRead != null ||
                                      _lastListenedVbv != null) &&
                                  _searchController.text.isEmpty)
                                _LastReadBanner(
                                  lastRead: _lastRead,
                                  lastListenedVbv: _lastListenedVbv,
                                  allSurahs: _allSurahs,
                                  onContinue: _lastRead == null
                                      ? null
                                      : () {
                                          final surahNum =
                                              _lastRead!['surahNumber'] as int;
                                          final ayahNum =
                                              _lastRead!['ayahNumber'] as int;
                                          try {
                                            final surah = _allSurahs.firstWhere(
                                                (s) => s.number == surahNum);
                                            _openSurah(
                                              context,
                                              surah,
                                              ReadingDisplayMode.arabicOnly,
                                              initialAyah:
                                                  ayahNum, // Pass the exact Ayah
                                            );
                                          } catch (_) {}
                                        },
                                  onContinueListening: _lastListenedVbv == null
                                      ? null
                                      : () {
                                          final surahNum =
                                              _lastListenedVbv!['surahNumber']
                                                  as int;
                                          final ayahNum =
                                              _lastListenedVbv!['ayahNumber']
                                                  as int;
                                          try {
                                            final surah = _allSurahs.firstWhere(
                                                (s) => s.number == surahNum);
                                            _openSurah(
                                              context,
                                              surah,
                                              ReadingDisplayMode
                                                  .arabicWithTranslation,
                                              // Can be any mode really
                                              initialAyah: ayahNum,
                                              startVbvOnLoad: true,
                                            );
                                          } catch (_) {}
                                        },
                                )
                              else if (_searchController.text.isEmpty)
                                _NoLastReadPlaceholder(),
                              if (_searchController.text.isEmpty) ...[
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Revelation', // Section Header
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF2D2D2D),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '114 SURAHS', // Surah Count Label
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                        if (_filteredSurahs.isEmpty &&
                            _searchController.text.isNotEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off,
                                      size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  const TranslatedText(
                                    'یہ نام کسی سورہ ka نہیں ہے',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  LiquidGlassButton(
                                    label: 'Search in Quran text',
                                    icon: const Icon(Icons.menu_book,
                                        size: 18, color: Color(0xFF6B8FB5)),
                                    textStyle: const TextStyle(
                                        color: Color(0xFF6B8FB5), fontSize: 13),
                                    onTap: () {
                                      context.read<QuranBloc>().add(
                                          SearchQuranEvent(
                                              query: _searchController.text));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final surah = _filteredSurahs[index];

                                // Calculate progress for this surah from the progress map
                                double? completionPercentage;
                                final lastAyah = _surahProgress[surah.number];
                                if (lastAyah != null) {
                                  final totalAyahs = surah.numberOfAyahs;
                                  if (totalAyahs > 0) {
                                    completionPercentage =
                                        lastAyah / totalAyahs;
                                    // Clamp between 0 and 1
                                    completionPercentage =
                                        completionPercentage.clamp(0.0, 1.0);
                                  }
                                }

                                return _SurahListTile(
                                  surah: surah,
                                  completionPercentage: completionPercentage,
                                  onTap: (mode) => _openSurah(
                                    context,
                                    surah,
                                    mode,
                                  ),
                                );
                              },
                              childCount: _filteredSurahs.length,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              // Floating player bar — must be a direct child of Stack
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ListenableBuilder(
                  listenable: VerseByVerseController(),
                  builder: (context, _) {
                    final vbvState = VerseByVerseController().state;
                    if (vbvState.isActive) {
                      return VersePlaybackBar(
                        controller: VerseByVerseController(),
                        onSettingsTap: () {
                          try {
                            final surah = _allSurahs.firstWhere(
                                (s) => s.number == vbvState.surahNumber);
                            _openSurah(
                              context,
                              surah,
                              ReadingDisplayMode.arabicWithTranslation,
                              initialAyah: vbvState.currentAyahInSurah,
                              startVbvOnLoad: true,
                            );
                          } catch (_) {}
                        },
                        onClose: () => setState(() {}),
                        onBarTap: () {
                          try {
                            final surah = _allSurahs.firstWhere(
                                (s) => s.number == vbvState.surahNumber);
                            _openSurah(
                              context,
                              surah,
                              ReadingDisplayMode.arabicWithTranslation,
                              initialAyah: vbvState.currentAyahInSurah,
                              startVbvOnLoad: true,
                            );
                          } catch (_) {}
                        },
                      );
                    }
                    return GlobalTafseerPlayerWidget(
                      onBarTap: () {
                        final surahNum = QuranAudioService().tafseerSurahNumber;
                        if (surahNum != null) {
                          try {
                            final surah = _allSurahs.firstWhere(
                                (s) => s.number == surahNum);
                            _openSurah(
                              context,
                              surah,
                              ReadingDisplayMode.arabicWithTranslation,
                              // We don't have exact ayah, so just go to surah
                            );
                          } catch (_) {}
                        }
                      },
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults(QuranSearchResults state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.transparent,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
                onPressed: () =>
                    context.read<QuranBloc>().add(const LoadSurahsEvent()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search Results: "${state.query}"',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.results.isEmpty
              ? const Center(child: Text("No results found"))
              : ListView.builder(
                  itemCount: state.results.length,
                  itemBuilder: (context, index) {
                    final ayah = state.results[index];
                    return ListTile(
                      title: Text(ayah.text.cleanArabic,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontFamily: 'UthmanicHafs', fontSize: 20)),
                      subtitle: Text(
                        "Surah ${ayah.surah?.name ?? '?'} : Ayah ${ayah.numberInSurah}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      onTap: () {
                        if (ayah.surah != null) {
                          _openSurah(
                            context,
                            ayah.surah!,
                            ReadingDisplayMode.arabicWithTranslation,
                            initialAyah: ayah.numberInSurah,
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openSurah(
      BuildContext context, Surah surah, ReadingDisplayMode mode,
      {int? initialAyah, bool startVbvOnLoad = false}) async {
    context.read<QuranBloc>().add(ChangeReadingModeEvent(mode: mode));
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<QuranBloc>(),
          child: ReaderScreen(
            surah: surah,
            initialMode: mode,
            initialAyah: initialAyah,
            startVbvOnLoad: startVbvOnLoad,
          ),
        ),
      ),
    );
    if (context.mounted) {
      // Refresh the list to show new progress immediately
      context.read<QuranBloc>().add(const LoadSurahsEvent());
    }
  }
}

// ─── Widgets ──────────────────────────────────────────────

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6B8FB5)),
            SizedBox(height: 16),
            TranslatedText('قرآن لوڈ ہو رہا ہے...',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _LastReadBanner extends StatelessWidget {
  final Map<String, dynamic>? lastRead;
  final Map<String, dynamic>? lastListenedVbv;
  final List<Surah> allSurahs;
  final VoidCallback? onContinue;
  final VoidCallback? onContinueListening;

  const _LastReadBanner({
    this.lastRead,
    this.lastListenedVbv,
    required this.allSurahs,
    this.onContinue,
    this.onContinueListening,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the main display info from lastRead or fallback to lastListenedVbv
    final displayData = lastRead ?? lastListenedVbv;
    if (displayData == null) return const SizedBox.shrink();

    final surahNum = displayData['surahNumber'] as int;
    final ayahNum = displayData['ayahNumber'] as int;
    final juzNum = displayData['juzNumber'] as int?;

    String surahName = 'Surah $surahNum';
    int totalAyahs = 1;
    try {
      final surah = allSurahs.firstWhere((s) => s.number == surahNum);
      surahName = surah.englishName;
      totalAyahs = surah.numberOfAyahs;
    } catch (_) {}

    final progress = (ayahNum / totalAyahs).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    String subText = 'Ayah $ayahNum';
    if (juzNum != null) {
      subText += ' • Juz $juzNum';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'lib/assets/images/quran.png',
                fit: BoxFit.cover,
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bookmark,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'LAST READ',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percentage%',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    surahName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subText,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (onContinue != null)
                        Expanded(
                          child: LiquidGlassButton(
                            label: 'Continue Reading',
                            height: 48,
                            textStyle: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white),
                            glassColor: const Color(0x33FFFFFF),
                            isTransparent: true,
                            onTap: onContinue!,
                          ),
                        ),
                      if (onContinue != null && onContinueListening != null)
                        const SizedBox(width: 12),
                      if (onContinueListening != null)
                        Expanded(
                          child: LiquidGlassButton(
                            label: 'Continue Audio',
                            icon: const Icon(Icons.headphones,
                                color: Colors.white, size: 16),
                            height: 48,
                            textStyle: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white),
                            glassColor: const Color(0x33FFFFFF),
                            isTransparent: true,
                            onTap: onContinueListening!,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onBack;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF2D2D2D), // User Search Input Text
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Search Surah...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const LanguageSelectorButton(),
        ],
      ),
    );
  }
}

class _SurahListTile extends StatelessWidget {
  final Surah surah;
  final double? completionPercentage;
  final void Function(ReadingDisplayMode) onTap;

  const _SurahListTile(
      {required this.surah, this.completionPercentage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showModeSelector(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(children: [
          // Number
          SizedBox(
            width: 36,
            child: Text(
              surah.number.toString().padLeft(2, '0'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800, // Surah List Index Number
                color: const Color(0xFFD6D6D6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Middle Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah.englishName,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w500, // Main Surah Name in List
                    color: const Color(0xFF2D2D2D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${surah.englishNameTranslation.toUpperCase()} • ${surah.numberOfAyahs} VERSES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8E8E8E),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Arabic Name & Progress Bar Column
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'surah${surah.number.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                      fontFamily: 'surah-name-v2-icon',
                      fontSize: 32,
                      color: Color(0xFF2D2D2D),
                      fontFeatures: [FontFeature.enable('liga')],
                    ),
                  ),
                ),
                if (completionPercentage != null &&
                    completionPercentage! > 0) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 50,
                    // Match typical width of the arabic name icon
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: completionPercentage,
                        backgroundColor: Colors.transparent,
                        // Only show filled portion as requested
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6B8FB5)),
                        minHeight: 2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _showModeSelector(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          flex: 0,
                          child: Text(
                            surah.name,
                            style: const TextStyle(
                              fontFamily: 'UthmanicHafs',
                              fontSize: 24,
                              color: Color(0xFF6B8FB5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            surah.englishName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              // English Name in Bottom Sheet
                              color: const Color(0xFF2D2D2D),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${surah.numberOfAyahs} آیات • ${surah.revelationType}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    const TranslatedText(
                      'پڑھنے کا طریقہ منتخب کریں',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D2D2D)),
                    ),
                    const SizedBox(height: 16),

                    // Mode tiles
                    _ModeTile(
                      icon: Icons.menu_book,
                      title: 'عربی + ترجمہ',
                      subtitle: 'آیت کے نیچے ترجمہ',
                      onTap: () {
                        Navigator.pop(context);
                        onTap(ReadingDisplayMode.arabicWithTranslation);
                      },
                    ),
                    _ModeTile(
                      icon: Icons.text_fields,
                      title: 'لفظ بہ لفظ',
                      subtitle: 'ہر لفظ کے نیچے ترجمہ (جیسa تصویر میں)',
                      onTap: () {
                        Navigator.pop(context);
                        onTap(ReadingDisplayMode.wordByWord);
                      },
                    ),
                    _ModeTile(
                      icon: Icons.palette,
                      title: 'تجوید رنگ',
                      subtitle: 'تجوید کے قواعد رنگوں سے',
                      onTap: () {
                        Navigator.pop(context);
                        onTap(ReadingDisplayMode.tajweed);
                      },
                    ),
                    _ModeTile(
                      icon: Icons.text_format,
                      title: 'صرف عربی',
                      subtitle: 'صرف عربی متن',
                      onTap: () {
                        Navigator.pop(context);
                        onTap(ReadingDisplayMode.arabicOnly);
                      },
                    ),
                  ],
                ),
              ),
            ));
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFF4F1ED),
        child: Icon(icon, color: const Color(0xFF6B8FB5)),
      ),
      title: TranslatedText(title,
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, color: const Color(0xFF2D2D2D))),
      subtitle: TranslatedText(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );
  }
}

class _NoLastReadPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1ED).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6D6D6), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Start reading to see progress here...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


