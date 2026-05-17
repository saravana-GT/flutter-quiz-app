import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_platform/providers/auth_provider.dart';
import 'package:quiz_platform/providers/quiz_provider.dart';
import 'package:quiz_platform/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class ApproverDashboard extends ConsumerStatefulWidget {
  const ApproverDashboard({super.key});

  @override
  ConsumerState<ApproverDashboard> createState() => _ApproverDashboardState();
}

class _ApproverDashboardState extends ConsumerState<ApproverDashboard> {
  int _currentTab = 0; // 0: Moderation Queue, 1: Approval History, 2: Security Audit

  @override
  Widget build(BuildContext context) {
    final pendingQuizzesAsync = ref.watch(pendingQuizzesProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context, ref),
          
          // Main Body switcher
          Expanded(
            child: _buildMainContent(pendingQuizzesAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(AsyncValue<dynamic> pendingQuizzesAsync) {
    switch (_currentTab) {
      case 0:
        return _buildModerationQueueTab(pendingQuizzesAsync);
      case 1:
        return _buildHistoryTab();
      case 2:
        return _buildSecurityAuditTab();
      default:
        return const SizedBox();
    }
  }

  // Tab 0: Moderation Queue
  Widget _buildModerationQueueTab(AsyncValue<dynamic> pendingQuizzesAsync) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Approver Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                SizedBox(height: 4),
                Text('Review and moderate submitted quiz content to ensure quality standard.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 32, 40, 16),
            child: pendingQuizzesAsync.when(
              data: (quizzes) {
                final pending = quizzes.length;
                return Row(
                  children: [
                    _buildStatCard('Pending Moderation', pending.toString(), Icons.pending_actions_outlined, AppTheme.warning),
                    const SizedBox(width: 24),
                    _buildStatCard('Approved Quizzes', '1', Icons.verified_outlined, AppTheme.accent),
                    const SizedBox(width: 24),
                    _buildStatCard('Rejected Quizzes', '0', Icons.gavel_outlined, AppTheme.error),
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
            child: Text('Quizzes Pending Approval', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          sliver: pendingQuizzesAsync.when(
            data: (quizzes) {
              if (quizzes.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80.0),
                      child: Text('All caught up! No quizzes pending moderation.', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildModerationListItem(context, quizzes[index]),
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

  // Tab 1: Approval History Tab
  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Moderation Log Book', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Text('Track all historically approved or rejected assessments.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildHistoryItem('Flutter Basics', 'APPROVED', '2026-05-17', AppTheme.accent),
                _mockDivider(),
                _buildHistoryItem('Python OOP Foundations', 'APPROVED', '2026-05-15', AppTheme.accent),
                _mockDivider(),
                _buildHistoryItem('Javascript Basics v2', 'REJECTED (Missing MCQ options)', '2026-05-12', AppTheme.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockDivider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8.0),
    child: Divider(color: Color(0xFFF1F5F9)),
  );

  Widget _buildHistoryItem(String quizTitle, String status, String date, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quizTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
              const SizedBox(height: 6),
              Text('Processed on: $date', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Tab 2: Security Audit Tab
  Widget _buildSecurityAuditTab() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Security Auditing Log', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Text('Real-time audit log of system auth, moderation actions and package deployments.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Event', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actor', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: [
                      _auditRow('2026-05-17 10:14', 'User Session Sign-In', 'student@test.com', 'SUCCESS (IP: 192.168.1.1)'),
                      _auditRow('2026-05-17 09:20', 'Quiz Assessment Creation', 'teacher@test.com', 'DRAFT PREPARED'),
                      _auditRow('2026-05-17 08:15', 'System Deploy Trigger', 'CI/CD runner v1.2', 'COMPLETED'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _auditRow(String time, String event, String actor, String status) {
    return DataRow(
      cells: [
        DataCell(Text(time)),
        DataCell(Text(event, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(actor)),
        DataCell(Text(status, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref) {
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
          _sidebarItem(Icons.gavel_rounded, 'Moderation Queue', 0),
          _sidebarItem(Icons.history_rounded, 'Approval History', 1),
          _sidebarItem(Icons.security_rounded, 'Security Audit', 2),
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

  Widget _buildModerationListItem(BuildContext context, dynamic quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text('${quiz.subject} • ${quiz.questions.length} Questions', style: const TextStyle(color: AppTheme.textMuted)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.warning.withOpacity(0.15)),
              ),
              child: const Text(
                'NEEDS REVIEW',
                style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => context.push('/approver/review/${quiz.id}'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Review'),
            ),
          ],
        ),
      ),
    );
  }
}
