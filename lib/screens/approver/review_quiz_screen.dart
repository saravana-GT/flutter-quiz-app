import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_platform/models/quiz.dart';
import 'package:quiz_platform/providers/quiz_provider.dart';
import 'package:go_router/go_router.dart';

class ReviewQuizScreen extends ConsumerStatefulWidget {
  final String quizId;
  const ReviewQuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<ReviewQuizScreen> createState() => _ReviewQuizScreenState();
}

class _ReviewQuizScreenState extends ConsumerState<ReviewQuizScreen> {
  final _reasonController = TextEditingController();

  void _approve(WidgetRef ref) async {
    await ref.read(quizActionsProvider).updateQuizStatus(widget.quizId, QuizStatus.approved);
    if (mounted) context.pop();
  }

  void _reject(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Quiz'),
        content: TextField(
          controller: _reasonController,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              await ref.read(quizActionsProvider).updateQuizStatus(
                widget.quizId,
                QuizStatus.rejected,
                rejectionReason: _reasonController.text,
              );
              if (mounted) {
                Navigator.pop(context); // close dialog
                context.pop(); // close screen
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider(widget.quizId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Quiz'),
      ),
      body: quizAsync.when(
        data: (quiz) {
          if (quiz == null) return const Center(child: Text('Quiz not found'));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quiz.title, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text('Subject: ${quiz.subject}', style: const TextStyle(fontSize: 16)),
                    Text('Description: ${quiz.description}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: quiz.questions.length,
                  itemBuilder: (context, index) {
                    final question = quiz.questions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${question.text}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(question.options.length, (optIndex) {
                              final isCorrect = optIndex == question.correctOptionIndex;
                              return ListTile(
                                dense: true,
                                title: Text(question.options[optIndex]),
                                leading: Icon(
                                  isCorrect ? Icons.check_circle : Icons.circle_outlined,
                                  color: isCorrect ? Colors.green : Colors.grey,
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            Text('Marks: ${question.marks}', style: const TextStyle(color: Colors.grey)),
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _reject(ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approve(ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
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
