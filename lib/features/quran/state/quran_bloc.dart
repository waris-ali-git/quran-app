import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../models/reading_mode.dart';
import '../models/translation_edition.dart';
import '../services/quran_service.dart';
import '../screens/widgets/word_by_word_ayah.dart';

part 'quran_event.dart';
part 'quran_state.dart';

class QuranBloc extends Bloc<QuranEvent, QuranState> {
  final QuranService _quranService;

  // Current state ka snapshot rakhne ke liye (preferences persist ke liye)
  ReadingPreferences _preferences = const ReadingPreferences();
  List<String> _bookmarks = [];
  List<TranslationEdition> _availableTranslations = [];
  List<Surah> _cachedSurahs = []; // Surah meta cache to avoid re-fetching
  Ayah? _bismillahAyah; // Surah 1 Ayah 1 — cached once for all surahs

  List<TranslationEdition> get availableTranslations => _availableTranslations;

  QuranBloc(this._quranService) : super(const QuranInitial()) {
    on<LoadSurahsEvent>(_onLoadSurahs);
    on<LoadSurahEvent>(_onLoadSurah);
    on<LoadSurahWordByWordEvent>(_onLoadSurahWordByWord);
    on<ChangeReadingModeEvent>(_onChangeReadingMode);
    on<ChangeWbwLanguageEvent>(_onChangeWbwLanguage);
    on<ChangeFontSizeEvent>(_onChangeFontSize);
    on<ToggleTajweedEvent>(_onToggleTajweed);
    on<ToggleTransliterationEvent>(_onToggleTransliteration);
    on<ChangeTranslationEvent>(_onChangeTranslation);
    on<BookmarkAyahEvent>(_onBookmarkAyah);
    on<RemoveBookmarkEvent>(_onRemoveBookmark);
    on<SearchQuranEvent>(_onSearchQuran);
    on<SaveLastReadEvent>(_onSaveLastRead);
    on<SaveLastListenedVbvEvent>(_onSaveLastListenedVbv);
    on<LoadLastReadEvent>(_onLoadLastRead);
  }

  // ─────────────────────────────────────────────
  // LOAD ALL SURAHS
  // ─────────────────────────────────────────────
  Future<void> _onLoadSurahs(
      LoadSurahsEvent event,
      Emitter<QuranState> emit,
      ) async {
    emit(const QuranLoading());
    try {
      final surahs = await _quranService.getAllSurahs();
      _cachedSurahs = surahs; // Cache for WBW meta lookups
      final lastRead = await _quranService.getLastRead();
      final lastListenedVbv = await _quranService.getLastListenedVbv();
      final surahProgress = await _quranService.getAllSurahProgress();
      _preferences = await _quranService.getReadingPreferences();
      _bookmarks = await _quranService.getBookmarks();
      _availableTranslations = await _quranService.getAvailableTranslations();

      emit(SurahsLoaded(
        surahs: surahs,
        lastRead: lastRead,
        lastListenedVbv: lastListenedVbv,
        surahProgress: surahProgress,
      ));
    } catch (e) {
      emit(QuranError(message: e.toString(), previousEvent: event));
    }
  }

  // ─────────────────────────────────────────────
  // LOAD SINGLE SURAH  (Arabic + Translation)
  // ─────────────────────────────────────────────
  Future<void> _onLoadSurah(
      LoadSurahEvent event,
      Emitter<QuranState> emit,
      ) async {
    try {
      final edition = event.translationEdition ?? _preferences.selectedTranslation;
      _bookmarks = await _quranService.getBookmarks();

      // Ensure we have the Bismillah ayah cached (fetch once from Surah 1)
      await _ensureBismillahAyah(edition);

      // Cache-first: try to show cached data instantly (no loading spinner!)
      final cachedSurah = _quranService.getCachedSurah(event.surahNumber, edition);
      if (cachedSurah != null) {
        emit(SurahLoaded(
          surah: cachedSurah,
          preferences: _preferences,
          bookmarks: _bookmarks,
          isFullyLoaded: true,
          bismillahAyah: _bismillahAyah,
        ));

        // For Tajweed/Arabic: merge WBW data in background if not already present
        if (_preferences.displayMode == ReadingDisplayMode.tajweed ||
            _preferences.displayMode == ReadingDisplayMode.arabicOnly ||
            _preferences.showTajweed) {
          final hasWords = cachedSurah.ayahs?.any((a) => a.ayahWords != null && a.ayahWords!.isNotEmpty) ?? false;
          if (!hasWords) {
            try {
              final wbwAyahs = await _quranService.getSurahWithWordByWord(event.surahNumber);
              final mergedSurah = _mergeWbwData(cachedSurah, wbwAyahs);
              final memKey = 'surah_${event.surahNumber}_$edition';
              _quranService.cacheDetailSurah(memKey, mergedSurah);
              emit(SurahLoaded(
                surah: mergedSurah,
                preferences: _preferences,
                bookmarks: _bookmarks,
                isFullyLoaded: true,
                bismillahAyah: _bismillahAyah,
              ));
            } catch (e) {
              debugPrint('Background WBW merge failed: $e');
            }
          }
        }
        return;
      }

      // ── No cache: emit loading state first so UI shows skeletons (not stale QuranError) ──
      emit(const QuranLoading());

      Surah? fullSurah;

      await emit.forEach<Surah>(
        _quranService.getSurahStream(event.surahNumber, edition),
        onData: (surah) {
          final ayahs = surah.ayahs ?? [];
          final totalAyahs = surah.numberOfAyahs;

          // All ayahs received → emit final SurahLoaded
          if (ayahs.length >= totalAyahs && ayahs.isNotEmpty) {
            fullSurah = surah;
            return SurahLoaded(
              surah: surah,
              preferences: _preferences,
              bookmarks: _bookmarks,
              isFullyLoaded: true,
              bismillahAyah: _bismillahAyah,
            );
          }

          // Partial data → emit SurahStreaming (skeleton cards fill progressively)
          return SurahStreaming(
            surahMeta: surah,
            loadedAyahs: ayahs,
            totalAyahs: totalAyahs,
            preferences: _preferences,
            bookmarks: _bookmarks,
            bismillahAyah: _bismillahAyah,
          );
        },
        onError: (e, st) {
          debugPrint('Surah stream error: $e');
          return QuranError(message: e.toString(), previousEvent: event);
        },
      );

      // Store into memory LRU for instant reopen
      if (fullSurah != null) {
        final memKey = 'surah_${event.surahNumber}_$edition';
        _quranService.cacheDetailSurah(memKey, fullSurah!);
      }
    } catch (e) {
      emit(QuranError(message: e.toString(), previousEvent: event));
    }
  }

  // Helper: Basic surah ke ayahs mein WBW ayahs merge karo (for words/tajweed)
  Surah _mergeWbwData(Surah baseSurah, List<Ayah> wbwAyahs) {
    if (baseSurah.ayahs == null) return baseSurah;

    final mergedAyahs = <Ayah>[];
    // Dono lists same length honi chahiye ideally
    // Map banalo for faster lookup
    final wbwMap = {for (var a in wbwAyahs) a.numberInSurah: a};

    for (var baseAyah in baseSurah.ayahs!) {
      final wbwAyah = wbwMap[baseAyah.numberInSurah];
      if (wbwAyah != null) {
        // Base ayah (tarjuma waghaira) + Words form WBW (tajweed)
        mergedAyahs.add(baseAyah.copyWith(words: wbwAyah.ayahWords));

      } else {
        mergedAyahs.add(baseAyah);
      }
    }

    return baseSurah.copyWith(ayahs: mergedAyahs);
  }

  // ─────────────────────────────────────────────
  // LOAD WORD-BY-WORD  (Quran.com)
  // ─────────────────────────────────────────────
  Future<void> _onLoadSurahWordByWord(
      LoadSurahWordByWordEvent event,
      Emitter<QuranState> emit,
      ) async {
    emit(const QuranLoading());
    try {
      // Use cached surah meta instead of re-fetching from API
      if (_cachedSurahs.isEmpty) {
        _cachedSurahs = await _quranService.getAllSurahs();
      }
      final surahMeta = _cachedSurahs.firstWhere((s) => s.number == event.surahNumber);

      // Word-by-word ayahs
      final ayahs = await _quranService.getSurahWithWordByWord(
        event.surahNumber,
        languageCode: _preferences.wbwLanguage,
      );
      _bookmarks = await _quranService.getBookmarks();

      // Ensure bismillah ayah is cached
      await _ensureBismillahAyah(_preferences.selectedTranslation);

      emit(SurahWordByWordLoaded(
        surahMeta: surahMeta,
        ayahs: ayahs,
        preferences: _preferences,
        bookmarks: _bookmarks,
        bismillahAyah: _bismillahAyah,
      ));
    } catch (e) {
      emit(QuranError(message: e.toString(), previousEvent: event));
    }
  }

  // ─────────────────────────────
  // BISMILLAH AYAH — Fetch & cache Surah 1 Ayah 1 once
  // ─────────────────────────────
  Future<void> _ensureBismillahAyah(String edition) async {
    // If we don't have bismillah ayah or it lacks word-by-word data, try fetching WBW version first
    if (_bismillahAyah == null || _bismillahAyah!.ayahWords == null || _bismillahAyah!.ayahWords!.isEmpty) {
      try {
        final wbwAyahs = await _quranService.getSurahWithWordByWord(1, languageCode: _preferences.wbwLanguage);
        if (wbwAyahs.isNotEmpty) {
          _bismillahAyah = wbwAyahs.first;
        }
      } catch (e) {
        debugPrint('Failed to fetch WBW bismillah: $e');
      }
    }

    if (_bismillahAyah == null) {
      try {
        // Try to get Surah 1 from cache first
        final cached = _quranService.getCachedSurah(1, edition);
        if (cached != null && cached.ayahs != null && cached.ayahs!.isNotEmpty) {
          _bismillahAyah = cached.ayahs!.first;
        } else {
          // Fetch Surah 1 fresh (it's only 7 ayahs, very fast)
          final surah1 = await _quranService.getSurahWithTranslation(1, edition);
          if (surah1.ayahs != null && surah1.ayahs!.isNotEmpty) {
            _bismillahAyah = surah1.ayahs!.first;
          }
        }
      } catch (e) {
        debugPrint('Failed to fetch bismillah ayah: $e');
      }
    }

    // Attach fallback Bismillah words if ayahWords is still null or empty
    if (_bismillahAyah != null && (_bismillahAyah!.ayahWords == null || _bismillahAyah!.ayahWords!.isEmpty)) {
      _bismillahAyah = _bismillahAyah!.copyWith(
        words: getBismillahWords(_preferences.wbwLanguage),
      );
    }
  }

  // ─────────────────────────────────────────────
  // READING MODE CHANGE
  // ─────────────────────────────────────────────
  Future<void> _onChangeReadingMode(
      ChangeReadingModeEvent event,
      Emitter<QuranState> emit,
      ) async {
    _preferences = _preferences.copyWith(displayMode: event.mode);
    await _quranService.saveReadingPreferences(_preferences);
    _emitPreferencesUpdate(emit);
  }

  Future<void> _onChangeWbwLanguage(
      ChangeWbwLanguageEvent event,
      Emitter<QuranState> emit,
      ) async {
    _preferences = _preferences.copyWith(wbwLanguage: event.languageCode);
    await _quranService.saveReadingPreferences(_preferences);
    _bismillahAyah = null; // Reset so Bismillah words get re-fetched in new language
    _emitPreferencesUpdate(emit);

    // If currently showing WBW, reload it to reflect new language translations
    if (state is SurahWordByWordLoaded) {
      final currentSurah = (state as SurahWordByWordLoaded).surahMeta;
      add(LoadSurahWordByWordEvent(surahNumber: currentSurah.number));
    }
  }

  Future<void> _onChangeFontSize(
      ChangeFontSizeEvent event,
      Emitter<QuranState> emit,
      ) async {
    _preferences = _preferences.copyWith(
      arabicFontSize: event.arabicSize,
      translationFontSize: event.translationSize,
    );
    await _quranService.saveReadingPreferences(_preferences);
    _emitPreferencesUpdate(emit);
  }

  Future<void> _onToggleTajweed(
      ToggleTajweedEvent event,
      Emitter<QuranState> emit,
      ) async {
    final wasEnabled = _preferences.showTajweed;
    _preferences = _preferences.copyWith(showTajweed: !_preferences.showTajweed);
    await _quranService.saveReadingPreferences(_preferences);
    _emitPreferencesUpdate(emit);

    // Agar Tajweed ON kiya hai aur abhi SurahLoaded state hai, to reload karo taake data fetch ho
    if (!wasEnabled && _preferences.showTajweed) {
      if (state is SurahLoaded) {
        final currentSurah = (state as SurahLoaded).surah;
        add(LoadSurahEvent(surahNumber: currentSurah.number));
      }
    }
  }

  Future<void> _onToggleTransliteration(
      ToggleTransliterationEvent event,
      Emitter<QuranState> emit,
      ) async {
    _preferences = _preferences.copyWith(
      showTransliteration: !_preferences.showTransliteration,
    );
    await _quranService.saveReadingPreferences(_preferences);
    _emitPreferencesUpdate(emit);
  }

  Future<void> _onChangeTranslation(
      ChangeTranslationEvent event,
      Emitter<QuranState> emit,
      ) async {
    _preferences = _preferences.copyWith(selectedTranslation: event.edition);
    await _quranService.saveReadingPreferences(_preferences);
    
    // Auto-reload current surah to reflect translation change immediately
    final current = state;
    if (current is SurahLoaded) {
      add(LoadSurahEvent(
        surahNumber: current.surah.number,
        translationEdition: event.edition,
      ));
    } else if (current is SurahWordByWordLoaded) {
      add(LoadSurahWordByWordEvent(surahNumber: current.surahMeta.number));
    } else if (current is SurahStreaming) {
      add(LoadSurahEvent(
        surahNumber: current.surahMeta.number,
        translationEdition: event.edition,
      ));
    } else {
      _emitPreferencesUpdate(emit);
    }
  }

  // ─────────────────────────────────────────────
  // BOOKMARKS
  // ─────────────────────────────────────────────
  Future<void> _onBookmarkAyah(
      BookmarkAyahEvent event,
      Emitter<QuranState> emit,
      ) async {
    await _quranService.bookmarkAyah(event.surahNumber, event.ayahNumber);
    _bookmarks = await _quranService.getBookmarks();
    emit(BookmarkUpdated(
      bookmarks: _bookmarks,
      isBookmarked: true,
      surahNumber: event.surahNumber,
      ayahNumber: event.ayahNumber,
    ));
  }

  Future<void> _onRemoveBookmark(
      RemoveBookmarkEvent event,
      Emitter<QuranState> emit,
      ) async {
    await _quranService.removeBookmark(event.surahNumber, event.ayahNumber);
    _bookmarks = await _quranService.getBookmarks();
    emit(BookmarkUpdated(
      bookmarks: _bookmarks,
      isBookmarked: false,
      surahNumber: event.surahNumber,
      ayahNumber: event.ayahNumber,
    ));
  }

  // ─────────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────────
  Future<void> _onSearchQuran(
      SearchQuranEvent event,
      Emitter<QuranState> emit,
      ) async {
    if (event.query.trim().isEmpty) return;
    emit(const QuranLoading());
    try {
      final results = await _quranService.searchQuran(
        event.query,
        _preferences.selectedTranslation,
      );
      emit(QuranSearchResults(results: results, query: event.query));
    } catch (e) {
      emit(QuranError(message: e.toString(), previousEvent: event));
    }
  }

  // ─────────────────────────────────────────────
  // LAST READ
  // ─────────────────────────────────────────────
  Future<void> _onSaveLastRead(
      SaveLastReadEvent event,
      Emitter<QuranState> emit,
      ) async {
    await _quranService.saveLastRead(event.surahNumber, event.ayahNumber);
  }

  Future<void> _onSaveLastListenedVbv(
      SaveLastListenedVbvEvent event,
      Emitter<QuranState> emit,
      ) async {
    await _quranService.saveLastListenedVbv(event.surahNumber, event.ayahNumber);
  }

  Future<void> _onLoadLastRead(
      LoadLastReadEvent event,
      Emitter<QuranState> emit,
      ) async {
    // Surah list reload karo with last read
    add(const LoadSurahsEvent());
  }

  // ─────────────────────────────────────────────
  // HELPER — preferences update emit karo
  // ─────────────────────────────────────────────
  void _emitPreferencesUpdate(Emitter<QuranState> emit) {
    final current = state;
    if (current is SurahLoaded) {
      emit(current.copyWith(preferences: _preferences));
    } else if (current is SurahWordByWordLoaded) {
      emit(current.copyWith(preferences: _preferences));
    }
  }
}