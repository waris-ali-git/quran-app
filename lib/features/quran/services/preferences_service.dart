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

  static final PreferencesService _instance = PreferencesService._internal();
  late SharedPreferences _prefs;

  factory PreferencesService() => _instance;
  PreferencesService._internal();

  /// Initialize the preferences service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
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
}

