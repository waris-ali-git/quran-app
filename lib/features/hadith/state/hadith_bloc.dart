import 'package:equatable/equatable.dart';
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
}
