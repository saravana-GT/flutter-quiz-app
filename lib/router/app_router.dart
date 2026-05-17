import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_platform/providers/auth_provider.dart';
import 'package:quiz_platform/models/user.dart';

// Import Screens (we'll create these next)
import 'package:quiz_platform/screens/auth/login_screen.dart';
import 'package:quiz_platform/screens/student/student_dashboard.dart';
import 'package:quiz_platform/screens/student/quiz_attempt_screen.dart';
import 'package:quiz_platform/screens/student/quiz_result_screen.dart';
import 'package:quiz_platform/models/quiz_attempt.dart';
import 'package:quiz_platform/screens/teacher/teacher_dashboard.dart';
import 'package:quiz_platform/screens/teacher/create_quiz_screen.dart';
import 'package:quiz_platform/screens/approver/approver_dashboard.dart';
import 'package:quiz_platform/screens/approver/review_quiz_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.value;

      if (isLoading) return null;

      final isGoingToLogin = state.uri.path == '/login';

      if (user == null && !isGoingToLogin) {
        return '/login';
      }

      if (user != null && isGoingToLogin) {
        switch (user.role) {
          case UserRole.student:
            return '/student';
          case UserRole.teacher:
            return '/teacher';
          case UserRole.approver:
            return '/approver';
        }
      }

      // Role-based route protection
      if (user != null) {
        final path = state.uri.path;
        if (path.startsWith('/student') && user.role != UserRole.student) {
          return _getHomeRoute(user.role);
        }
        if (path.startsWith('/teacher') && user.role != UserRole.teacher) {
          return _getHomeRoute(user.role);
        }
        if (path.startsWith('/approver') && user.role != UserRole.approver) {
          return _getHomeRoute(user.role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
        routes: [
          GoRoute(
            path: 'attempt/:id',
            builder: (context, state) => QuizAttemptScreen(
              quizId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'result/:attemptId',
            builder: (context, state) {
              final attempt = state.extra as QuizAttempt;
              return QuizResultScreen(attempt: attempt);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboard(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateQuizScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/approver',
        builder: (context, state) => const ApproverDashboard(),
        routes: [
          GoRoute(
            path: 'review/:id',
            builder: (context, state) => ReviewQuizScreen(
              quizId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
});

String _getHomeRoute(UserRole role) {
  switch (role) {
    case UserRole.student:
      return '/student';
    case UserRole.teacher:
      return '/teacher';
    case UserRole.approver:
      return '/approver';
  }
}
