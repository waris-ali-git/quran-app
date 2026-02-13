part of 'quran_bloc.dart';

abstract class QuranState extends Equatable {
  const QuranState();

  @override
  List<Object?> get props => [];
}

// ─── Initial ───────────────────────────────────
class QuranInitial extends QuranState {
  const QuranInitial();
}

// ─── Loading ───────────────────────────────────
class QuranLoading extends QuranState {
  const QuranLoading();
}

// ─── Surahs Loaded (Home screen) ───────────────
class SurahsLoaded extends QuranState {
  final List<Surah> surahs;
  final Map<String, dynamic>? lastRead;

  const SurahsLoaded({
    required this.surahs,
    this.lastRead,
  });

  @override
  List<Object?> get props => [surahs, lastRead];
}

// ─── Single Surah Loaded (Reader screen) ───────
class SurahLoaded extends QuranState {
  final Surah surah;
  final ReadingPreferences preferences;
  final List<String> bookmarks;

  const SurahLoaded({
    required this.surah,
    required this.preferences,
    required this.bookmarks,
  });

  SurahLoaded copyWith({
    Surah? surah,
    ReadingPreferences? preferences,
    List<String>? bookmarks,
  }) {
    return SurahLoaded(
      surah: surah ?? this.surah,
      preferences: preferences ?? this.preferences,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }

  @override
  List<Object?> get props => [surah, preferences, bookmarks];
}

// ─── Word-by-Word Mode ─────────────────────────
class SurahWordByWordLoaded extends QuranState {
  final Surah surahMeta;   // Naam, number etc
  final List<Ayah> ayahs;  // Words ke saath
  final ReadingPreferences preferences;
  final List<String> bookmarks;

  const SurahWordByWordLoaded({
    required this.surahMeta,
    required this.ayahs,
    required this.preferences,
    required this.bookmarks,
  });

  SurahWordByWordLoaded copyWith({
    ReadingPreferences? preferences,
    List<String>? bookmarks,
  }) {
    return SurahWordByWordLoaded(
      surahMeta: surahMeta,
      ayahs: ayahs,
      preferences: preferences ?? this.preferences,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }

  @override
  List<Object?> get props => [surahMeta, ayahs, preferences, bookmarks];
}

// ─── Search Results ────────────────────────────
class QuranSearchResults extends QuranState {
  final List<Ayah> results;
  final String query;

  const QuranSearchResults({
    required this.results,
    required this.query,
  });

  @override
  List<Object?> get props => [results, query];
}

// ─── Error ─────────────────────────────────────
class QuranError extends QuranState {
  final String message;
  final QuranEvent? previousEvent; // Retry ke liye

  const QuranError({
    required this.message,
    this.previousEvent,
  });

  @override
  List<Object?> get props => [message];
}

// ─── Bookmark Updated ──────────────────────────
class BookmarkUpdated extends QuranState {
  final List<String> bookmarks;
  final bool isBookmarked;
  final int surahNumber;
  final int ayahNumber;

  const BookmarkUpdated({
    required this.bookmarks,
    required this.isBookmarked,
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  List<Object?> get props => [bookmarks, isBookmarked, surahNumber, ayahNumber];
}