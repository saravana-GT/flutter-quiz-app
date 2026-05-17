import 'package:quiz_platform/models/question.dart';

enum QuizStatus { draft, pending, approved, rejected }

class Quiz {
  final String id;
  final String teacherId;
  final String title;
  final String subject;
  final String description;
  final String difficulty;
  final int? timeLimitMinutes;
  final List<Question> questions;
  final QuizStatus status;
  final String? rejectionReason;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.subject,
    required this.description,
    required this.difficulty,
    this.timeLimitMinutes,
    required this.questions,
    this.status = QuizStatus.draft,
    this.rejectionReason,
    required this.createdAt,
  });

  Quiz copyWith({
    String? id,
    String? teacherId,
    String? title,
    String? subject,
    String? description,
    String? difficulty,
    int? timeLimitMinutes,
    List<Question>? questions,
    QuizStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      questions: questions ?? this.questions,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      teacherId: json['teacherId'],
      title: json['title'],
      subject: json['subject'],
      description: json['description'],
      difficulty: json['difficulty'],
      timeLimitMinutes: json['timeLimitMinutes'],
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
      status: QuizStatus.values.firstWhere(
        (e) => e.toString() == 'QuizStatus.${json['status']}',
        orElse: () => QuizStatus.draft,
      ),
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'title': title,
      'subject': subject,
      'description': description,
      'difficulty': difficulty,
      'timeLimitMinutes': timeLimitMinutes,
      'questions': questions.map((q) => q.toJson()).toList(),
      'status': status.toString().split('.').last,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
