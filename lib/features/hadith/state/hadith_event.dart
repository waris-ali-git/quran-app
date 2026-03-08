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
