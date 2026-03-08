import 'package:equatable/equatable.dart';

/// Audio source type — determines which URL pattern to use
enum AudioSource {
  /// AlQuran.cloud CDN: cdn.islamic.network/quran/audio/128/{edition}/{globalAyahNumber}.mp3
  /// Uses global ayah number (1-6236)
  alquranCdn,

  /// Quran.com / verses.quran.com: verses.quran.com/{path}/{SSSVVV}.mp3
  /// Uses surah:verse format (e.g. 001001 = Surah 1, Verse 1)
  quranCom,
}

/// Model representing a Quran reciter/scholar
class Reciter extends Equatable {
  final String id;
  final String name;
  final String localizedName;
  final String country;
  final String description;
  final String avatarUrl;
  final int priority;
  final AudioSource audioSource;

  /// For [AudioSource.alquranCdn]: edition identifier (e.g. 'ar.alafasy')
  /// For [AudioSource.quranCom]: path after verses.quran.com/ (e.g. 'Sudais/mp3')
  final String audioPath;

  const Reciter({
    required this.id,
    required this.name,
    required this.localizedName,
    required this.country,
    required this.description,
    required this.avatarUrl,
    this.priority = 100,
    this.audioSource = AudioSource.alquranCdn,
    this.audioPath = 'ar.alafasy',
  });

  @override
  List<Object?> get props => [id, name, localizedName, country, description, avatarUrl, priority, audioSource, audioPath];

  /// Build audio URL for a specific ayah.
  ///
  /// [globalAyahNumber] — 1-6236 (used by AlQuran.cloud CDN)
  /// [surahNumber] + [ayahInSurah] — needed for Quran.com URLs
  ///
  /// Callers MUST pass surahNumber & ayahInSurah so both sources work.
  String getAyahAudioUrl(int globalAyahNumber, {int? surahNumber, int? ayahInSurah}) {
    switch (audioSource) {
      case AudioSource.alquranCdn:
        return 'https://cdn.islamic.network/quran/audio/128/$audioPath/$globalAyahNumber.mp3';

      case AudioSource.quranCom:
        final s = (surahNumber ?? 1).toString().padLeft(3, '0');
        final v = (ayahInSurah ?? 1).toString().padLeft(3, '0');
        return 'https://verses.quran.com/$audioPath/$s$v.mp3';
    }
  }

  @Deprecated('Tafseer audio is now fetched from TafseerService using Tanzeem.org')
  /// Tafseer audio URL for a specific surah
  String getTafseerAudioUrl(int surahNumber, {String? edition}) {
    switch (id) {
      case 'maududi':
        return 'https://archive.org/download/Tafheem-ul-Quran-by-Syed-Abul-Ala-Moududi-Audio-MP3-CDdone/Surah%20$surahNumber.mp3';
      case 'israr':
        return 'https://archive.org/download/Quran-Tafseer-Dr-Israr-Ahmad/Surah%20$surahNumber.mp3';
      default:
        return '';
    }
  }
}

// ═══════════════════════════════════════════════
// DEFAULT RECITERS
// ═══════════════════════════════════════════════
// Verified against live CDN (200 OK) and Quran.com API.
//
// CDN working  (AudioSource.alquranCdn):
//   ar.alafasy, ar.mahermuaiqly, ar.husary, ar.husarymujawwad,
//   ar.hudhaify, ar.muhammadayyoub, ar.muhammadjibreel,
//   ar.ahmedajamy, ar.shaatree
//
// CDN blocked 403 → use Quran.com (AudioSource.quranCom):
//   Abdul Basit, Sudais, Shuraim, Hani Rifai, Minshawi, Tablawi, Husary Muallim
// ═══════════════════════════════════════════════

const List<Reciter> defaultReciters = [
  // ── 1. Mishary Rashid Al-Afasy ──────────────────
  Reciter(
    id: 'alafasy',
    name: 'Mishary Rashid Al-Afasy',
    localizedName: 'مشاری راشد العفاسی',
    country: 'Kuwait',
    description: 'Most popular reciter worldwide',
    avatarUrl: 'assets/images/reciters/alafasy.png',
    priority: 1,
    audioSource: AudioSource.alquranCdn,
    audioPath: 'ar.alafasy',
  ),

  // ── 2. Abdul Basit (Mujawwad) ───────────────────
  Reciter(
    id: 'abdulbasit_mujawwad',
    name: 'Abdul Basit Abdul Samad (Mujawwad)',
    localizedName: 'عبد الباسط عبد الصمد - مجوّد',
    country: 'Egypt',
    description: 'Classical Mujawwad recitation',
    avatarUrl: 'assets/images/reciters/abdulbasit.png',
    priority: 2,
    audioSource: AudioSource.quranCom,
    audioPath: 'AbdulBaset/Mujawwad/mp3',
  ),

  // ── 3. Abdul Basit (Murattal) ───────────────────
  Reciter(
    id: 'abdulbasit_murattal',
    name: 'Abdul Basit Abdul Samad (Murattal)',
    localizedName: 'عبد الباسط عبد الصمد - مرتل',
    country: 'Egypt',
    description: 'Classical Murattal recitation',
    avatarUrl: 'assets/images/reciters/abdulbasit.png',
    priority: 3,
    audioSource: AudioSource.quranCom,
    audioPath: 'AbdulBaset/Murattal/mp3',
  ),

  // ── 4. Abdur-Rahman As-Sudais ───────────────────
  Reciter(
    id: 'sudais',
    name: 'Abdur-Rahman As-Sudais',
    localizedName: 'عبد الرحمٰن السدیس',
    country: 'Saudi Arabia',
    description: 'Imam of Masjid al-Haram, Makkah',
    avatarUrl: 'assets/images/reciters/sudais.png',
    priority: 4,
    audioSource: AudioSource.quranCom,
    audioPath: 'Sudais/mp3',
  ),

  // ── 5. Saud Ash-Shuraim ─────────────────────────
  Reciter(
    id: 'shuraim',
    name: "Sa'ud Ash-Shuraim",
    localizedName: 'سعود الشریم',
    country: 'Saudi Arabia',
    description: 'Imam of Masjid al-Haram, Makkah',
    avatarUrl: 'assets/images/reciters/shuraim.png',
    priority: 5,
    audioSource: AudioSource.quranCom,
    audioPath: 'Shuraym/mp3',
  ),

  // ── 6. Hani Ar-Rifai ────────────────────────────
  Reciter(
    id: 'hanirifai',
    name: 'Hani Ar-Rifai',
    localizedName: 'ہانی الرفاعی',
    country: 'Saudi Arabia',
    description: 'Melodic and soothing recitation',
    avatarUrl: 'assets/images/reciters/hanirifai.png',
    priority: 6,
    audioSource: AudioSource.quranCom,
    audioPath: 'Rifai/mp3',
  ),

  // ── 7. Maher Al-Muaiqly ─────────────────────────
  Reciter(
    id: 'mahermuaiqly',
    name: 'Maher Al-Muaiqly',
    localizedName: 'ماہر المعیقلی',
    country: 'Saudi Arabia',
    description: 'Imam of Masjid al-Haram, beautiful voice',
    avatarUrl: 'assets/images/reciters/maher.png',
    priority: 7,
    audioSource: AudioSource.alquranCdn,
    audioPath: 'ar.mahermuaiqly',
  ),

  // ── 8. Mahmoud Khalil Al-Husary ─────────────────
  Reciter(
    id: 'husary',
    name: 'Mahmoud Khalil Al-Husary',
    localizedName: 'محمود خلیل الحصری',
    country: 'Egypt',
    description: 'Known for precise tajweed',
    avatarUrl: 'assets/images/reciters/husary.png',
    priority: 8,
    audioSource: AudioSource.alquranCdn,
    audioPath: 'ar.husary',
  ),

  // ── 9. Husary (Mujawwad) ────────────────────────
  Reciter(
    id: 'husary_mujawwad',
    name: 'Mahmoud Khalil Al-Husary (Mujawwad)',
    localizedName: 'محمود خلیل الحصری - مجوّد',
    country: 'Egypt',
    description: 'Mujawwad style with tajweed',
    avatarUrl: 'assets/images/reciters/husary.png',
    priority: 9,
    audioSource: AudioSource.alquranCdn,
    audioPath: 'ar.husarymujawwad',
  ),

  // ── 10. Ali Al-Hudhaify ─────────────────────────
  Reciter(
    id: 'hudhaify',
    name: 'Ali Al-Hudhaify',
    localizedName: 'علی الحذیفی',
    country: 'Saudi Arabia',
    description: 'Imam of Masjid an-Nabawi',
    avatarUrl: 'assets/images/reciters/hudhaify.png',
    priority: 10,
    audioSource: AudioSource.alquranCdn,
    audioPath: 'ar.hudhaify',
  ),

  // ── 11. Muhammad Ayyoub ─────────────────────────
  Reciter(
    id: 'muhammadayyoub',
    name: 'Muhammad Ayyoub',
    localizedName: 'محمد ایوب',
    country: 'Saudi Arabia',
    description: 'Imam of Masjid an-Nabawi, Madinah',
    avatarUrl: 'assets/images/reciters/muhammadayyoub.png',
    priority: 11,
    audioSource: AudioSource.alquranCdn,
    audioPath: 'ar.muhammadayyoub',
  ),

  // ── 12. Ahmed Al-Ajamy ──────────────────────────
  Reciter(
    id: 'ahmedajamy',
    name: 'Ahmed Al-Ajamy',
    localizedName: 'أحمد العجمی',
    country: 'Saudi Arabia',
    description: 'Heart-touching emotional recitation',
    avatarUrl: 'assets/images/reciters/ahmedajamy.png',
    priority: 12,
    audioSource: AudioSource.alquranCdn,
    audioPath: 'ar.ahmedajamy',
  ),

  // ── 13. Abu Bakr Ash-Shatri ─────────────────────
  Reciter(
    id: 'shaatree',
    name: 'Abu Bakr Ash-Shatri',
    localizedName: 'ابو بکر الشاطری',
    country: 'Saudi Arabia',
    description: 'Beautiful and clear recitation',
    avatarUrl: 'assets/images/reciters/shaatree.png',
    priority: 13,
    audioSource: AudioSource.alquranCdn,
    audioPath: 'ar.shaatree',
  ),

  // ── 14. Muhammad Jibreel ────────────────────────
  Reciter(
    id: 'muhammadjibreel',
    name: 'Muhammad Jibreel',
    localizedName: 'محمد جبریل',
    country: 'Egypt',
    description: 'Former Imam of Masjid Amr ibn al-As',
    avatarUrl: 'assets/images/reciters/muhammadjibreel.png',
    priority: 14,
    audioSource: AudioSource.alquranCdn,
    audioPath: 'ar.muhammadjibreel',
  ),

  // ── 15. Mohamed Siddiq Al-Minshawi (Mujawwad) ──
  Reciter(
    id: 'minshawi_mujawwad',
    name: 'Mohamed Siddiq Al-Minshawi (Mujawwad)',
    localizedName: 'محمد صدیق المنشاوی - مجوّد',
    country: 'Egypt',
    description: 'Beautiful Mujawwad style',
    avatarUrl: 'assets/images/reciters/minshawi.png',
    priority: 15,
    audioSource: AudioSource.quranCom,
    audioPath: 'Minshawi/Mujawwad/mp3',
  ),

  // ── 16. Mohamed Siddiq Al-Minshawi (Murattal) ──
  Reciter(
    id: 'minshawi_murattal',
    name: 'Mohamed Siddiq Al-Minshawi (Murattal)',
    localizedName: 'محمد صدیق المنشاوی - مرتل',
    country: 'Egypt',
    description: 'Clear Murattal recitation',
    avatarUrl: 'assets/images/reciters/minshawi.png',
    priority: 16,
    audioSource: AudioSource.quranCom,
    audioPath: 'Minshawi/Murattal/mp3',
  ),
];

/// Tafseer scholars list
const List<Reciter> tafseerScholars = [
  Reciter(
    id: 'maududi',
    name: 'Syed Abul Ala Maududi',
    localizedName: 'سید ابوالاعلیٰ مودودی',
    country: 'Pakistan',
    description: 'Tafheem-ul-Quran (Tafseer)',
    avatarUrl: 'assets/images/scholars/maududi.png',
    priority: 1,
  ),
  Reciter(
    id: 'israr',
    name: 'Dr. Israr Ahmad',
    localizedName: 'ڈاکٹر اسرار احمد',
    country: 'Pakistan',
    description: 'Quran Tafseer (Tafseer)',
    avatarUrl: 'assets/images/scholars/israr.png',
    priority: 2,
  ),
];

