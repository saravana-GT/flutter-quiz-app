import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_platform/models/quiz.dart';
import 'package:quiz_platform/models/quiz_attempt.dart';
import 'package:quiz_platform/repositories/mock_data.dart';

class QuizRepository {
  static const String _quizzesKey = 'quizzes_data';
  static const String _attemptsKey = 'attempts_data';

  Future<List<Quiz>> getQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final quizzesJson = prefs.getString(_quizzesKey);

    if (quizzesJson != null) {
      final List<dynamic> decoded = jsonDecode(quizzesJson);
      return decoded.map((e) => Quiz.fromJson(e)).toList();
    } else {
      // Seed initial data
      await _saveQuizzes(MockData.quizzes);
      return MockData.quizzes;
    }
  }

  Future<void> _saveQuizzes(List<Quiz> quizzes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(quizzes.map((e) => e.toJson()).toList());
    await prefs.setString(_quizzesKey, encoded);
  }

  Future<void> addQuiz(Quiz quiz) async {
    final quizzes = await getQuizzes();
    quizzes.add(quiz);
    await _saveQuizzes(quizzes);
  }

  Future<void> updateQuiz(Quiz quiz) async {
    final quizzes = await getQuizzes();
    final index = quizzes.indexWhere((q) => q.id == quiz.id);
    if (index != -1) {
      quizzes[index] = quiz;
      await _saveQuizzes(quizzes);
    }
  }

  Future<void> deleteQuiz(String id) async {
    final quizzes = await getQuizzes();
    quizzes.removeWhere((q) => q.id == id);
    await _saveQuizzes(quizzes);
  }

  Future<List<Quiz>> getQuizzesByTeacher(String teacherId) async {
    final quizzes = await getQuizzes();
    return quizzes.where((q) => q.teacherId == teacherId).toList();
  }

  Future<List<Quiz>> getApprovedQuizzes() async {
    final quizzes = await getQuizzes();
    return quizzes.where((q) => q.status == QuizStatus.approved).toList();
  }

  Future<List<Quiz>> getPendingQuizzes() async {
    final quizzes = await getQuizzes();
    return quizzes.where((q) => q.status == QuizStatus.pending).toList();
  }

  // Attempts
  Future<List<QuizAttempt>> getAttempts(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsJson = prefs.getString(_attemptsKey);

    if (attemptsJson != null) {
      final List<dynamic> decoded = jsonDecode(attemptsJson);
      return decoded
          .map((e) => QuizAttempt.fromJson(e))
          .where((a) => a.studentId == studentId)
          .toList();
    }
    return [];
  }

  Future<void> saveAttempt(QuizAttempt attempt) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsJson = prefs.getString(_attemptsKey);
    List<QuizAttempt> attempts = [];

    if (attemptsJson != null) {
      final List<dynamic> decoded = jsonDecode(attemptsJson);
      attempts = decoded.map((e) => QuizAttempt.fromJson(e)).toList();
    }

    attempts.add(attempt);
    await prefs.setString(
        _attemptsKey, jsonEncode(attempts.map((e) => e.toJson()).toList()));
  }
}
