class QuizAttempt {
  final String id;
  final String quizId;
  final String studentId;
  final int score;
  final int totalMarks;
  final Map<String, int> selectedOptions; // questionId -> selectedOptionIndex
  final DateTime attemptedAt;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.score,
    required this.totalMarks,
    required this.selectedOptions,
    required this.attemptedAt,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      quizId: json['quizId'],
      studentId: json['studentId'],
      score: json['score'],
      totalMarks: json['totalMarks'],
      selectedOptions: Map<String, int>.from(json['selectedOptions']),
      attemptedAt: DateTime.parse(json['attemptedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'studentId': studentId,
      'score': score,
      'totalMarks': totalMarks,
      'selectedOptions': selectedOptions,
      'attemptedAt': attemptedAt.toIso8601String(),
    };
  }
}
