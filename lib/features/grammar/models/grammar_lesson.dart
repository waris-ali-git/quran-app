class GrammarExample {
  final String arabic;
  final String transliteration;
  final String meaning;

  GrammarExample({
    required this.arabic,
    required this.transliteration,
    required this.meaning,
  });

  factory GrammarExample.fromJson(Map<String, dynamic> json) {
    return GrammarExample(
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      meaning: json['meaning'] as String,
    );
  }
}

class GrammarQuiz {
  final String question;
  final List<String> options;
  final int answer;

  GrammarQuiz({
    required this.question,
    required this.options,
    required this.answer,
  });

  factory GrammarQuiz.fromJson(Map<String, dynamic> json) {
    return GrammarQuiz(
      question: json['question'] as String,
      options: List<String>.from(json['options']),
      answer: json['answer'] as int,
    );
  }
}

class GrammarLesson {
  final int id;
  final String category; // 'Nahw' or 'Sarf'
  final String title;
  final String arabicTitle;
  final String description;
  final List<GrammarExample> examples;
  final GrammarQuiz? quiz;

  GrammarLesson({
    required this.id,
    required this.category,
    required this.title,
    required this.arabicTitle,
    required this.description,
    required this.examples,
    this.quiz,
  });

  factory GrammarLesson.fromJson(Map<String, dynamic> json) {
    return GrammarLesson(
      id: json['id'] as int,
      category: json['category'] as String,
      title: json['title'] as String,
      arabicTitle: json['arabicTitle'] as String,
      description: json['description'] as String,
      examples: (json['examples'] as List)
          .map((e) => GrammarExample.fromJson(e as Map<String, dynamic>))
          .toList(),
      quiz: json['quiz'] != null
          ? GrammarQuiz.fromJson(json['quiz'] as Map<String, dynamic>)
          : null,
    );
  }
}
