class DailyHadith {
  final int id;
  final String arabic;
  final String urdu;
  final String english;
  final String book;
  final String hadithNumber;
  final String narrator;
  final String chapter;
  final String grade;

  const DailyHadith({
    required this.id,
    required this.arabic,
    required this.urdu,
    required this.english,
    required this.book,
    required this.hadithNumber,
    required this.narrator,
    required this.chapter,
    required this.grade,
  });

  factory DailyHadith.fromJson(Map<String, dynamic> json) {
    return DailyHadith(
      id: json['id'] as int? ?? 0,
      arabic: json['arabic'] as String? ?? '',
      urdu: json['urdu'] as String? ?? '',
      english: json['english'] as String? ?? '',
      book: json['book'] as String? ?? 'صحيح البخاري',
      hadithNumber: json['hadithNumber']?.toString() ?? '',
      narrator: json['narrator'] as String? ?? '',
      chapter: json['chapter'] as String? ?? '',
      grade: json['grade'] as String? ?? 'صحيح',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arabic': arabic,
      'urdu': urdu,
      'english': english,
      'book': book,
      'hadithNumber': hadithNumber,
      'narrator': narrator,
      'chapter': chapter,
      'grade': grade,
    };
  }

  static const DailyHadith fallback = DailyHadith(
    id: 1,
    arabic: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
    urdu: 'اعمال کا دارومدار نیتوں پر ہے، اور ہر شخص کے لیے وہی ہے جس کی اس نے نیت کیہ۔',
    english: 'Actions are judged by intentions, and every person will get what they intended.',
    book: 'صحيح البخاري',
    hadithNumber: '1',
    narrator: 'عمر بن الخطاب رضي الله عنه',
    chapter: 'كتاب بدء الوحي',
    grade: 'صحيح',
  );
}
