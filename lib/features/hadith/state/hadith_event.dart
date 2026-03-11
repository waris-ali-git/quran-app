part of 'hadith_bloc.dart';

abstract class HadithEvent extends Equatable {
  const HadithEvent();
  @override
  List<Object?> get props => [];
}

class LoadHadithBooksEvent extends HadithEvent {
  const LoadHadithBooksEvent();
}

class SelectHadithBookEvent extends HadithEvent {
  final HadithBook book;
  const SelectHadithBookEvent({required this.book});

  @override
  List<Object?> get props => [book];
}

class SelectHadithSectionEvent extends HadithEvent {
  final HadithSection section;
  const SelectHadithSectionEvent({required this.section});

  @override
  List<Object?> get props => [section];
}

class ChangeHadithTranslationEvent extends HadithEvent {
  final String language;
  const ChangeHadithTranslationEvent({required this.language});

  @override
  List<Object?> get props => [language];
}

/// Load ALL available translations for a section
class LoadAllTranslationsForSectionEvent extends HadithEvent {
  final HadithSection section;
  const LoadAllTranslationsForSectionEvent({required this.section});

  @override
  List<Object?> get props => [section];
}

/// Toggle a specific language on/off in the multi-translation view
class ToggleHadithLanguageEvent extends HadithEvent {
  final String language;
  const ToggleHadithLanguageEvent({required this.language});

  @override
  List<Object?> get props => [language];
}

