import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_platform/models/quiz_attempt.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizAttempt attempt;
  
  const QuizResultScreen({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final percentage = (attempt.score / attempt.totalMarks) * 100;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        automaticallyImplyLeading: false, // Prevent going back to attempt
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const SizedBox(height: 24),
              Text(
                'Quiz Completed!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Your Score',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                '${attempt.score} / ${attempt.totalMarks}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: percentage >= 50 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  context.go('/student');
                },
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
