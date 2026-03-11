part of 'hadith_bloc.dart';

abstract class HadithState extends Equatable {
  const HadithState();
  @override
  List<Object?> get props => [];
}

class HadithInitial extends HadithState {}

class HadithLoading extends HadithState {}

class HadithBooksLoaded extends HadithState {
  final List<HadithBook> books;
  const HadithBooksLoaded({required this.books});

  @override
  List<Object?> get props => [books];
}

class HadithSectionsLoaded extends HadithState {
  final HadithBook selectedBook;
  final HadithEdition selectedTranslation;
  final List<HadithSection> sections;

  const HadithSectionsLoaded({
    required this.selectedBook,
    required this.selectedTranslation,
    required this.sections,
  });

  @override
  List<Object?> get props => [selectedBook, selectedTranslation, sections];
}

class HadithsLoaded extends HadithState {
  final HadithBook selectedBook;
  final HadithEdition selectedTranslation;
  final HadithSection selectedSection;
  final List<HadithItem> hadiths;

  const HadithsLoaded({
    required this.selectedBook,
    required this.selectedTranslation,
    required this.selectedSection,
    required this.hadiths,
  });

  @override
  List<Object?> get props => [selectedBook, selectedTranslation, selectedSection, hadiths];
}

class HadithError extends HadithState {
  final String message;
  const HadithError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State when all translations of hadiths for a section are loaded
class HadithAllTranslationsLoaded extends HadithState {
  final HadithBook selectedBook;
  final HadithSection selectedSection;
  final List<MultiTranslationHadith> hadiths;
  final List<String> availableLanguages;
  final Set<String> selectedLanguages;

  const HadithAllTranslationsLoaded({
    required this.selectedBook,
    required this.selectedSection,
    required this.hadiths,
    required this.availableLanguages,
    required this.selectedLanguages,
  });

  @override
  List<Object?> get props => [selectedBook, selectedSection, hadiths, availableLanguages, selectedLanguages];
}
