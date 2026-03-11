import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/hadith.dart';
import '../services/hadith_service.dart';

part 'hadith_event.dart';
part 'hadith_state.dart';

class HadithBloc extends Bloc<HadithEvent, HadithState> {
  final HadithService _hadithService;

  List<HadithBook> _booksCache = [];
  HadithBook? _currentBook;
  HadithEdition? _currentTranslation;
  HadithSection? _currentSection;

  List<HadithBook> get books => _booksCache;

  HadithBloc(this._hadithService) : super(HadithInitial()) {
    on<LoadHadithBooksEvent>(_onLoadBooks);
    on<SelectHadithBookEvent>(_onSelectBook);
    on<SelectHadithSectionEvent>(_onSelectSection);
    on<ChangeHadithTranslationEvent>(_onChangeTranslation);
    on<LoadAllTranslationsForSectionEvent>(_onLoadAllTranslations);
    on<ToggleHadithLanguageEvent>(_onToggleLanguage);
  }

  Future<void> _onLoadBooks(LoadHadithBooksEvent event, Emitter<HadithState> emit) async {
    emit(HadithLoading());
    try {
      if (_booksCache.isEmpty) {
        _booksCache = await _hadithService.getAvailableBooks();
      }
      emit(HadithBooksLoaded(books: _booksCache));
    } catch (e) {
      emit(HadithError(message: e.toString()));
    }
  }

  Future<void> _onSelectBook(SelectHadithBookEvent event, Emitter<HadithState> emit) async {
    emit(HadithLoading());
    try {
      _currentBook = event.book;
      // Default translation: English if available, otherwise first
      _currentTranslation = _currentBook!.editions.firstWhere(
        (e) => e.language.toLowerCase() == 'english',
        orElse: () => _currentBook!.editions.first,
      );

      final sections = await _hadithService.getEditionSections(_currentTranslation!.name);
      
      emit(HadithSectionsLoaded(
        selectedBook: _currentBook!,
        selectedTranslation: _currentTranslation!,
        sections: sections,
      ));
    } catch (e) {
      emit(HadithError(message: e.toString()));
    }
  }

  Future<void> _onSelectSection(SelectHadithSectionEvent event, Emitter<HadithState> emit) async {
    if (_currentBook == null || _currentTranslation == null) return;
    
    emit(HadithLoading());
    try {
      _currentSection = event.section;
      final hadiths = await _hadithService.getHadithsBySection(
        _currentTranslation!.name,
        _currentSection!,
      );

      emit(HadithsLoaded(
        selectedBook: _currentBook!,
        selectedTranslation: _currentTranslation!,
        selectedSection: _currentSection!,
        hadiths: hadiths,
      ));
    } catch (e) {
      emit(HadithError(message: e.toString()));
    }
  }

  Future<void> _onChangeTranslation(ChangeHadithTranslationEvent event, Emitter<HadithState> emit) async {
    if (_currentBook == null) return;

    final newTranslation = _currentBook!.editions.firstWhere(
      (e) => e.language == event.language,
      orElse: () => _currentBook!.editions.first,
    );

    _currentTranslation = newTranslation;

    if (state is HadithsLoaded && _currentSection != null) {
      emit(HadithLoading());
      try {
        final hadiths = await _hadithService.getHadithsBySection(
          _currentTranslation!.name,
          _currentSection!,
        );

        emit(HadithsLoaded(
          selectedBook: _currentBook!,
          selectedTranslation: _currentTranslation!,
          selectedSection: _currentSection!,
          hadiths: hadiths,
        ));
      } catch (e) {
        emit(HadithError(message: e.toString()));
      }
    } else if (state is HadithSectionsLoaded || state is HadithsLoaded) {
      emit(HadithLoading());
      try {
        final sections = await _hadithService.getEditionSections(_currentTranslation!.name);
        
        emit(HadithSectionsLoaded(
          selectedBook: _currentBook!,
          selectedTranslation: _currentTranslation!,
          sections: sections,
        ));
      } catch (e) {
        emit(HadithError(message: e.toString()));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ALL TRANSLATIONS MODE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _onLoadAllTranslations(
      LoadAllTranslationsForSectionEvent event, Emitter<HadithState> emit) async {
    if (_currentBook == null) return;
    emit(HadithLoading());

    try {
      _currentSection = event.section;
      final editions = _currentBook!.editions;

      // Sort: Arabic first, then English, then Urdu, then rest alphabetically
      final sortedEditions = List<HadithEdition>.from(editions);
      sortedEditions.sort((a, b) {
        const priority = ['Arabic', 'English', 'Urdu'];
        final idxA = priority.indexWhere((p) => a.language.toLowerCase() == p.toLowerCase());
        final idxB = priority.indexWhere((p) => b.language.toLowerCase() == p.toLowerCase());
        final pA = idxA == -1 ? 999 : idxA;
        final pB = idxB == -1 ? 999 : idxB;
        if (pA != pB) return pA.compareTo(pB);
        return a.language.compareTo(b.language);
      });

      // Fetch hadiths from ALL editions in parallel
      final futures = <Future<MapEntry<String, List<HadithItem>>?>>[];
      for (final edition in sortedEditions) {
        final editionId = edition.name; // e.g. "eng-bukhari"
        final lang = edition.language;  // e.g. "English"
        if (editionId.isEmpty || lang.isEmpty) continue;

        futures.add(() async {
          try {
            final hadiths = await _hadithService.getHadithsBySection(
              editionId, event.section,
            );
            return MapEntry(lang, hadiths);
          } catch (e) {
            debugPrint('Failed to load $lang edition ($editionId): $e');
            return null;
          }
        }());
      }

      final results = await Future.wait(futures);
      final Map<String, List<HadithItem>> resultsByLang = {};
      final List<String> orderedLanguages = [];

      for (final result in results) {
        if (result != null && result.value.isNotEmpty) {
          // If same language appears twice (e.g. two Arabic editions), append suffix
          var langKey = result.key;
          if (resultsByLang.containsKey(langKey)) {
            int i = 2;
            while (resultsByLang.containsKey('$langKey ($i)')) { i++; }
            langKey = '$langKey ($i)';
          }
          resultsByLang[langKey] = result.value;
          orderedLanguages.add(langKey);
        }
      }

      // Collect all hadith numbers
      final Set<String> allHadithNums = {};
      for (final hadiths in resultsByLang.values) {
        for (final h in hadiths) {
          allHadithNums.add(h.hadithNumber.toString());
        }
      }

      // Sort numerically
      final sortedNums = allHadithNums.toList()
        ..sort((a, b) {
          final na = double.tryParse(a) ?? double.tryParse(a.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          final nb = double.tryParse(b) ?? double.tryParse(b.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          return na.compareTo(nb);
        });

      // Merge into MultiTranslationHadith objects
      final List<MultiTranslationHadith> multiHadiths = [];
      for (final num in sortedNums) {
        final translations = <String, String>{};
        List<HadithGrade> grades = [];
        dynamic arabicNumber;

        for (final lang in orderedLanguages) {
          final hadiths = resultsByLang[lang]!;
          final match = hadiths.where((h) => h.hadithNumber.toString() == num);
          if (match.isNotEmpty) {
            final h = match.first;
            if (h.text.trim().isNotEmpty) {
              translations[lang] = h.text;
            }
            if (grades.isEmpty && h.grades.isNotEmpty) {
              grades = h.grades;
            }
            arabicNumber ??= h.arabicNumber;
          }
        }

        if (translations.isNotEmpty) {
          multiHadiths.add(MultiTranslationHadith(
            hadithNumber: num,
            arabicNumber: arabicNumber,
            grades: grades,
            translations: translations,
          ));
        }
      }

      // Default visible: Arabic + English + Urdu if available
      final defaultLangs = <String>{};
      for (final lang in orderedLanguages) {
        final lower = lang.toLowerCase();
        if (lower == 'arabic' || lower == 'english' || lower == 'urdu') {
          defaultLangs.add(lang);
        }
      }
      if (defaultLangs.isEmpty && orderedLanguages.isNotEmpty) {
        defaultLangs.add(orderedLanguages.first);
      }

      emit(HadithAllTranslationsLoaded(
        selectedBook: _currentBook!,
        selectedSection: event.section,
        hadiths: multiHadiths,
        availableLanguages: orderedLanguages,
        selectedLanguages: defaultLangs,
      ));
    } catch (e) {
      emit(HadithError(message: e.toString()));
    }
  }

  void _onToggleLanguage(ToggleHadithLanguageEvent event, Emitter<HadithState> emit) {
    if (state is! HadithAllTranslationsLoaded) return;
    final current = state as HadithAllTranslationsLoaded;
    final updated = Set<String>.from(current.selectedLanguages);
    if (updated.contains(event.language)) {
      if (updated.length > 1) updated.remove(event.language);
    } else {
      updated.add(event.language);
    }

    emit(HadithAllTranslationsLoaded(
      selectedBook: current.selectedBook,
      selectedSection: current.selectedSection,
      hadiths: current.hadiths,
      availableLanguages: current.availableLanguages,
      selectedLanguages: updated,
    ));
  }
}
