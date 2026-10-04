import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'courses_screen.dart';
import 'create_course_screen.dart';
import 'course_details_screen.dart';
import 'lessons_screen.dart';
import 'formations_screen.dart';
import 'student_progress_screen.dart';
import 'assignments_screen.dart';
import 'users_management_screen.dart';
import 'revenue_screen.dart';
import 'messages_screen.dart';
import 'login_screen.dart';
import 'admin_analytics_screen.dart';
import '../services/admin_dashboard_service.dart';
import '../services/analytics_service.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  final String fullName;

  const DashboardScreen({
    super.key,
    required this.role,
    required this.fullName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;

  int courses = 0;
  int students = 0;
  int formations = 0;
  int lessons = 0;
  bool loading = true;
  String? errorMessage;
  List<Map<String, dynamic>> recentActivities = [];
  AdminDashboardOverview? adminOverview;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final overview = widget.role == 'admin'
          ? await AdminDashboardOverview.fetch()
          : null;
      final stats = overview == null
          ? await AnalyticsService.fetchStats(widget.role)
          : {
              'courses': overview.courses,
              'students': overview.students,
              'formations': overview.formations,
              'lessons': overview.lessons,
            };
      List<Map<String, dynamic>> recents = [];
      if (overview != null) {
        recents = overview.recentCourses;
      } else {
        final res = await supabase
            .from('courses')
            .select('id, title, domain, created_at')
            .order('created_at', ascending: false)
            .limit(5);
        recents = List<Map<String, dynamic>>.from(res);
      }

      if (!mounted) return;
      setState(() {
        courses = stats['courses'] ?? 0;
        students = stats['students'] ?? 0;
        formations = stats['formations'] ?? 0;
        lessons = stats['lessons'] ?? 0;
        recentActivities = recents;
        adminOverview = overview;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        adminOverview = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out from Evolve Staff Portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _quickAddLesson() async {
    try {
      final coursesRes = await supabase
          .from('courses')
          .select('id, title')
          .order('title', ascending: true);
      if (coursesRes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please create a course before adding lessons.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      String selectedId = coursesRes.first['id'].toString();

      final chosen = await showDialog<String>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Select Course for Lesson'),
            content: DropdownButtonFormField<String>(
              value: selectedId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Target Course',
              ),
              items: coursesRes
                  .map(
                    (c) => DropdownMenuItem(
                      value: c['id'].toString(),
                      child: Text(c['title']?.toString() ?? 'Course'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setDialogState(() => selectedId = v!),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF84CC16),
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(ctx, selectedId),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      );

      if (chosen != null && mounted) {
        final created = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddLessonScreen(courseId: chosen)),
        );
        if (created == true && mounted) {
          await _loadDashboardData();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openUsers({String initialRoleFilter = 'all'}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UsersManagementScreen(initialRoleFilter: initialRoleFilter),
      ),
    );
    if (mounted) await _loadDashboardData();
  }

  Future<void> _openRevenue() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RevenueScreen()),
    );
    if (mounted) await _loadDashboardData();
  }

  Future<void> _openCourseModeration() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CoursesScreen(initialStatusFilter: 'draft'),
      ),
    );
    if (mounted) await _loadDashboardData();
  }

  void _showStatsOverview() {
    if (widget.role == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Evolve Platform Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.school, color: Color(0xFF65A30D)),
                title: const Text('Active Courses'),
                trailing: Text(
                  '$courses',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.people, color: Color(0xFF3B82F6)),
                title: const Text('Enrolled Students'),
                trailing: Text(
                  '$students',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.route, color: Color(0xFFF59E0B)),
                title: const Text('Structured Formations'),
                trailing: Text(
                  '$formations',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.play_lesson,
                  color: Color(0xFF8B5CF6),
                ),
                title: const Text('Total Lessons'),
                trailing: Text(
                  '$lessons',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == 'admin';
    final fullName = widget.fullName;
    final role = widget.role;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context, isAdmin, role, fullName),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Welcome back, ${fullName.isEmpty ? 'Staff Member' : fullName}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Refresh Dashboard',
                        onPressed: loading ? null : _loadDashboardData,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Stats row (clickable cards)
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Unable to load dashboard: $errorMessage',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: loading ? null : _loadDashboardData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 1050
                                ? 4
                                : 2;
                            return GridView.count(
                              crossAxisCount: columns,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: columns == 4 ? 1.35 : 1.8,
                              children: [
                                _statCard(
                                  'Courses',
                                  courses.toString(),
                                  Icons.school_outlined,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CoursesScreen(),
                                    ),
                                  ),
                                ),
                                _statCard(
                                  'Students',
                                  students.toString(),
                                  Icons.people_outline,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const StudentProgressScreen(),
                                    ),
                                  ),
                                ),
                                _statCard(
                                  'Formations',
                                  formations.toString(),
                                  Icons.route_outlined,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FormationsScreen(),
                                    ),
                                  ),
                                ),
                                _statCard(
                                  'Lessons',
                                  lessons.toString(),
                                  Icons.play_lesson_outlined,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LessonsScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                  if (isAdmin && adminOverview != null) ...[
                    const SizedBox(height: 36),
                    _buildAdminOverview(adminOverview!),
                  ],
                  const SizedBox(height: 36),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 1050 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: columns == 4 ? 2.5 : 3.2,
                        children: [
                          _actionCard(
                            Icons.add_circle_outline,
                            'Create Course',
                            'Add a new course to curriculum',
                            onTap: () async {
                              final created = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateCourseScreen(),
                                ),
                              );
                              if (created == true && mounted) {
                                await _loadDashboardData();
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          _actionCard(
                            Icons.video_call_outlined,
                            'Add Lesson',
                            'Create a new video or lecture',
                            onTap: _quickAddLesson,
                          ),
                          const SizedBox(width: 16),
                          _actionCard(
                            Icons.route_outlined,
                            'Create Formation',
                            'Build a structured learning path',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FormationsScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _actionCard(
                            Icons.rate_review_outlined,
                            'Grade Submissions',
                            'Evaluate student homework',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AssignmentsScreen(),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 36),

                  // Recent Activity
                  const Text(
                    'Recent Platform Activity',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: recentActivities.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No recent activity recorded yet.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: recentActivities.map((item) {
                              final title =
                                  item['title']?.toString() ?? 'Course';
                              final domain =
                                  item['domain']?.toString() ?? 'General';
                              final dateStr = _formatActivityDate(
                                item['created_at'],
                              );
                              final published = item['is_published'] == true;

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFFFD8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.school_outlined,
                                    color: Color(0xFF65A30D),
                                  ),
                                ),
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  isAdmin
                                      ? '$domain · ${published ? 'Published' : 'Draft'}'
                                      : domain,
                                ),
                                trailing: Text(
                                  dateStr,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
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

  Widget _buildAdminOverview(AdminDashboardOverview overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin overview',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Platform health, account activity, and items that may need attention.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1100
                ? 3
                : constraints.maxWidth >= 650
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: columns == 1
                  ? 3.4
                  : columns == 2
                  ? 2.2
                  : 1.85,
              children: [
                _adminMetricCard(
                  title: 'Total users',
                  value: overview.totalUsers,
                  subtitle: '${overview.students} students',
                  icon: Icons.people_outline,
                  color: const Color(0xFF2563EB),
                  onTap: () => _openUsers(),
                ),
                _adminMetricCard(
                  title: 'Teachers',
                  value: overview.teachers,
                  subtitle: 'Teaching accounts',
                  icon: Icons.co_present_outlined,
                  color: const Color(0xFF7C3AED),
                  onTap: () => _openUsers(initialRoleFilter: 'teacher'),
                ),
                _adminMetricCard(
                  title: 'New accounts · 7 days',
                  value: overview.newUsersLastSevenDays,
                  subtitle: '${overview.administrators} administrators',
                  icon: Icons.person_add_alt_1_outlined,
                  color: const Color(0xFF0891B2),
                  onTap: () => _openUsers(),
                ),
                _adminMetricCard(
                  title: 'Pending checkouts',
                  value: overview.pendingPayments,
                  subtitle: 'Awaiting payment confirmation',
                  icon: Icons.pending_actions_outlined,
                  color: const Color(0xFFD97706),
                  onTap: _openRevenue,
                ),
                _adminMetricCard(
                  title: 'Published courses',
                  value: overview.publishedCourses,
                  subtitle: 'Of ${overview.courses} total courses',
                  icon: Icons.public_outlined,
                  color: const Color(0xFF65A30D),
                  onTap: _openCourseModeration,
                ),
                _adminMetricCard(
                  title: 'Courses needing review',
                  value: overview.draftCourses,
                  subtitle: 'Drafts not visible to students',
                  icon: Icons.rate_review_outlined,
                  color: const Color(0xFFEA580C),
                  onTap: _openCourseModeration,
                ),
                _adminMetricCard(
                  title: 'Paid enrollments',
                  value: overview.paidEnrollments,
                  subtitle:
                      '${overview.lessons} lessons · ${overview.formations} formations',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFFDB2777),
                  onTap: _openRevenue,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recent sign-ups',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openUsers(),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Manage users'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (overview.recentUsers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No user accounts found.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...overview.recentUsers.map((user) {
                  final name = user['full_name']?.toString().trim();
                  final role = user['role']?.toString() ?? 'student';
                  final roleLabel = role.isEmpty
                      ? 'Student'
                      : '${role[0].toUpperCase()}${role.substring(1)}';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(
                        0xFF84CC16,
                      ).withValues(alpha: 0.15),
                      foregroundColor: const Color(0xFF4D7C0F),
                      child: Text(
                        name != null && name.isNotEmpty
                            ? name[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(
                      name == null || name.isEmpty ? 'New user' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(roleLabel),
                    trailing: Text(
                      _formatActivityDate(user['created_at']),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _adminMetricCard({
    required String title,
    required int value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatActivityDate(dynamic rawDate) {
    final parsed = DateTime.tryParse(rawDate?.toString() ?? '');
    if (parsed == null) return 'Date unavailable';
    final local = parsed.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  Widget _buildSidebar(
    BuildContext context,
    bool isAdmin,
    String role,
    String fullName,
  ) {
    return Container(
      width: 250,
      color: const Color(0xFF111111),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EVOLVE',
            style: TextStyle(
              color: Color(0xFF84CC16),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Staff Portal',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 36),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _menuItem(
                    context,
                    Icons.dashboard_outlined,
                    'Dashboard',
                    onTap: _loadDashboardData,
                  ),
                  _menuItem(
                    context,
                    Icons.school_outlined,
                    'My Courses',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CoursesScreen()),
                    ),
                  ),
                  _menuItem(
                    context,
                    Icons.play_lesson_outlined,
                    'Lessons',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LessonsScreen()),
                    ),
                  ),
                  _menuItem(
                    context,
                    Icons.route_outlined,
                    'Formations',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FormationsScreen(),
                      ),
                    ),
                  ),
                  _menuItem(
                    context,
                    Icons.assignment_outlined,
                    'Assignments',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssignmentsScreen(),
                      ),
                    ),
                  ),
                  _menuItem(
                    context,
                    Icons.people_outline,
                    'Students Progress',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentProgressScreen(),
                      ),
                    ),
                  ),
                  _menuItem(
                    context,
                    Icons.mail_outline,
                    'Student Messages',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MessagesScreen()),
                    ),
                  ),
                  _menuItem(
                    context,
                    Icons.analytics_outlined,
                    isAdmin ? 'Management Statistics' : 'Statistics',
                    onTap: _showStatsOverview,
                  ),

                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'ADMINISTRATION',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _menuItem(
                      context,
                      Icons.manage_accounts_outlined,
                      'Users & Roles',
                      onTap: () => _openUsers(),
                    ),
                    _menuItem(
                      context,
                      Icons.payments_outlined,
                      'Revenue',
                      onTap: _openRevenue,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // User Profile Card & Sign Out
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF84CC16),
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'E',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isEmpty ? 'Staff Member' : fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF84CC16),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white60,
                    size: 18,
                  ),
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: Colors.white70, size: 20),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF84CC16), size: 28),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.black26,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFFD8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF65A30D)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
