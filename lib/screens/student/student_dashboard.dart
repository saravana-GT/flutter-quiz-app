import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_platform/providers/auth_provider.dart';
import 'package:quiz_platform/providers/quiz_provider.dart';
import 'package:quiz_platform/models/quiz_attempt.dart';
import 'package:quiz_platform/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _currentTab = 0; // 0: Dashboard, 1: My Attempts, 2: Profile Settings

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox();

    final quizzesAsync = ref.watch(approvedQuizzesProvider);
    final attemptsAsync = ref.watch(studentAttemptsProvider(user.id));

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context, ref, user.name),
          
          // Main content switcher
          Expanded(
            child: _buildMainContent(quizzesAsync, attemptsAsync, user),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(AsyncValue<dynamic> quizzesAsync, AsyncValue<List<QuizAttempt>> attemptsAsync, dynamic user) {
    switch (_currentTab) {
      case 0:
        return _buildDashboardTab(quizzesAsync, attemptsAsync, user);
      case 1:
        return _buildAttemptsTab(attemptsAsync);
      case 2:
        return _buildProfileTab(user);
      default:
        return const SizedBox();
    }
  }

  // Dashboard Tab
  Widget _buildDashboardTab(AsyncValue<dynamic> quizzesAsync, AsyncValue<List<QuizAttempt>> attemptsAsync, dynamic user) {
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
                    Text(
                      'Welcome back, ${user.name}! 👋',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 4),
                    const Text('Ready to test your knowledge today?', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.stars, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Student Tier', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 32, 40, 16),
            child: attemptsAsync.when(
              data: (attempts) {
                final total = attempts.length;
                final avg = total == 0 
                    ? 0 
                    : (attempts.fold(0, (sum, a) => sum + (a.score * 100 ~/ a.totalMarks)) / total).round();
                return Row(
                  children: [
                    _buildStatCard('Attempted Quizzes', total.toString(), Icons.check_circle_outline, AppTheme.primary),
                    const SizedBox(width: 24),
                    _buildStatCard('Average Score', '$avg%', Icons.analytics_outlined, AppTheme.accent),
                    const SizedBox(width: 24),
                    _buildStatCard('Performance', avg >= 75 ? 'Excellent' : 'Good', Icons.emoji_events_outlined, AppTheme.warning),
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
            child: Text('Available Quizzes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
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
                      child: Text('No quizzes available at the moment.', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  ),
                );
              }
              return SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 1.4,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildQuizCard(context, quizzes[index]),
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

  // Attempts Tab
  Widget _buildAttemptsTab(AsyncValue<List<QuizAttempt>> attemptsAsync) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Quiz Attempts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Text('Review your previously submitted quizzes and scores.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 32),
          Expanded(
            child: attemptsAsync.when(
              data: (attempts) {
                if (attempts.isEmpty) {
                  return const Center(child: Text('You have not attempted any quizzes yet.', style: TextStyle(color: AppTheme.textMuted)));
                }
                return ListView.builder(
                  itemCount: attempts.length,
                  itemBuilder: (context, index) {
                    final attempt = attempts[index];
                    final percentage = (attempt.score / attempt.totalMarks) * 100;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (percentage >= 50 ? Colors.green : Colors.red).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            percentage >= 50 ? Icons.check_circle : Icons.cancel,
                            color: percentage >= 50 ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text('Quiz ID: ${attempt.quizId}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text('Attempted on: ${attempt.attemptedAt.toLocal().toString().substring(0, 16)}', style: const TextStyle(color: AppTheme.textMuted)),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${attempt.score} / ${attempt.totalMarks}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: percentage >= 50 ? Colors.green : Colors.red,
                              ),
                            ),
                            Text('${percentage.round()}% Score', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading attempts: $err')),
            ),
          ),
        ],
      ),
    );
  }

  // Profile Tab
  Widget _buildProfileTab(dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Text('Update your preferences and view system roles.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: const Text('S', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        const SizedBox(height: 4),
                        Text(user.email, style: const TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),
                _buildProfileDetailRow('System Role', user.role.toString().split('.').last.toUpperCase()),
                _buildProfileDetailRow('Account Status', 'ACTIVE (MOCK)'),
                _buildProfileDetailRow('Mock Security Key', 'SEC-FLUTTER-DEMO-991'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        ],
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
          _sidebarItem(Icons.history_edu_rounded, 'My Attempts', 1),
          _sidebarItem(Icons.person_outline, 'Profile Settings', 2),
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

  Widget _buildQuizCard(BuildContext context, dynamic quiz) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    quiz.subject,
                    style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('${quiz.timeLimitMinutes ?? 15} Mins', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              quiz.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                quiz.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${quiz.questions.length} Questions', style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
                ElevatedButton(
                  onPressed: () => context.push('/student/attempt/${quiz.id}'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Start Quiz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
