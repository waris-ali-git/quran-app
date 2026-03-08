import 'package:equatable/equatable.dart';

/// User ke reading mode options
enum ReadingDisplayMode {
  arabicOnly,              // Sirf Arabic text
  arabicWithTranslation,   // Arabic + Translation (image jaisa)
  wordByWord,              // Har word ke neeche translation (exactly image jaisa)
  tajweed,                 // Colored tajweed mode
}

/// Available translations — AlQuran.cloud editions
class TranslationOption {
  final String edition;
  final String languageName;
  final String translatorName;
  final String displayName;

  const TranslationOption({
    required this.edition,
    required this.languageName,
    required this.translatorName,
    required this.displayName,
  });
}

@Deprecated('Dynamic translations from AlQuran.cloud are used instead')
const List<TranslationOption> kAvailableTranslations = [
  // Urdu
  TranslationOption(
    edition: 'ur.jalandhry',
    languageName: 'اردو',
    translatorName: 'فتح محمد جالندھری',
    displayName: 'اردو — جالندھری',
  ),
  TranslationOption(
    edition: 'ur.jawadi',
    languageName: 'اردو',
    translatorName: 'سید ذیشان حیدر جوادی',
    displayName: 'اردو — جوادی',
  ),
  TranslationOption(
    edition: 'ur.qadri',
    languageName: 'اردو',
    translatorName: 'طاہرالقادری',
    displayName: 'اردو — طاہرالقادری',
  ),
  TranslationOption(
    edition: 'ur.kanzuliman',
    languageName: 'اردو',
    translatorName: 'احمد رضا خان',
    displayName: 'اردو — کنزالایمان',
  ),
  // English
  TranslationOption(
    edition: 'en.sahih',
    languageName: 'English',
    translatorName: 'Sahih International',
    displayName: 'English — Sahih International',
  ),
  TranslationOption(
    edition: 'en.pickthall',
    languageName: 'English',
    translatorName: 'Pickthall',
    displayName: 'English — Pickthall',
  ),
  TranslationOption(
    edition: 'en.asad',
    languageName: 'English',
    translatorName: 'Muhammad Asad',
    displayName: 'English — Muhammad Asad',
  ),
];

class ReadingPreferences extends Equatable {
  final ReadingDisplayMode displayMode;
  final bool showTajweed;
  final double arabicFontSize;
  final double translationFontSize;
  final String selectedTranslation;
  final bool showTransliteration;
  final int selectedReciterId;

  const ReadingPreferences({
    this.displayMode = ReadingDisplayMode.arabicWithTranslation,
    this.showTajweed = false,
    this.arabicFontSize = 28.0,
    this.translationFontSize = 16.0,
    this.selectedTranslation = 'ur.jalandhry',
    this.showTransliteration = false,
    this.selectedReciterId = 7, // Mishari Rashid Al-Afasy
  });

  ReadingPreferences copyWith({
    ReadingDisplayMode? displayMode,
    bool? showTajweed,
    double? arabicFontSize,
    double? translationFontSize,
    String? selectedTranslation,
    bool? showTransliteration,
    int? selectedReciterId,
  }) {
    return ReadingPreferences(
      displayMode: displayMode ?? this.displayMode,
      showTajweed: showTajweed ?? this.showTajweed,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      selectedTranslation: selectedTranslation ?? this.selectedTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      selectedReciterId: selectedReciterId ?? this.selectedReciterId,
    );
  }

  @override
  List<Object?> get props => [
    displayMode,
    showTajweed,
    arabicFontSize,
    translationFontSize,
    selectedTranslation,
    showTransliteration,
    selectedReciterId,
  ];
}