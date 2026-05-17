import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_platform/models/quiz.dart';
import 'package:quiz_platform/models/quiz_attempt.dart';
import 'package:quiz_platform/repositories/quiz_repository.dart';

final quizRepositoryProvider = Provider((ref) => QuizRepository());

// Quizzes by status
final pendingQuizzesProvider = FutureProvider<List<Quiz>>((ref) async {
  return ref.read(quizRepositoryProvider).getPendingQuizzes();
});

final approvedQuizzesProvider = FutureProvider<List<Quiz>>((ref) async {
  return ref.read(quizRepositoryProvider).getApprovedQuizzes();
});

// Teacher's quizzes
final teacherQuizzesProvider = FutureProvider.family<List<Quiz>, String>((ref, teacherId) async {
  return ref.read(quizRepositoryProvider).getQuizzesByTeacher(teacherId);
});

// Student's attempts
final studentAttemptsProvider = FutureProvider.family<List<QuizAttempt>, String>((ref, studentId) async {
  return ref.read(quizRepositoryProvider).getAttempts(studentId);
});

// Provider for fetching a single quiz
final quizProvider = FutureProvider.family<Quiz?, String>((ref, quizId) async {
  final quizzes = await ref.read(quizRepositoryProvider).getQuizzes();
  try {
    return quizzes.firstWhere((q) => q.id == quizId);
  } catch (e) {
    return null;
  }
});

// Notifier for quiz actions (create, approve, reject, submit attempt)
final quizActionsProvider = Provider((ref) => QuizActions(ref));

class QuizActions {
  final Ref _ref;
  QuizActions(this._ref);

  Future<void> createQuiz(Quiz quiz) async {
    await _ref.read(quizRepositoryProvider).addQuiz(quiz);
    // Invalidate caches
    _ref.invalidate(teacherQuizzesProvider);
    _ref.invalidate(pendingQuizzesProvider);
  }

  Future<void> updateQuizStatus(String quizId, QuizStatus status, {String? rejectionReason}) async {
    final repository = _ref.read(quizRepositoryProvider);
    final quizzes = await repository.getQuizzes();
    final index = quizzes.indexWhere((q) => q.id == quizId);
    
    if (index != -1) {
      final updatedQuiz = quizzes[index].copyWith(
        status: status,
        rejectionReason: rejectionReason,
      );
      await repository.updateQuiz(updatedQuiz);
      
      _ref.invalidate(pendingQuizzesProvider);
      _ref.invalidate(approvedQuizzesProvider);
      _ref.invalidate(teacherQuizzesProvider);
      _ref.invalidate(quizProvider);
    }
  }

  Future<void> submitAttempt(QuizAttempt attempt) async {
    await _ref.read(quizRepositoryProvider).saveAttempt(attempt);
    _ref.invalidate(studentAttemptsProvider);
  }
}
