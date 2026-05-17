import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_platform/providers/auth_provider.dart';
import 'package:quiz_platform/providers/quiz_provider.dart';
import 'package:quiz_platform/models/quiz.dart';
import 'package:quiz_platform/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  int _currentTab = 0; // 0: Dashboard, 1: My Quizzes, 2: Performance Stats

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox();

    final quizzesAsync = ref.watch(teacherQuizzesProvider(user.id));

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context, ref, user.name),
          
          // Main Body switcher
          Expanded(
            child: _buildMainContent(quizzesAsync, user),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(AsyncValue<List<Quiz>> quizzesAsync, dynamic user) {
    switch (_currentTab) {
      case 0:
        return _buildDashboardTab(quizzesAsync, user);
      case 1:
        return _buildMyQuizzesTab(quizzesAsync);
      case 2:
        return _buildStatsTab(quizzesAsync);
      default:
        return const SizedBox();
    }
  }

  // Tab 0: Dashboard
  Widget _buildDashboardTab(AsyncValue<List<Quiz>> quizzesAsync, dynamic user) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teacher Dashboard', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 4),
                    const Text('Manage, monitor and create interactive assessments.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/teacher/create'),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Create New Quiz'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 32, 40, 16),
            child: quizzesAsync.when(
              data: (quizzes) {
                final total = quizzes.length;
                final approved = quizzes.where((q) => q.status == QuizStatus.approved).length;
                final pending = quizzes.where((q) => q.status == QuizStatus.pending).length;
                final rejected = quizzes.where((q) => q.status == QuizStatus.rejected).length;
                return Row(
                  children: [
                    _buildStatCard('Total Quizzes', total.toString(), Icons.folder_open_outlined, AppTheme.primary),
                    const SizedBox(width: 24),
                    _buildStatCard('Approved', approved.toString(), Icons.check_circle_outline, AppTheme.accent),
                    const SizedBox(width: 24),
                    _buildStatCard('Pending Approval', pending.toString(), Icons.hourglass_empty, AppTheme.warning),
                    const SizedBox(width: 24),
                    _buildStatCard('Rejected', rejected.toString(), Icons.cancel_outlined, AppTheme.error),
                  ],
                );
              },
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Text('All Created Quizzes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          sliver: quizzesAsync.when(
            data: (quizzes) {
              if (quizzes.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80.0),
                      child: Text('No quizzes created yet. Use the button above to create one!', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildQuizListItem(context, quizzes[index]),
                  childCount: quizzes.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (err, st) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
          ),
        ),
      ],
    );
  }

  // Tab 1: My Quizzes Management View
  Widget _buildMyQuizzesTab(AsyncValue<List<Quiz>> quizzesAsync) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quiz Inventory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              ElevatedButton.icon(
                onPressed: () => context.push('/teacher/create'),
                icon: const Icon(Icons.add),
                label: const Text('Add Quiz'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Focus view on all created assessment packages.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 32),
          Expanded(
            child: quizzesAsync.when(
              data: (quizzes) {
                if (quizzes.isEmpty) {
                  return const Center(child: Text('Inventory is empty.', style: TextStyle(color: AppTheme.textMuted)));
                }
                return ListView.builder(
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        subtitle: Text('${quiz.subject} • ${quiz.questions.length} Questions', style: const TextStyle(color: AppTheme.textMuted)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              quiz.status.name.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: quiz.status == QuizStatus.approved ? AppTheme.accent : AppTheme.warning,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                              onPressed: () async {
                                await ref.read(quizRepositoryProvider).deleteQuiz(quiz.id);
                                ref.invalidate(teacherQuizzesProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Quiz deleted successfully!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 2: Performance Stats View
  Widget _buildStatsTab(AsyncValue<List<Quiz>> quizzesAsync) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performance Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text('Visual metrics of student participations and average grading logs.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 32),
            Row(
              children: [
                _buildAnalyticsSummaryCard('Highest Avg Score', '87%', Icons.trending_up, AppTheme.accent),
                const SizedBox(width: 24),
                _buildAnalyticsSummaryCard('Total Exam Takers', '14 Students', Icons.people_outline, AppTheme.primary),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Participation Activity Graph (Mock)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
                  const SizedBox(height: 24),
                  // Render custom mock graph bars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _mockGraphBar('Mon', 40),
                      _mockGraphBar('Tue', 70),
                      _mockGraphBar('Wed', 55),
                      _mockGraphBar('Thu', 90),
                      _mockGraphBar('Fri', 60),
                      _mockGraphBar('Sat', 20),
                      _mockGraphBar('Sun', 35),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mockGraphBar(String day, double heightPercentage) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 150 * (heightPercentage / 100),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 12),
        Text(day, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAnalyticsSummaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref, String name) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(color: Color(0xFF0F172A)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.school, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Text('EduPortal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 16),
          _sidebarItem(Icons.dashboard_rounded, 'Dashboard', 0),
          _sidebarItem(Icons.folder_open_rounded, 'My Quizzes', 1),
          _sidebarItem(Icons.analytics_outlined, 'Performance Stats', 2),
          const Spacer(),
          const Divider(color: Color(0xFF1E293B)),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: InkWell(
              onTap: () => ref.read(authStateProvider.notifier).logout(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, int tabIndex) {
    final active = _currentTab == tabIndex;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => setState(() => _currentTab = tabIndex),
        leading: Icon(icon, color: active ? AppTheme.primary : const Color(0xFF94A3B8)),
        title: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizListItem(BuildContext context, Quiz quiz) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    switch (quiz.status) {
      case QuizStatus.approved:
        statusColor = AppTheme.accent;
        statusIcon = Icons.check_circle_outline;
        break;
      case QuizStatus.pending:
        statusColor = AppTheme.warning;
        statusIcon = Icons.hourglass_empty;
        break;
      case QuizStatus.rejected:
        statusColor = AppTheme.error;
        statusIcon = Icons.cancel_outlined;
        break;
      case QuizStatus.draft:
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.edit_note;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text('${quiz.subject} • ${quiz.questions.length} Questions', style: const TextStyle(color: AppTheme.textMuted)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    quiz.status.name.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (quiz.status == QuizStatus.rejected) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.info_outline, color: AppTheme.error),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                          SizedBox(width: 12),
                          Text('Rejection Details'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your quiz was rejected for the following reason:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.error.withOpacity(0.15)),
                            ),
                            child: Text(
                              quiz.rejectionReason ?? 'No comment provided.',
                              style: const TextStyle(color: AppTheme.textDark, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}
