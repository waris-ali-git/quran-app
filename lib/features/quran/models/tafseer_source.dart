enum TafseerType { text, audio, mixed }

class TafseerSource {
  final String id; // Unique slug e.g. 'ur-tafsir-bayan-ul-quran'
  final String name; // Display name e.g. 'Dr. Israr Ahmed'
  final String language; // e.g. 'ur', 'en'
  final TafseerType type;
  final String? audioUrlPattern; // Pattern to generate audio URL if applicable

  const TafseerSource({
    required this.id,
    required this.name,
    required this.language,
    required this.type,
    this.audioUrlPattern,
  });

  // Pre-defined list of available Tafseers
  static const List<TafseerSource> availableSources = [
    TafseerSource(
      id: 'ur-tafsir-bayan-ul-quran',
      name: 'Dr. Israr Ahmed (Bayan ul Quran)',
      language: 'ur',
      type: TafseerType.mixed,
      audioUrlPattern: 'https://archive.org/download/Bayan_ul_Quran_By_Dr_Israr_Ahmed_with_Urdu_Translation/{surah_000}.mp3', // Verified Archive.org collection
    ),
    TafseerSource(
      id: 'ur-tafseer-ibn-e-kaseer',
      name: 'Ibn Kathir (Urdu)',
      language: 'ur',
      type: TafseerType.text,
    ),
     TafseerSource(
      id: 'en-tafsir-maarif-ul-quran',
      name: 'Maariful Quran (English)',
      language: 'en',
      type: TafseerType.text,
    ),
    // We can add more specific Audio-only sources if needed
    TafseerSource(
      id: 'ur-taqi-usmani-audio',
      name: 'Mufti Taqi Usmani (Audio Only)',
      language: 'ur',
      type: TafseerType.audio,
      audioUrlPattern: 'https://archive.org/download/Tafseer-E-Quran-By-Mufti-Taqi-Usmani/00{surah_000}-Tafseer-E-Quran_{surah_name}.mp3', // Placeholder
    ),
  ];
}
