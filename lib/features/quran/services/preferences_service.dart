import 'package:shared_preferences/shared_preferences.dart';
import '../models/reciter.dart';

/// Service to manage app-wide user preferences for Quran reading via SharedPreferences.
///
/// NOTE on Architecture:
/// - App Preferences (Reciter, Tafseer Scholar, etc.) are managed here via `SharedPreferences`.
/// - Reading Session Preferences (Display Mode, Font Size, Translations) are managed via `QuranService` using `Hive`.
/// This separation ensures heavy/complex session objects are cached locally via Hive, 
/// while simple, persistent app-wide settings stay in SharedPreferences.
class PreferencesService {
  static const String _selectedReciterId = 'selected_reciter_id';
  static const String _selectedTafseerScholarId = 'selected_tafseer_scholar_id';
  static const String _completedOnboarding = 'completed_onboarding';
  // Qibla Cache
  static const String _cachedQiblaDirection = 'cached_qibla_direction';
  static const String _cachedQiblaLat = 'cached_qibla_lat';
  static const String _cachedQiblaLng = 'cached_qibla_lng';
  // Verse-by-Verse settings
  static const String _vbvTranslationEditionId = 'vbv_translation_edition_id';
  static const String _vbvPlayTranslation = 'vbv_play_translation';
  static const String _vbvPlayTafseer = 'vbv_play_tafseer';

  static final PreferencesService _instance = PreferencesService._internal();
  late SharedPreferences _prefs;

  factory PreferencesService() => _instance;
  PreferencesService._internal();

  /// Initialize the preferences service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Expose the SharedPreferences instance
  SharedPreferences? get prefs => _prefs;

  /// Check if user has completed the onboarding flow
  bool getCompletedOnboarding() {
    return _prefs.getBool(_completedOnboarding) ?? false;
  }

  /// Mark onboarding flow as completed
  Future<void> setCompletedOnboarding(bool value) async {
    await _prefs.setBool(_completedOnboarding, value);
  }

  /// Get the saved reciter ID, defaults to 'alafasy'
  String getSelectedReciterId() {
    return _prefs.getString(_selectedReciterId) ?? 'alafasy';
  }

  /// Get the selected reciter object
  Reciter getSelectedReciter() {
    final id = getSelectedReciterId();
    return defaultReciters.firstWhere(
      (r) => r.id == id,
      orElse: () => defaultReciters.first,
    );
  }

  /// Save the selected reciter ID
  Future<void> setSelectedReciterId(String reciterId) async {
    await _prefs.setString(_selectedReciterId, reciterId);
  }

  /// Save the selected reciter
  Future<void> setSelectedReciter(Reciter reciter) async {
    await setSelectedReciterId(reciter.id);
  }

  /// Get the saved tafseer scholar ID
  String? getSelectedTafseerScholarId() {
    return _prefs.getString(_selectedTafseerScholarId);
  }

  /// Get the selected tafseer scholar object
  Reciter? getSelectedTafseerScholar() {
    final id = getSelectedTafseerScholarId();
    if (id == null) return null;
    return tafseerScholars.firstWhere(
      (s) => s.id == id,
      orElse: () => tafseerScholars.first,
    );
  }

  /// Save the selected tafseer scholar ID
  Future<void> setSelectedTafseerScholarId(String scholarId) async {
    await _prefs.setString(_selectedTafseerScholarId, scholarId);
  }

  /// Save the selected tafseer scholar
  Future<void> setSelectedTafseerScholar(Reciter scholar) async {
    await setSelectedTafseerScholarId(scholar.id);
  }

  // ─── Qibla Cache ───────────────────────────

  double? getCachedQiblaDirection() {
    return _prefs.getDouble(_cachedQiblaDirection);
  }

  double? getCachedQiblaLatitude() {
    return _prefs.getDouble(_cachedQiblaLat);
  }

  double? getCachedQiblaLongitude() {
    return _prefs.getDouble(_cachedQiblaLng);
  }

  Future<void> saveQiblaCache(double direction, double lat, double lng) async {
    await _prefs.setDouble(_cachedQiblaDirection, direction);
    await _prefs.setDouble(_cachedQiblaLat, lat);
    await _prefs.setDouble(_cachedQiblaLng, lng);
  }

  // ─── Verse-by-Verse Settings ─────────────────

  /// Get saved translation edition ID (defaults to Urdu Jalandhari)
  String getVbvTranslationEditionId() {
    return _prefs.getString(_vbvTranslationEditionId) ?? 'ur-jalandhri';
  }

  Future<void> setVbvTranslationEditionId(String editionId) async {
    await _prefs.setString(_vbvTranslationEditionId, editionId);
  }

  bool getVbvPlayTranslation() {
    return _prefs.getBool(_vbvPlayTranslation) ?? true;
  }

  Future<void> setVbvPlayTranslation(bool value) async {
    await _prefs.setBool(_vbvPlayTranslation, value);
  }

  bool getVbvPlayTafseer() {
    return _prefs.getBool(_vbvPlayTafseer) ?? false;
  }

  Future<void> setVbvPlayTafseer(bool value) async {
    await _prefs.setBool(_vbvPlayTafseer, value);
  }

  // ─── Grammar Progress Settings ─────────────
  static const String _masteredGrammarLessons = 'mastered_grammar_lessons';

  Set<int> getMasteredGrammarLessons() {
    final list = _prefs.getStringList(_masteredGrammarLessons) ?? [];
    return list
        .map((e) => int.tryParse(e) ?? -1)
        .where((id) => id != -1)
        .toSet();
  }

  Future<void> saveMasteredGrammarLessons(Set<int> masteredIds) async {
    await _prefs.setStringList(
      _masteredGrammarLessons,
      masteredIds.map((id) => id.toString()).toList(),
    );
  }

  Future<void> clearMasteredGrammarLessons() async {
    await _prefs.remove(_masteredGrammarLessons);
  }
}
