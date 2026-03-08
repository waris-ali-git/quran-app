enum TafseerType { text, audio, mixed }
enum AudioPatternType { surahLevel, perAyah }

class TafseerSource {
  final String id;
  final String name;
  final String language; // ISO code: 'ur', 'en', 'ar', 'bn', 'ru', 'ku'
  final String languageLabel; // Display label: 'اردو', 'English', 'العربية' etc.
  final TafseerType type;
  final String? audioUrlPattern;
  final AudioPatternType audioPatternType;
  final int? quranComTafsirId; // Quran.com API tafsir ID (ayah-by-ayah text)
  final int? quranComTranslationId; // Quran.com API translation ID (interpretive translations)

  const TafseerSource({
    required this.id,
    required this.name,
    required this.language,
    this.languageLabel = '',
    required this.type,
    this.audioUrlPattern,
    this.audioPatternType = AudioPatternType.surahLevel,
    this.quranComTafsirId,
    this.quranComTranslationId,
  });

  bool get usesQuranComApi => quranComTafsirId != null || quranComTranslationId != null;

  // ═══════════════════════════════════════════════════
  // ALL AVAILABLE TAFSEER SOURCES
  // Sources: Quran.com API + spa5k/tafsir_api + Tanzeem.org
  // ═══════════════════════════════════════════════════
  static const List<TafseerSource> availableSources = [

    // ─────────────────────────────────────────
    // اردو  (URDU) — 6 sources
    // ─────────────────────────────────────────

    TafseerSource(
      id: 'ur-tafsir-bayan-ul-quran',
      name: 'Bayan ul Quran — Dr. Israr Ahmed',
      language: 'ur', languageLabel: 'اردو',
      type: TafseerType.mixed,
      audioPatternType: AudioPatternType.perAyah,
    ),
    TafseerSource(
      id: 'ur-israr-tanzeem-04198',
      name: 'Dr. Israr Ahmed — Tanzeem.org Audio',
      language: 'ur', languageLabel: 'اردو',
      type: TafseerType.audio,
      audioPatternType: AudioPatternType.perAyah,
    ),
    TafseerSource(
      id: 'ur-ibn-kathir-qurancom',
      name: 'Tafsir Ibn Kathir',
      language: 'ur', languageLabel: 'اردو',
      type: TafseerType.text,
      quranComTafsirId: 160,
    ),
    TafseerSource(
      id: 'ur-bayan-ul-quran-qurancom',
      name: 'Bayan ul Quran — Dr. Israr Ahmad (Text)',
      language: 'ur', languageLabel: 'اردو',
      type: TafseerType.text,
      quranComTafsirId: 159,
    ),
    TafseerSource(
      id: 'ur-fi-zilal-qurancom',
      name: 'Fi Zilal al-Quran — Sayyid Qutb',
      language: 'ur', languageLabel: 'اردو',
      type: TafseerType.text,
      quranComTafsirId: 157,
    ),
    TafseerSource(
      id: 'ur-tazkir-qurancom',
      name: 'Tazkir ul Quran — Wahiduddin Khan',
      language: 'ur', languageLabel: 'اردو',
      type: TafseerType.text,
      quranComTafsirId: 818,
    ),

    // ─────────────────────────────────────────
    // ENGLISH — 9 sources
    // ─────────────────────────────────────────

    TafseerSource(
      id: 'en-ibn-kathir-qurancom',
      name: 'Ibn Kathir (Abridged)',
      language: 'en', languageLabel: 'English',
      type: TafseerType.text,
      quranComTafsirId: 169,
    ),
    TafseerSource(
      id: 'en-maarif-qurancom',
      name: "Ma'arif al-Quran — Mufti Shafi",
      language: 'en', languageLabel: 'English',
      type: TafseerType.text,
      quranComTafsirId: 168,
    ),
    TafseerSource(
      id: 'en-tazkir-qurancom',
      name: 'Tazkir ul Quran — Wahiduddin Khan',
      language: 'en', languageLabel: 'English',
      type: TafseerType.text,
      quranComTafsirId: 817,
    ),
    // spa5k: Extra English tafseers
    TafseerSource(
      id: 'en-al-jalalayn',
      name: 'Al-Jalalayn',
      language: 'en', languageLabel: 'English',
      type: TafseerType.text,
    ),
    TafseerSource(
      id: 'en-tafsir-ibn-abbas',
      name: 'Tafsir Ibn Abbas',
      language: 'en', languageLabel: 'English',
      type: TafseerType.text,
    ),
    TafseerSource(
      id: 'en-asbab-al-nuzul-by-al-wahidi',
      name: 'Asbab Al-Nuzul — Al-Wahidi',
      language: 'en', languageLabel: 'English',
      type: TafseerType.text,
    ),
    TafseerSource(
      id: 'en-tafsir-al-tustari',
      name: 'Tafsir al-Tustari',
      language: 'en', languageLabel: 'English',
      type: TafseerType.text,
    ),
    TafseerSource(
      id: 'en-kashani-tafsir',
      name: 'Kashani Tafsir',
      language: 'en', languageLabel: 'English',
      type: TafseerType.text,
    ),
    TafseerSource(
      id: 'en-al-qushairi-tafsir',
      name: 'Al-Qushairi Tafsir',
      language: 'en', languageLabel: 'English',
      type: TafseerType.text,
    ),

    // ─────────────────────────────────────────
    // العربية  (ARABIC) — 7 sources
    // ─────────────────────────────────────────

    TafseerSource(
      id: 'ar-ibn-kathir-qurancom',
      name: 'تفسير ابن كثير — Ibn Kathir',
      language: 'ar', languageLabel: 'العربية',
      type: TafseerType.text,
      quranComTafsirId: 14,
    ),
    TafseerSource(
      id: 'ar-tabari-qurancom',
      name: 'تفسير الطبري — al-Tabari',
      language: 'ar', languageLabel: 'العربية',
      type: TafseerType.text,
      quranComTafsirId: 15,
    ),
    TafseerSource(
      id: 'ar-muyassar-qurancom',
      name: 'التفسير الميسر — Muyassar',
      language: 'ar', languageLabel: 'العربية',
      type: TafseerType.text,
      quranComTafsirId: 16,
    ),
    TafseerSource(
      id: 'ar-qurtubi-qurancom',
      name: 'تفسير القرطبي — Al-Qurtubi',
      language: 'ar', languageLabel: 'العربية',
      type: TafseerType.text,
      quranComTafsirId: 90,
    ),
    TafseerSource(
      id: 'ar-sadi-qurancom',
      name: "تفسير السعدي — Al-Sa'di",
      language: 'ar', languageLabel: 'العربية',
      type: TafseerType.text,
      quranComTafsirId: 91,
    ),
    TafseerSource(
      id: 'ar-wasit-qurancom',
      name: 'التفسير الوسيط — Al-Wasit (Tantawi)',
      language: 'ar', languageLabel: 'العربية',
      type: TafseerType.text,
      quranComTafsirId: 93,
    ),
    TafseerSource(
      id: 'ar-baghawi-qurancom',
      name: 'تفسير البغوي — Al-Baghawi',
      language: 'ar', languageLabel: 'العربية',
      type: TafseerType.text,
      quranComTafsirId: 94,
    ),

    // ─────────────────────────────────────────
    // বাংলা  (BENGALI) — 4 sources
    // ─────────────────────────────────────────

    TafseerSource(
      id: 'bn-ibn-kathir-qurancom',
      name: 'তাফসীর ইবনে কাসীর — Ibn Kathir',
      language: 'bn', languageLabel: 'বাংলা',
      type: TafseerType.text,
      quranComTafsirId: 164,
    ),
    TafseerSource(
      id: 'bn-ahsanul-bayaan-qurancom',
      name: 'তাফসীর আহসানুল বায়ান — Ahsanul Bayaan',
      language: 'bn', languageLabel: 'বাংলা',
      type: TafseerType.text,
      quranComTafsirId: 165,
    ),
    TafseerSource(
      id: 'bn-abu-bakr-zakaria-qurancom',
      name: 'তাফসীর আবু বকর জাকারিয়া — Abu Bakr Zakaria',
      language: 'bn', languageLabel: 'বাংলা',
      type: TafseerType.text,
      quranComTafsirId: 166,
    ),
    TafseerSource(
      id: 'bn-fathul-majid-qurancom',
      name: 'তাফসীর ফাতহুল মাজীদ — Fathul Majid',
      language: 'bn', languageLabel: 'বাংলা',
      type: TafseerType.text,
      quranComTafsirId: 381,
    ),

    // ─────────────────────────────────────────
    // Русский  (RUSSIAN) — 1 source
    // ─────────────────────────────────────────

    TafseerSource(
      id: 'ru-sadi-qurancom',
      name: "Тафсир Ас-Саади — Al-Sa'di",
      language: 'ru', languageLabel: 'Русский',
      type: TafseerType.text,
      quranComTafsirId: 170,
    ),

    // ─────────────────────────────────────────
    // کوردی  (KURDISH) — 1 source
    // ─────────────────────────────────────────

    TafseerSource(
      id: 'ku-rebar-qurancom',
      name: 'تەفسیری ڕێبار — Rebar Kurdish',
      language: 'ku', languageLabel: 'کوردی',
      type: TafseerType.text,
      quranComTafsirId: 804,
    ),

    // ═══════════════════════════════════════════════════
    // INTERPRETIVE TRANSLATIONS (Quran.com Translations API)
    // Scholarly translations with commentary — 20+ languages
    // ═══════════════════════════════════════════════════

    // ─────────────────────────────────────────
    // हिन्दी  (HINDI)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'hi-umari-qurancom',
      name: 'Maulana Azizul Haque al-Umari',
      language: 'hi', languageLabel: 'हिन्दी',
      type: TafseerType.text,
      quranComTranslationId: 122,
    ),

    // ─────────────────────────────────────────
    // فارسی  (PERSIAN / FARSI)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'fa-dari-qurancom',
      name: 'حسین تاجی — Hussein Taji Kal Dari',
      language: 'fa', languageLabel: 'فارسی',
      type: TafseerType.text,
      quranComTranslationId: 29,
    ),
    TafseerSource(
      id: 'fa-islamhouse-qurancom',
      name: 'اسلام هاوس — IslamHouse.com',
      language: 'fa', languageLabel: 'فارسی',
      type: TafseerType.text,
      quranComTranslationId: 135,
    ),

    // ─────────────────────────────────────────
    // پښتو  (PASHTO)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'ps-abulsalam-qurancom',
      name: 'زکریا ابوالسلام — Zakaria Abulsalam',
      language: 'ps', languageLabel: 'پښتو',
      type: TafseerType.text,
      quranComTranslationId: 118,
    ),

    // ─────────────────────────────────────────
    // Türkçe  (TURKISH)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'tr-diyanet-qurancom',
      name: 'Diyanet İşleri',
      language: 'tr', languageLabel: 'Türkçe',
      type: TafseerType.text,
      quranComTranslationId: 77,
    ),
    TafseerSource(
      id: 'tr-yazir-qurancom',
      name: 'Elmalılı Hamdi Yazır',
      language: 'tr', languageLabel: 'Türkçe',
      type: TafseerType.text,
      quranComTranslationId: 52,
    ),

    // ─────────────────────────────────────────
    // Français  (FRENCH)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'fr-montada-qurancom',
      name: 'Montada Islamic Foundation',
      language: 'fr', languageLabel: 'Français',
      type: TafseerType.text,
      quranComTranslationId: 136,
    ),
    TafseerSource(
      id: 'fr-hamidullah-qurancom',
      name: 'Muhammad Hamidullah',
      language: 'fr', languageLabel: 'Français',
      type: TafseerType.text,
      quranComTranslationId: 31,
    ),

    // ─────────────────────────────────────────
    // Deutsch  (GERMAN)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'de-bubenheim-qurancom',
      name: 'Frank Bubenheim & Nadeem',
      language: 'de', languageLabel: 'Deutsch',
      type: TafseerType.text,
      quranComTranslationId: 27,
    ),
    TafseerSource(
      id: 'de-abureda-qurancom',
      name: 'Abu Reda Muhammad ibn Ahmad',
      language: 'de', languageLabel: 'Deutsch',
      type: TafseerType.text,
      quranComTranslationId: 208,
    ),

    // ─────────────────────────────────────────
    // Español  (SPANISH)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'es-garcia-qurancom',
      name: 'Sheikh Isa Garcia',
      language: 'es', languageLabel: 'Español',
      type: TafseerType.text,
      quranComTranslationId: 83,
    ),
    TafseerSource(
      id: 'es-noor-qurancom',
      name: 'Noor International Center',
      language: 'es', languageLabel: 'Español',
      type: TafseerType.text,
      quranComTranslationId: 199,
    ),

    // ─────────────────────────────────────────
    // Italiano  (ITALIAN)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'it-piccardo-qurancom',
      name: 'Hamza Roberto Piccardo',
      language: 'it', languageLabel: 'Italiano',
      type: TafseerType.text,
      quranComTranslationId: 153,
    ),

    // ─────────────────────────────────────────
    // Português  (PORTUGUESE)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'pt-nasr-qurancom',
      name: 'Helmi Nasr',
      language: 'pt', languageLabel: 'Português',
      type: TafseerType.text,
      quranComTranslationId: 103,
    ),

    // ─────────────────────────────────────────
    // Bahasa Indonesia  (INDONESIAN)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'id-kemenag-qurancom',
      name: 'King Fahad Quran Complex',
      language: 'id', languageLabel: 'Bahasa Indonesia',
      type: TafseerType.text,
      quranComTranslationId: 134,
    ),
    TafseerSource(
      id: 'id-sabiq-qurancom',
      name: 'The Sabiq Company',
      language: 'id', languageLabel: 'Bahasa Indonesia',
      type: TafseerType.text,
      quranComTranslationId: 141,
    ),

    // ─────────────────────────────────────────
    // Bahasa Melayu  (MALAY)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'ms-basmeih-qurancom',
      name: 'Abdullah Muhammad Basmeih',
      language: 'ms', languageLabel: 'Bahasa Melayu',
      type: TafseerType.text,
      quranComTranslationId: 39,
    ),

    // ─────────────────────────────────────────
    // 日本語  (JAPANESE)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'ja-mita-qurancom',
      name: '三田了一 — Ryoichi Mita',
      language: 'ja', languageLabel: '日本語',
      type: TafseerType.text,
      quranComTranslationId: 35,
    ),

    // ─────────────────────────────────────────
    // 한국어  (KOREAN)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'ko-korean-qurancom',
      name: '한국어 번역 — Korean Translation',
      language: 'ko', languageLabel: '한국어',
      type: TafseerType.text,
      quranComTranslationId: 36,
    ),

    // ─────────────────────────────────────────
    // 中文  (CHINESE)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'zh-jian-qurancom',
      name: '马坚 — Ma Jian (Simplified)',
      language: 'zh', languageLabel: '中文',
      type: TafseerType.text,
      quranComTranslationId: 56,
    ),

    // ─────────────────────────────────────────
    // Tiếng Việt  (VIETNAMESE)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'vi-rwwad-qurancom',
      name: 'Ruwwad Center',
      language: 'vi', languageLabel: 'Tiếng Việt',
      type: TafseerType.text,
      quranComTranslationId: 220,
    ),

    // ─────────────────────────────────────────
    // ภาษาไทย  (THAI)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'th-thai-qurancom',
      name: 'Society of Institutes and Universities',
      language: 'th', languageLabel: 'ภาษาไทย',
      type: TafseerType.text,
      quranComTranslationId: 230,
    ),

    // ─────────────────────────────────────────
    // Soomaaliga  (SOMALI)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'so-abduh-qurancom',
      name: 'Mahmud Muhammad Abduh',
      language: 'so', languageLabel: 'Soomaaliga',
      type: TafseerType.text,
      quranComTranslationId: 46,
    ),

    // ─────────────────────────────────────────
    // Kiswahili  (SWAHILI)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'sw-bakr-qurancom',
      name: 'Dr. Abdullah Muhammad Abu Bakr',
      language: 'sw', languageLabel: 'Kiswahili',
      type: TafseerType.text,
      quranComTranslationId: 231,
    ),

    // ─────────────────────────────────────────
    // Hausa  (HAUSA)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'ha-gumi-qurancom',
      name: 'Abubakar Mahmoud Gumi',
      language: 'ha', languageLabel: 'Hausa',
      type: TafseerType.text,
      quranComTranslationId: 32,
    ),

    // ─────────────────────────────────────────
    // Shqip  (ALBANIAN)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'sq-nahi-qurancom',
      name: 'Hasan Efendi Nahi',
      language: 'sq', languageLabel: 'Shqip',
      type: TafseerType.text,
      quranComTranslationId: 88,
    ),

    // ─────────────────────────────────────────
    // Bosanski  (BOSNIAN)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'bs-korkut-qurancom',
      name: 'Besim Korkut',
      language: 'bs', languageLabel: 'Bosanski',
      type: TafseerType.text,
      quranComTranslationId: 126,
    ),

    // ─────────────────────────────────────────
    // Azərbaycan  (AZERBAIJANI)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'az-musayev-qurancom',
      name: 'Alikhan Musayev',
      language: 'az', languageLabel: 'Azərbaycan',
      type: TafseerType.text,
      quranComTranslationId: 75,
    ),

    // ─────────────────────────────────────────
    // Oʻzbekcha  (UZBEK)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'uz-yusuf-qurancom',
      name: 'Muhammad Sodiq Muhammad Yusuf',
      language: 'uz', languageLabel: 'Oʻzbekcha',
      type: TafseerType.text,
      quranComTranslationId: 127,
    ),

    // ─────────────────────────────────────────
    // Тоҷикӣ  (TAJIK)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'tg-mirof-qurancom',
      name: 'Khawaja Mirof & Khawaja Mir',
      language: 'tg', languageLabel: 'Тоҷикӣ',
      type: TafseerType.text,
      quranComTranslationId: 139,
    ),

    // ─────────────────────────────────────────
    // Қазақша  (KAZAKH)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'kk-altay-qurancom',
      name: 'Khalifa Altay',
      language: 'kk', languageLabel: 'Қазақша',
      type: TafseerType.text,
      quranComTranslationId: 222,
    ),

    // ─────────────────────────────────────────
    // Татарча  (TATAR)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'tt-tatar-qurancom',
      name: 'Tatar Translation',
      language: 'tt', languageLabel: 'Татарча',
      type: TafseerType.text,
      quranComTranslationId: 53,
    ),

    // ─────────────────────────────────────────
    // नेपाली  (NEPALI)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'ne-nepal-qurancom',
      name: 'Ahl Al-Hadith Central Society of Nepal',
      language: 'ne', languageLabel: 'नेपाली',
      type: TafseerType.text,
      quranComTranslationId: 108,
    ),

    // ─────────────────────────────────────────
    // தமிழ்  (TAMIL)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'ta-baqavi-qurancom',
      name: 'Abdul Hameed Baqavi',
      language: 'ta', languageLabel: 'தமிழ்',
      type: TafseerType.text,
      quranComTranslationId: 133,
    ),

    // ─────────────────────────────────────────
    // తెలుగు  (TELUGU)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'te-rahim-qurancom',
      name: 'Maulana Abder-Rahim ibn Muhammad',
      language: 'te', languageLabel: 'తెలుగు',
      type: TafseerType.text,
      quranComTranslationId: 227,
    ),

    // ─────────────────────────────────────────
    // മലയാളം  (MALAYALAM)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'ml-kunhi-qurancom',
      name: 'Abdul-Hamid Haidar & Kanhi Muhammad',
      language: 'ml', languageLabel: 'മലയാളം',
      type: TafseerType.text,
      quranComTranslationId: 224,
    ),

    // ─────────────────────────────────────────
    // ગુજરાતી  (GUJARATI)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'gu-umry-qurancom',
      name: 'Rabila Al-Umry',
      language: 'gu', languageLabel: 'ગુજરાતી',
      type: TafseerType.text,
      quranComTranslationId: 225,
    ),

    // ─────────────────────────────────────────
    // مراٹھی  (MARATHI)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'mr-ansari-qurancom',
      name: 'Muhammad Shafi Ansari',
      language: 'mr', languageLabel: 'मराठी',
      type: TafseerType.text,
      quranComTranslationId: 226,
    ),

    // ─────────────────────────────────────────
    // অসমীয়া  (ASSAMESE)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'as-habibur-qurancom',
      name: 'Shaykh Rafeeq ul Islam Habibur-Rahman',
      language: 'as', languageLabel: 'অসমীয়া',
      type: TafseerType.text,
      quranComTranslationId: 120,
    ),

    // ─────────────────────────────────────────
    // ئۇيغۇرچە  (UYGHUR)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'ug-saleh-qurancom',
      name: 'محمد صالح — Muhammad Saleh',
      language: 'ug', languageLabel: 'ئۇيغۇرچە',
      type: TafseerType.text,
      quranComTranslationId: 76,
    ),

    // ─────────────────────────────────────────
    // Tagalog  (FILIPINO)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'tl-darsalam-qurancom',
      name: 'Dar Al-Salam Center',
      language: 'tl', languageLabel: 'Tagalog',
      type: TafseerType.text,
      quranComTranslationId: 211,
    ),

    // ─────────────────────────────────────────
    // አማርኛ  (AMHARIC)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'am-sadiq-qurancom',
      name: 'Sadiq and Sani',
      language: 'am', languageLabel: 'አማርኛ',
      type: TafseerType.text,
      quranComTranslationId: 87,
    ),

    // ─────────────────────────────────────────
    // Українська  (UKRAINIAN)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'uk-yakubovic-qurancom',
      name: 'Dr. Mikhailo Yakubovic',
      language: 'uk', languageLabel: 'Українська',
      type: TafseerType.text,
      quranComTranslationId: 217,
    ),

    // ─────────────────────────────────────────
    // Polski  (POLISH)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'pl-bielawski-qurancom',
      name: 'Józef Bielawski',
      language: 'pl', languageLabel: 'Polski',
      type: TafseerType.text,
      quranComTranslationId: 42,
    ),

    // ─────────────────────────────────────────
    // Norsk  (NORWEGIAN)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'no-norwegian-qurancom',
      name: 'Norwegian Translation',
      language: 'no', languageLabel: 'Norsk',
      type: TafseerType.text,
      quranComTranslationId: 41,
    ),

    // ─────────────────────────────────────────
    // Svenska  (SWEDISH)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'sv-bernstrom-qurancom',
      name: 'Knut Bernström',
      language: 'sv', languageLabel: 'Svenska',
      type: TafseerType.text,
      quranComTranslationId: 48,
    ),

    // ─────────────────────────────────────────
    // Suomi  (FINNISH)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'fi-finnish-qurancom',
      name: 'Finnish Translation',
      language: 'fi', languageLabel: 'Suomi',
      type: TafseerType.text,
      quranComTranslationId: 30,
    ),

    // ─────────────────────────────────────────
    // Čeština  (CZECH)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'cs-czech-qurancom',
      name: 'Czech Translation',
      language: 'cs', languageLabel: 'Čeština',
      type: TafseerType.text,
      quranComTranslationId: 26,
    ),

    // ─────────────────────────────────────────
    // Română  (ROMANIAN)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'ro-grigore-qurancom',
      name: 'George Grigore',
      language: 'ro', languageLabel: 'Română',
      type: TafseerType.text,
      quranComTranslationId: 44,
    ),

    // ─────────────────────────────────────────
    // עברית  (HEBREW)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'he-darsalam-qurancom',
      name: 'Dar Al-Salam Center',
      language: 'he', languageLabel: 'עברית',
      type: TafseerType.text,
      quranComTranslationId: 233,
    ),

    // ─────────────────────────────────────────
    // سنڌي  (SINDHI)
    // ─────────────────────────────────────────
    TafseerSource(
      id: 'sd-amroti-qurancom',
      name: 'تاج محمود امروٹی — Taj Mehmood Amroti',
      language: 'sd', languageLabel: 'سنڌي',
      type: TafseerType.text,
      quranComTranslationId: 238,
    ),
  ];

  /// Get all unique language labels for filtering
  static List<String> get availableLanguages {
    final langs = <String>{};
    for (final s in availableSources) {
      if (s.languageLabel.isNotEmpty) langs.add(s.languageLabel);
    }
    return langs.toList();
  }

  /// Get sources filtered by language
  static List<TafseerSource> getSourcesByLanguage(String languageLabel) {
    return availableSources
        .where((s) => s.languageLabel == languageLabel)
        .toList();
  }
}
