class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  final int marks;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    required this.marks,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      options: List<String>.from(json['options']),
      correctOptionIndex: json['correctOptionIndex'],
      marks: json['marks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'marks': marks,
    };
  }
}
