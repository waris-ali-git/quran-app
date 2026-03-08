# Quran App — Complete Implementation Plan

**Purpose:** Har file ka kaam, fazool cheezein, performance issues, aur code-mixing ka hisaab. Performance pe koi compromise nahi.

---

## 1. File-by-File Summary (Har file ka kaam)

### Root & Core

| File | Kaam |
|------|------|
| `lib/main.dart` | App entry: `setupDependencies()`, `MultiBlocProvider` (QuranBloc, HadithBloc), `MaterialApp` with theme, `HomeScreen` as home. |
| `lib/core/di.dart` | GetIt setup: PreferencesService init, Hive init + **quran_cache clear on every boot**, Dio + LogInterceptor, QuranService/TafseerService/HadithService, QuranBloc/HadithBloc. |

### Home

| File | Kaam |
|------|------|
| `lib/features/home/screens/home_screen.dart` | Home UI: 2 buttons — Al-Quran → `SurahListScreen`, Hadith → `HadithBooksScreen`. |

### Quran — Models

| File | Kaam |
|------|------|
| `lib/features/quran/models/ayah.dart` | Ayah, AyahWord, TajweedSegment, TajweedRule; fromJson/fromQuranComJson; copyWith; word-level tajweed parsing. |
| `lib/features/quran/models/surah.dart` | Surah model; fromJson (AlQuran.cloud), fromQuranComJson; copyWith. |
| `lib/features/quran/models/reciter.dart` | Reciter, AudioSource (alquranCdn, quranCom); getAyahAudioUrl, getTafseerAudioUrl; defaultReciters + tafseerScholars lists. |
| `lib/features/quran/models/reading_mode.dart` | ReadingDisplayMode enum, TranslationOption, kAvailableTranslations, **ReadingPreferences** (displayMode, font sizes, translation, tajweed, etc.). |
| `lib/features/quran/models/translation_edition.dart` | TranslationEdition (identifier, language, name, etc.) for API editions. |
| `lib/features/quran/models/tafseer_source.dart` | TafseerType, AudioPatternType, TafseerSource, **availableSources** (sources list), getSourcesByLanguage, availableLanguages. |

### Quran — Services

| File | Kaam |
|------|------|
| `lib/features/quran/services/quran_service.dart` | AlQuran.cloud + Quran.com: getAvailableTranslations, getAllSurahs, getSurahWithTranslation (with tafseer), getSurahWithWordByWord, getAyahAudioUrl, getReciters, searchQuran, bookmarks, lastRead, **reading preferences (save/load)**. |
| `lib/features/quran/services/audio_service.dart` | **Singleton** QuranAudioService: ayah + tafseer players, reciter/tafseer scholar from PreferencesService, playAyah/playTafseer with fallback URLs, pause/stop/seek/speed. |
| `lib/features/quran/services/tafseer_service.dart` | TafseerAudioSegment + **_tanzeemSegments** (static list), getTafseerText (spa5k/Quran.com), getTanzeemSegmentForAyah, getTanzeemSegmentsForSurah, getAudioUrl/getPerAyahAudioUrl, getFallbackUrls. |
| `lib/features/quran/services/tajweed_service.dart` | TajweedService (static): parseTajweedSegments, getTajweedColor, getTajweedRuleNameUrdu/English, buildTajweedSpans, parseTajweedTextToSpans (AlQuran.cloud codes), _parsePlainTextForHeavyLetters, getAllRules. |
| `lib/features/quran/services/preferences_service.dart` | **Singleton** PreferencesService: SharedPreferences init, get/set selected reciter & tafseer scholar by ID. |

### Quran — State (BLoC)

| File | Kaam |
|------|------|
| `lib/features/quran/state/quran_bloc.dart` | QuranBloc: Load surahs/surah/WBW, change mode/font/tajweed/transliteration/translation, bookmarks, search, last read; _mergeWbwData. |
| `lib/features/quran/state/quran_event.dart` | Events: LoadSurahs, LoadSurah, LoadSurahWordByWord, ChangeReadingMode, ChangeFontSize, ToggleTajweed, ToggleTransliteration, ChangeTranslation, Bookmark, RemoveBookmark, SearchQuran, SaveLastRead, LoadLastRead. |
| `lib/features/quran/state/quran_state.dart` | States: QuranInitial, QuranLoading, SurahsLoaded, SurahLoaded, SurahWordByWordLoaded, QuranSearchResults, QuranError, BookmarkUpdated. |

### Quran — Screens

| File | Kaam |
|------|------|
| `lib/features/quran/screens/surah_list_screen.dart` | Surah list, search bar, last-read banner, mode selector on tap; _LoadingWidget, _ErrorWidget, _LastReadBanner, _SearchBar, _SurahListTile, _ModeTile, _QuranSearchSheet. |
| `lib/features/quran/screens/reader_screen.dart` | Reader: load surah/WBW by mode, BlocConsumer for BookmarkUpdated, _buildSurahContent (Tajweed / _StandardAyahCard), _buildWordByWordContent, persistent tafseer player bar, app bar (reciter, settings), _showTafseer, _BismillahHeader, _StandardAyahCard, _AyahNumberBadge. |
| `lib/features/quran/screens/translation_selection_screen.dart` | Full-screen translation list from bloc.availableTranslations, search filter, tap to set edition. |

### Quran — Screens/Widgets

| File | Kaam |
|------|------|
| `lib/features/quran/screens/widgets/tajweed_ayah.dart` | TajweedAyahWidget (Arabic + translation with tajweed colors), TajweedLegendWidget, _LegendItem, _AyahBadge. |
| `lib/features/quran/screens/widgets/word_by_word_ayah.dart` | WordByWordAyahWidget, _WordByWordGrid, _WordCard, _AyahBadge. |
| `lib/features/quran/screens/widgets/reading_settings_sheet.dart` | ReadingSettingsSheet: mode, tajweed/transliteration toggles, font sliders, translation selector, TajweedLegendWidget; _ReadingModeSelector, _FontSizeSlider, _TranslationSelector, _ToggleTile, _SectionTitle. |
| `lib/features/quran/screens/widgets/reciter_selection_sheet.dart` | ReciterSelectionSheet (list of reciters), showReciterSelectionSheet(). |

### Quran — Widgets (feature level)

| File | Kaam |
|------|------|
| `lib/features/quran/widgets/tafseer_bottom_sheet.dart` | TafseerBottomSheet: source/language selector, audio player (Tanzeem segments), tafseer text, _buildAudioPlayer, _showTanzeemPartsSheet. |

### Hadith — Models

| File | Kaam |
|------|------|
| `lib/features/hadith/models/hadith.dart` | HadithEdition, HadithBook, HadithSection, HadithGrade, HadithItem (body/text for text). |

### Hadith — Services

| File | Kaam |
|------|------|
| `lib/features/hadith/services/hadith_service.dart` | getAvailableBooks (editions.json), getEditionSections (info.json + fallback), getHadithsBySection (per-section API + fallback), _parseSectionsFromInfoJson, _parseHadithListFromSectionJson. |

### Hadith — State

| File | Kaam |
|------|------|
| `lib/features/hadith/state/hadith_bloc.dart` | HadithBloc: LoadHadithBooks, SelectHadithBook, SelectHadithSection, ChangeHadithTranslation. |
| `lib/features/hadith/state/hadith_event.dart` | LoadHadithBooksEvent, SelectHadithBookEvent, SelectHadithSectionEvent, ChangeHadithTranslationEvent. |
| `lib/features/hadith/state/hadith_state.dart` | HadithInitial, HadithLoading, HadithBooksLoaded, HadithSectionsLoaded, HadithsLoaded, HadithError. |

### Hadith — Screens

| File | Kaam |
|------|------|
| `lib/features/hadith/screens/hadith_books_screen.dart` | Grid of hadith books, tap → HadithReaderScreen. |
| `lib/features/hadith/screens/hadith_reader_screen.dart` | Sections list → hadiths list; translation/section selectors; hadith text + grades. |

---

## 2. Fazool / Redundant Cheezein (Har file)

- **lib/core/di.dart**
  - **Fazool:** `await quranCacheBox.clear()` har boot pe — cache kabhi use nahi hoti properly; Hadith fix ke liye temporary add kiya gaya tha. **Recommendation:** Remove clear on boot; use versioned cache keys ya separate Hadith cache box instead.

- **lib/features/quran/services/audio_service.dart**
  - **Fazool:** `print()` statements (e.g. "Attempting to play tafseer audio", "Audio URL set") — production mein noise. **Recommendation:** `debugPrint` ya remove.

- **lib/features/quran/services/tafseer_service.dart**
  - **Fazool:** `print('Error fetching Tafseer...')`, `print('Chapter-level tafsir fetch failed...')`, `print('Quran.com translation fetch failed...')`. **Recommendation:** `debugPrint` ya proper logging.

- **lib/features/quran/widgets/tafseer_bottom_sheet.dart**
  - **Fazool:** `print("🔍 Generated audio URL...")`, `print("🔍 Play button - Generated URL...")`, `print("❌ Error...")`, `print("⚠️ Tafseer audio not available...")`. **Recommendation:** `debugPrint` ya remove.

- **lib/features/quran/models/reciter.dart**
  - **Fazool:** `getTafseerAudioUrl` (Archive.org URLs) — ab Tanzeem.org use ho raha hai, yeh path tafseer flow mein use nahi ho raha. **Recommendation:** Either remove ya mark deprecated; tafseer audio ab TafseerService/Tanzeem se aati hai.

- **lib/features/quran/models/reading_mode.dart**
  - **Fazool:** `kAvailableTranslations` (TranslationOption list) — app AlQuran.cloud se dynamic `getAvailableTranslations()` use karti hai; yeh static list kahi use ho rahi hai? **Recommendation:** Agar sirf TranslationSelectionScreen bloc se feed ho rahi hai to yeh list remove ya backup-only rakh sakte ho.

- **lib/features/quran/screens/reader_screen.dart**
  - **Fazool:** Duplicate import: `import '../services/audio_service.dart';` do baar (line 3 and 14). **Recommendation:** Ek remove karo.
  - **Fazool:** `setState((){});` in persistent player close — force rebuild; thoda hacky. **Recommendation:** Prefer StreamBuilder/Bloc se state drive karna.

- **lib/features/quran/screens/widgets/reading_settings_sheet.dart**
  - **Fazool:** Duplicate import: `import '../../state/quran_bloc.dart';` do baar (lines 3–4). **Recommendation:** Ek remove karo.

- **lib/features/hadith/services/hadith_service.dart**
  - **Fazool:** `print('HadithService getAvailableBooks Error...')` etc. **Recommendation:** `debugPrint` ya logging.

- **lib/features/quran/screens/surah_list_screen.dart**
  - **Fazool:** _LastReadBanner mein "جاری رکھیں" button ka `onPressed` empty — "Navigate to last read position" comment hai, implementation nahi. **Recommendation:** Implement (e.g. open same surah at last ayah) ya button hatao.

---

## 3. Performance Pe Asar Dene Wali Cheezein

- **lib/core/di.dart**
  - **Performance:** Har app start pe **pure quran_cache box clear** — har baar surah/translation/word-by-word data re-fetch. **Fix:** Cache clear hatao; Hadith ke liye alag cache key/box use karo.

- **lib/features/quran/state/quran_bloc.dart**
  - **Performance:** Tajweed mode ON hone par **surah load pe extra WBW fetch** (_mergeWbwData) — do network calls (getSurahWithTranslation + getSurahWithWordByWord). **Fix:** Optional: single combined request ya WBW cache per surah.

- **lib/features/quran/screens/reader_screen.dart**
  - **Performance:** Har ayah card pe **2x StreamBuilder** (ayahPlayerStateStream) — Arabic + Translation buttons. **Fix:** Ek parent StreamBuilder se state lo, do child IconButtons ko pass karo (rebuilds kam).

- **lib/features/quran/screens/widgets/tajweed_ayah.dart** & **word_by_word_ayah.dart**
  - **Performance:** Har ayah pe 2x StreamBuilder (QuranAudioService().ayahPlayerStateStream). **Fix:** Same — ek StreamBuilder per ayah ya list-level provider.

- **lib/features/quran/widgets/tafseer_bottom_sheet.dart**
  - **Performance:** **4x stream subscriptions** in initState (tafseerPlayerStateStream, positionStream, durationStream, speedStream) — har stream pe `setState`. **Fix:** Single combined stream ya rxdart combineLatest; kam setState.

- **lib/features/quran/services/tafseer_service.dart**
  - **Performance:** **_tanzeemSegments** list ~150+ entries — har getTanzeemSegmentForAyah/search linear scan. **Fix:** Per-surah map banao (surahNumber -> list of segments) for O(1) lookup by surah then small list search.

- **lib/features/quran/services/quran_service.dart**
  - **Performance:** getSurahWithTranslation mein **4 editions ek saath** (uthmani, tajweed, translation, tafseer) — theek hai; lekin cache key hardcoded `_tj_tf` — agar edition list change ho to cache invalidate. **Fix:** Cache key already includes translationEdition; ensure tafseer edition bhi key mein ho if variable.

- **lib/features/hadith/services/hadith_service.dart**
  - **Performance:** getEditionSections **info.json** poora fetch karta hai (sari books). **Fix:** Acceptable for one-time load; agar badi ho to server-side section-only endpoint ya lazy load per book.

- **lib/features/quran/screens/surah_list_screen.dart**
  - **Performance:** BlocBuilder har state change pe poora tree rebuild; _filteredSurahs in state update side-effect se set ho rahe hain. **Fix:** buildWhen use karo (e.g. sirf SurahsLoaded / QuranSearchResults) taake search ke time unnecessary rebuilds na hon.

---

## 4. Code Wrong File Mein / Mixed (Code-Mixing)

- **TafseerBottomSheet import path**
  - **Location:** `lib/features/quran/widgets/tafseer_bottom_sheet.dart`
  - **Issue:** `import '../../../../core/di.dart';` — 4 levels up galat hai (project root ke bahar nikal jata hai). **Sahi path:** `../../../core/di.dart` (lib tak 3 up).

- **Reading preferences: 2 jagah persist**
  - **QuranService** (quran_service.dart): getReadingPreferences / saveReadingPreferences — Hive **quran_cache** box use karta hai.
  - **PreferencesService** (preferences_service.dart): Sirf reciter & tafseer scholar — **SharedPreferences** use karta hai.
  - **Issue:** Reading prefs (displayMode, font size, translation, etc.) Hive mein; reciter/tafseer SharedPreferences mein. Same "preferences" concept do alag stores mein. **Recommendation:** Sab reading-related prefs ek hi jagah (either Hive ya SharedPreferences); ya clearly separate "app preferences" vs "reading session preferences" document karo.

- **Ayah card UI duplicate**
  - **reader_screen.dart:** _StandardAyahCard (Arabic + translation, 2 StreamBuilders, translation URL hardcoded).
  - **tajweed_ayah.dart:** TajweedAyahWidget (same row: play Arabic, play translation, tafseer, reciter, bookmark).
  - **word_by_word_ayah.dart:** WordByWordAyahWidget (same row again).
  - **Issue:** Top row (ayah number + Arabic play + Translation play + Tafseer + Bookmark) teen jagah copy-paste. **Recommendation:** Ek common widget banao, e.g. `AyahToolbar` (ayah number, isBookmarked, onBookmark, onTafseer, translationAudioUrl, currentAyahNumber, …) aur use in _StandardAyahCard, TajweedAyahWidget, WordByWordAyahWidget.

- **Translation audio URL hardcoded**
  - **reader_screen.dart** (_StandardAyahCard): `final translationAudioUrl = 'https://cdn.islamic.network/quran/audio/128/ur.khan/${ayah.number}.mp3';`
  - **tajweed_ayah.dart** & **word_by_word_ayah.dart:** Same URL.
  - **Issue:** URL 3 jagah duplicate; agar edition change karni ho to teen jagah change. **Recommendation:** Ek helper (e.g. in audio_service ya constants) `getTranslationAudioUrl(ayahNumber)` ya selected translation edition se URL.

- **Reciter selection: 2 jagah**
  - **reader_screen.dart** AppBar: "Reciter" + IconButton → showReciterSelectionSheet.
  - **tajweed_ayah.dart** & **word_by_word_ayah.dart:** Har ayah card pe "Reciter Selection" IconButton.
  - **Issue:** Reciter change karna ayah-level pe zaroori nahi; AppBar pe ek hi enough. **Recommendation:** Ayah cards se reciter button hatao; sirf AppBar pe rakho (cleaner + kam rebuild).

- **HadithBloc internal cache**
  - **hadith_bloc.dart:** `List<HadithBook> _booksCache`, `_currentBook`, `_currentTranslation`, `_currentSection` — in-memory. Hadith data service/cache layer se aati hai; bloc sirf "current selection" hold karta hai. **Issue:** Books list getter se expose ho rahi hai; consistency theek hai. Koi galat file mein code nahi, bas yeh note: Hadith "cache" service + bloc dono mein (service = network/cache, bloc = current UI state).

---

## 5. Recommended Implementation Order (Bina performance compromise)

### Phase 1 — Quick fixes (1–2 din)

1. **Imports & prints**
   - `reader_screen.dart`: Duplicate `audio_service.dart` import hatao.
   - `reading_settings_sheet.dart`: Duplicate `quran_bloc.dart` import hatao.
   - `tafseer_bottom_sheet.dart`: Import `../../../core/di.dart` fix karo.
   - Saari `print()` → `debugPrint()` (audio_service, tafseer_service, tafseer_bottom_sheet, hadith_service).

2. **Cache**
   - `di.dart`: `quranCacheBox.clear()` hatao. Agar Hadith cache issue tha to Hadith ke liye alag box/key use karo (e.g. `hadith_cache`), Quran cache rehne do.

3. **Last read**
   - `surah_list_screen.dart`: _LastReadBanner "جاری رکھیں" pe last read surah/ayah open karo (same flow as _openSurah + scroll/position if possible).

### Phase 2 — Performance (2–3 din)

4. **StreamBuilder**
   - Reader + Tajweed + WordByWord: Har ayah pe 2 StreamBuilder ki jagah ek parent StreamBuilder (ayah player state) use karo; child widgets ko state pass karo.

5. **Tafseer bottom sheet**
   - 4 stream subscriptions ko ek combined stream ya ChangeNotifier se replace karke setState kam karo.

6. **Tanzeem segments**
   - `tafseer_service.dart`: `Map<int, List<TafseerAudioSegment>>` by surahNumber banao; getTanzeemSegmentForAyah pehle surah ki list lo phir range check (faster).

7. **Surah list**
   - `surah_list_screen.dart`: BlocBuilder par `buildWhen` add karo taake sirf relevant states pe rebuild ho.

### Phase 3 — Code in sahi file / no mixing (2–3 din)

8. **Ayah toolbar**
   - Naya widget: `lib/features/quran/widgets/ayah_toolbar.dart` (ayah number, Arabic play, Translation play, Tafseer, Bookmark; StreamBuilder yahi ek baar). _StandardAyahCard, TajweedAyahWidget, WordByWordAyahWidget is toolbar ko use karein.

9. **Translation audio URL**
   - Ek jagah define karo (e.g. `QuranAudioService.getTranslationAudioUrl(ayahNumber)` ya constant + helper); reader_screen, tajweed_ayah, word_by_word_ayah mein replace karo.

10. **Reciter button**
    - Tajweed aur WordByWord ayah cards se "Reciter Selection" button hatao; sirf ReaderScreen AppBar pe rakho.

11. **Preferences**
    - Document karo: Reading prefs (Hive) vs Reciter/Tafseer (SharedPreferences). Optional: agar chaho to sab reading-related prefs SharedPreferences mein shift karke ek hi PreferencesService use karo (consistency).

### Phase 4 — Optional cleanup

12. **reciter.dart**
    - getTafseerAudioUrl agar kahi use nahi ho raha to deprecate/remove.

13. **kAvailableTranslations**
    - Agar kahi use nahi ho raha to remove; translation list sirf API se.

14. **TafseerBottomSheet**
    - Info message / warning boxes ek hi style (e.g. _InfoBanner widget) bana kar reuse karo.

---

## 6. Summary Table

| Category | Count | Action |
|----------|--------|--------|
| Fazool (prints, duplicate imports, empty handlers) | 10+ | Remove/fix in Phase 1 |
| Performance (cache clear, StreamBuilders, streams, list search) | 7 | Phase 2 |
| Code wrong file / mixed (import path, duplicate toolbar, URL, prefs) | 6 | Phase 3 |
| Optional cleanup | 3 | Phase 4 |

**Total estimated effort:** ~8–11 din (1 developer), bina app behaviour break kiye. Performance pe koi compromise nahi — cache clear hata kar, StreamBuilder/streams optimize karke, aur duplicate UI hata kar app light aur consistent rahegi.

---

*Document version: 1.0 — Full project review.*
