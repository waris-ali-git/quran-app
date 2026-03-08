import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../models/reading_mode.dart';
import '../models/translation_edition.dart';
import '../services/quran_service.dart';

part 'quran_event.dart';
part 'quran_state.dart';

class QuranBloc extends Bloc<QuranEvent, QuranState> {
  final QuranService _quranService;

  // Current state ka snapshot rakhne ke liye (preferences persist ke liye)
  ReadingPreferences _preferences = const ReadingPreferences();
  List<String> _bookmarks = [];
  List<TranslationEdition> _availableTranslations = [];

  List<TranslationEdition> get availableTranslations => _availableTranslations;

  QuranBloc(this._quranService) : super(const QuranInitial()) {
    on<LoadSurahsEvent>(_onLoadSurahs);
    on<LoadSurahEvent>(_onLoadSurah);
    on<LoadSurahWordByWordEvent>(_onLoadSurahWordByWord);
    on<ChangeReadingModeEvent>(_onChangeReadingMode);
    on<ChangeFontSizeEvent>(_onChangeFontSize);
    on<ToggleTajweedEvent>(_onToggleTajweed);
    on<ToggleTransliterationEvent>(_onToggleTransliteration);
    on<ChangeTranslationEvent>(_onChangeTranslation);
    on<BookmarkAyahEvent>(_onBookmarkAyah);
    on<RemoveBookmarkEvent>(_onRemoveBookmark);
    on<SearchQuranEvent>(_onSearchQuran);
    on<SaveLastReadEvent>(_onSaveLastRead);
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
      final lastRead = await _quranService.getLastRead();
      _preferences = await _quranService.getReadingPreferences();
      _bookmarks = await _quranService.getBookmarks();
      _availableTranslations = await _quranService.getAvailableTranslations();

      emit(SurahsLoaded(surahs: surahs, lastRead: lastRead));
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
    emit(const QuranLoading());
    try {
      final edition = event.translationEdition ?? _preferences.selectedTranslation;
      Surah surah;

      // Agar Tajweed mode active hai, to WBW data (jisme tajweed info hai) fetch karke merge karo
      if (_preferences.displayMode == ReadingDisplayMode.tajweed ||
          _preferences.showTajweed) {
        try {
          // Fetch concurrently to avoid extra loading time
          final results = await Future.wait([
            _quranService.getSurahWithTranslation(event.surahNumber, edition),
            _quranService.getSurahWithWordByWord(event.surahNumber),
          ]);
          surah = results[0] as Surah;
          final wbwAyahs = results[1] as List<Ayah>;
          surah = _mergeWbwData(surah, wbwAyahs);
        } catch (e) {
          // WBW fail hone par bhi basic surah show karo, bas tajweed nahi hogi
          debugPrint('Tajweed data load failed: $e');
          surah = await _quranService.getSurahWithTranslation(event.surahNumber, edition);
        }
      } else {
        surah = await _quranService.getSurahWithTranslation(event.surahNumber, edition);
      }

      _bookmarks = await _quranService.getBookmarks();

      emit(SurahLoaded(
        surah: surah,
        preferences: _preferences,
        bookmarks: _bookmarks,
      ));
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
      // Surah meta alag se lo (naam etc)
      final allSurahs = await _quranService.getAllSurahs();
      final surahMeta = allSurahs.firstWhere((s) => s.number == event.surahNumber);

      // Word-by-word ayahs
      final ayahs = await _quranService.getSurahWithWordByWord(event.surahNumber);
      _bookmarks = await _quranService.getBookmarks();

      emit(SurahWordByWordLoaded(
        surahMeta: surahMeta,
        ayahs: ayahs,
        preferences: _preferences,
        bookmarks: _bookmarks,
      ));
    } catch (e) {
      emit(QuranError(message: e.toString(), previousEvent: event));
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
    _emitPreferencesUpdate(emit);
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