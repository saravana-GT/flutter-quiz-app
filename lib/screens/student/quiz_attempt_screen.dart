import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_platform/providers/auth_provider.dart';
import 'package:quiz_platform/providers/quiz_provider.dart';
import 'package:quiz_platform/models/quiz_attempt.dart';
import 'package:go_router/go_router.dart';

class QuizAttemptScreen extends ConsumerStatefulWidget {
  final String quizId;
  const QuizAttemptScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends ConsumerState<QuizAttemptScreen> {
  final Map<String, int> _selectedOptions = {};
  bool _isSubmitting = false;

  void _submit(WidgetRef ref, int totalMarks, int score) async {
    setState(() => _isSubmitting = true);
    final user = ref.read(authStateProvider).value!;
    
    final attempt = QuizAttempt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      quizId: widget.quizId,
      studentId: user.id,
      score: score,
      totalMarks: totalMarks,
      selectedOptions: _selectedOptions,
      attemptedAt: DateTime.now(),
    );

    await ref.read(quizActionsProvider).submitAttempt(attempt);
    
    if (mounted) {
      context.go('/student/result/${attempt.id}', extra: attempt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider(widget.quizId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Attempt'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: quizAsync.when(
        data: (quiz) {
          if (quiz == null) return const Center(child: Text('Quiz not found'));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  quiz.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: quiz.questions.length,
                  itemBuilder: (context, index) {
                    final question = quiz.questions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${question.text}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(question.options.length, (optIndex) {
                              return RadioListTile<int>(
                                title: Text(question.options[optIndex]),
                                value: optIndex,
                                groupValue: _selectedOptions[question.id],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedOptions[question.id] = val!;
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () {
                      int score = 0;
                      int totalMarks = 0;
                      for (var q in quiz.questions) {
                        totalMarks += q.marks;
                        if (_selectedOptions[q.id] == q.correctOptionIndex) {
                          score += q.marks;
                        }
                      }
                      _submit(ref, totalMarks, score);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isSubmitting 
                      ? const CircularProgressIndicator()
                      : const Text('Submit Quiz'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
