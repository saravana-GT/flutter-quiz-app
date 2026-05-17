import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_platform/models/quiz.dart';
import 'package:quiz_platform/models/question.dart';
import 'package:quiz_platform/providers/auth_provider.dart';
import 'package:quiz_platform/providers/quiz_provider.dart';
import 'package:go_router/go_router.dart';

class CreateQuizScreen extends ConsumerStatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  ConsumerState<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends ConsumerState<CreateQuizScreen> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  
  final List<Question> _questions = [];

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => const AddQuestionDialog(),
    ).then((question) {
      if (question != null && question is Question) {
        setState(() {
          _questions.add(question);
        });
      }
    });
  }

  void _submitQuiz(QuizStatus status) async {
    if (_titleController.text.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add title and at least 1 question')),
      );
      return;
    }

    final user = ref.read(authStateProvider).value!;
    final quiz = Quiz(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teacherId: user.id,
      title: _titleController.text,
      subject: _subjectController.text,
      description: _descController.text,
      difficulty: 'Intermediate',
      questions: _questions,
      status: status,
      createdAt: DateTime.now(),
    );

    await ref.read(quizActionsProvider).createQuiz(quiz);
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz'),
        actions: [
          TextButton(
            onPressed: () => _submitQuiz(QuizStatus.draft),
            child: const Text('Save Draft', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => _submitQuiz(QuizStatus.pending),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue),
            child: const Text('Submit for Approval'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar (Details)
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.grey.shade100,
              child: ListView(
                children: [
                  const Text('Quiz Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Quiz Title'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          // Right Content (Questions)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Questions (${_questions.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Question'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _questions.isEmpty
                        ? const Center(child: Text('No questions added yet.'))
                        : ListView.builder(
                            itemCount: _questions.length,
                            itemBuilder: (context, index) {
                              final q = _questions[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ListTile(
                                  title: Text(q.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Marks: ${q.marks} | Options: ${q.options.length}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _questions.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddQuestionDialog extends StatefulWidget {
  const AddQuestionDialog({super.key});

  @override
  State<AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<AddQuestionDialog> {
  final _textController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctIndex = 0;
  final _marksController = TextEditingController(text: '10');

  void _save() {
    if (_textController.text.isEmpty || _optionControllers.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    
    final q = Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _textController.text,
      options: _optionControllers.map((c) => c.text).toList(),
      correctOptionIndex: _correctIndex,
      marks: int.tryParse(_marksController.text) ?? 10,
    );
    Navigator.pop(context, q);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Question'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(labelText: 'Question Text'),
              ),
              const SizedBox(height: 16),
              ...List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _correctIndex,
                        onChanged: (val) {
                          setState(() => _correctIndex = val!);
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              TextField(
                controller: _marksController,
                decoration: const InputDecoration(labelText: 'Marks'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Add Question'),
        ),
      ],
    );
  }
}
