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
  final Map<String, dynamic>? lastListenedVbv;
  final Map<int, int> surahProgress;

  const SurahsLoaded({
    required this.surahs,
    this.lastRead,
    this.lastListenedVbv,
    this.surahProgress = const {},
  });

  @override
  List<Object?> get props => [surahs, lastRead, lastListenedVbv, surahProgress];
}

// ─── Single Surah Loaded (Reader screen) ───────
class SurahLoaded extends QuranState {
  final Surah surah;
  final ReadingPreferences preferences;
  final List<String> bookmarks;
  final bool isFullyLoaded;
  final Ayah? bismillahAyah; // Surah 1 Ayah 1 — shown at top of every surah except 1 & 9

  const SurahLoaded({
    required this.surah,
    required this.preferences,
    required this.bookmarks,
    this.isFullyLoaded = true,
    this.bismillahAyah,
  });

  SurahLoaded copyWith({
    Surah? surah,
    ReadingPreferences? preferences,
    List<String>? bookmarks,
    bool? isFullyLoaded,
    Ayah? bismillahAyah,
  }) {
    return SurahLoaded(
      surah: surah ?? this.surah,
      preferences: preferences ?? this.preferences,
      bookmarks: bookmarks ?? this.bookmarks,
      isFullyLoaded: isFullyLoaded ?? this.isFullyLoaded,
      bismillahAyah: bismillahAyah ?? this.bismillahAyah,
    );
  }

  @override
  List<Object?> get props => [surah, preferences, bookmarks, isFullyLoaded, bismillahAyah];
}

// ─── Surah Streaming (Progressive load — skeleton fill) ─
class SurahStreaming extends QuranState {
  final Surah surahMeta;         // Name, number — instantly available
  final List<Ayah> loadedAyahs; // Ayahs received so far
  final int totalAyahs;          // Expected total (for skeleton count)
  final ReadingPreferences preferences;
  final List<String> bookmarks;
  final Ayah? bismillahAyah; // Surah 1 Ayah 1 — shown at top of every surah except 1 & 9

  const SurahStreaming({
    required this.surahMeta,
    required this.loadedAyahs,
    required this.totalAyahs,
    required this.preferences,
    required this.bookmarks,
    this.bismillahAyah,
  });

  int get remainingAyahs => (totalAyahs - loadedAyahs.length).clamp(0, totalAyahs);

  SurahStreaming copyWith({
    List<Ayah>? loadedAyahs,
  }) {
    return SurahStreaming(
      surahMeta: surahMeta,
      loadedAyahs: loadedAyahs ?? this.loadedAyahs,
      totalAyahs: totalAyahs,
      preferences: preferences,
      bookmarks: bookmarks,
      bismillahAyah: bismillahAyah,
    );
  }

  @override
  List<Object?> get props => [surahMeta, loadedAyahs, totalAyahs, preferences, bookmarks, bismillahAyah];
}

// ─── Word-by-Word Mode ─────────────────────────
class SurahWordByWordLoaded extends QuranState {
  final Surah surahMeta;   // Naam, number etc
  final List<Ayah> ayahs;  // Words ke saath
  final ReadingPreferences preferences;
  final List<String> bookmarks;
  final bool isFullyLoaded;
  final Ayah? bismillahAyah; // Surah 1 Ayah 1 — shown at top of every surah except 1 & 9

  const SurahWordByWordLoaded({
    required this.surahMeta,
    required this.ayahs,
    required this.preferences,
    required this.bookmarks,
    this.isFullyLoaded = true,
    this.bismillahAyah,
  });

  SurahWordByWordLoaded copyWith({
    ReadingPreferences? preferences,
    List<String>? bookmarks,
    bool? isFullyLoaded,
    Ayah? bismillahAyah,
  }) {
    return SurahWordByWordLoaded(
      surahMeta: surahMeta,
      ayahs: ayahs,
      preferences: preferences ?? this.preferences,
      bookmarks: bookmarks ?? this.bookmarks,
      isFullyLoaded: isFullyLoaded ?? this.isFullyLoaded,
      bismillahAyah: bismillahAyah ?? this.bismillahAyah,
    );
  }

  @override
  List<Object?> get props => [surahMeta, ayahs, preferences, bookmarks, isFullyLoaded, bismillahAyah];
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