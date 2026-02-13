part of 'quran_bloc.dart';

abstract class QuranEvent extends Equatable {
  const QuranEvent();

  @override
  List<Object?> get props => [];
}

/// App start pe sari Surahs load karo
class LoadSurahsEvent extends QuranEvent {
  const LoadSurahsEvent();
}

/// Kisi Surah ko open karo (Arabic + Translation)
class LoadSurahEvent extends QuranEvent {
  final int surahNumber;
  final String? translationEdition;

  const LoadSurahEvent({
    required this.surahNumber,
    this.translationEdition,
  });

  @override
  List<Object?> get props => [surahNumber, translationEdition];
}

/// Word-by-word mode ke liye Surah load karo
class LoadSurahWordByWordEvent extends QuranEvent {
  final int surahNumber;

  const LoadSurahWordByWordEvent({required this.surahNumber});

  @override
  List<Object?> get props => [surahNumber];
}

/// Reading mode change karo
class ChangeReadingModeEvent extends QuranEvent {
  final ReadingDisplayMode mode;

  const ChangeReadingModeEvent({required this.mode});

  @override
  List<Object?> get props => [mode];
}

/// Font size adjust karo
class ChangeFontSizeEvent extends QuranEvent {
  final double arabicSize;
  final double translationSize;

  const ChangeFontSizeEvent({
    required this.arabicSize,
    required this.translationSize,
  });

  @override
  List<Object?> get props => [arabicSize, translationSize];
}

/// Tajweed on/off karo
class ToggleTajweedEvent extends QuranEvent {
  const ToggleTajweedEvent();
}

/// Transliteration on/off karo
class ToggleTransliterationEvent extends QuranEvent {
  const ToggleTransliterationEvent();
}

/// Translation language change karo
class ChangeTranslationEvent extends QuranEvent {
  final String edition;

  const ChangeTranslationEvent({required this.edition});

  @override
  List<Object?> get props => [edition];
}

/// Ayah bookmark karo
class BookmarkAyahEvent extends QuranEvent {
  final int surahNumber;
  final int ayahNumber;

  const BookmarkAyahEvent({
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  List<Object?> get props => [surahNumber, ayahNumber];
}

/// Bookmark hata do
class RemoveBookmarkEvent extends QuranEvent {
  final int surahNumber;
  final int ayahNumber;

  const RemoveBookmarkEvent({
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  List<Object?> get props => [surahNumber, ayahNumber];
}

/// Quran mein search karo
class SearchQuranEvent extends QuranEvent {
  final String query;

  const SearchQuranEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Last read position save karo
class SaveLastReadEvent extends QuranEvent {
  final int surahNumber;
  final int ayahNumber;

  const SaveLastReadEvent({
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  List<Object?> get props => [surahNumber, ayahNumber];
}

/// Last read position load karo
class LoadLastReadEvent extends QuranEvent {
  const LoadLastReadEvent();
}