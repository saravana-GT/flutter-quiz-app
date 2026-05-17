import 'package:quiz_platform/models/user.dart';
import 'package:quiz_platform/models/quiz.dart';
import 'package:quiz_platform/models/question.dart';

class MockData {
  static final List<User> users = [
    User(id: '1', email: 'student@test.com', name: 'Student 1', role: UserRole.student),
    User(id: '2', email: 'teacher@test.com', name: 'Teacher 1', role: UserRole.teacher),
    User(id: '3', email: 'approver@test.com', name: 'Approver 1', role: UserRole.approver),
  ];

  // Dummy passwords just for the mock auth check
  static const String dummyPassword = '123456';

  static final List<Quiz> quizzes = [
    Quiz(
      id: 'q1',
      teacherId: '2',
      title: 'Flutter Basics',
      subject: 'Mobile Development',
      description: 'A basic quiz to test your Flutter knowledge.',
      difficulty: 'Beginner',
      timeLimitMinutes: 10,
      status: QuizStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      questions: [
        Question(
          id: 'q1_1',
          text: 'What language is Flutter written in?',
          options: ['Java', 'Kotlin', 'Dart', 'Swift'],
          correctOptionIndex: 2,
          marks: 10,
        ),
        Question(
          id: 'q1_2',
          text: 'Who developed Flutter?',
          options: ['Apple', 'Microsoft', 'Google', 'Facebook'],
          correctOptionIndex: 2,
          marks: 10,
        ),
      ],
    ),
    Quiz(
      id: 'q2',
      teacherId: '2',
      title: 'Advanced Dart',
      subject: 'Programming',
      description: 'Test your advanced Dart skills.',
      difficulty: 'Advanced',
      status: QuizStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      questions: [
        Question(
          id: 'q2_1',
          text: 'What does "Isolate" mean in Dart?',
          options: ['A thread', 'An independent worker with its own memory', 'A UI component', 'A package manager'],
          correctOptionIndex: 1,
          marks: 20,
        ),
      ],
    ),
  ];
}
