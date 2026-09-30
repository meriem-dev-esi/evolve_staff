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
import 'messages_screen.dart';
import 'login_screen.dart';
import '../services/analytics_service.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  final String fullName;

  const DashboardScreen({super.key, required this.role, required this.fullName});

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

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      loading = true;
    });
    try {
      final stats = await AnalyticsService.fetchStats(widget.role);

      // Fetch recent courses as recent activity
      List<Map<String, dynamic>> recents = [];
      try {
        final res = await supabase
            .from('courses')
            .select('id, title, domain, created_at')
            .order('created_at', ascending: false)
            .limit(5);
        recents = List<Map<String, dynamic>>.from(res);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        courses = stats['courses'] ?? 0;
        students = stats['students'] ?? 0;
        formations = stats['formations'] ?? 0;
        lessons = stats['lessons'] ?? 0;
        recentActivities = recents;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
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
        content: const Text('Are you sure you want to sign out from Evolve Staff Portal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
      final coursesRes = await supabase.from('courses').select('id, title').order('title', ascending: true);
      if (coursesRes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please create a course before adding lessons.')),
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
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Target Course'),
              items: coursesRes.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['title']?.toString() ?? 'Course'))).toList(),
              onChanged: (v) => setDialogState(() => selectedId = v!),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: Colors.black),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showStatsOverview() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Evolve Platform Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.school, color: Color(0xFF65A30D)),
                title: const Text('Active Courses'),
                trailing: Text('$courses', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.people, color: Color(0xFF3B82F6)),
                title: const Text('Enrolled Students'),
                trailing: Text('$students', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.route, color: Color(0xFFF59E0B)),
                title: const Text('Structured Formations'),
                trailing: Text('$formations', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.play_lesson, color: Color(0xFF8B5CF6)),
                title: const Text('Total Lessons'),
                trailing: Text('$lessons', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
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
                          const Text('Dashboard', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF212121))),
                          const SizedBox(height: 6),
                          Text('Welcome back, ${fullName.isEmpty ? 'Staff Member' : fullName}', style: const TextStyle(color: Colors.grey, fontSize: 16)),
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
                          ? Text('Error loading stats: $errorMessage', style: const TextStyle(color: Colors.red))
                          : Row(
                              children: [
                                _statCard(
                                  'Courses',
                                  courses.toString(),
                                  Icons.school_outlined,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesScreen())),
                                ),
                                const SizedBox(width: 20),
                                _statCard(
                                  'Students',
                                  students.toString(),
                                  Icons.people_outline,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProgressScreen())),
                                ),
                                const SizedBox(width: 20),
                                _statCard(
                                  'Formations',
                                  formations.toString(),
                                  Icons.route_outlined,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormationsScreen())),
                                ),
                                const SizedBox(width: 20),
                                _statCard(
                                  'Lessons',
                                  lessons.toString(),
                                  Icons.play_lesson_outlined,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonsScreen())),
                                ),
                              ],
                            ),
                  const SizedBox(height: 36),

                  // Quick Actions
                  const Text('Quick Actions', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _actionCard(
                        Icons.add_circle_outline,
                        'Create Course',
                        'Add a new course to curriculum',
                        onTap: () async {
                          final created = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateCourseScreen()),
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
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormationsScreen())),
                      ),
                      const SizedBox(width: 16),
                      _actionCard(
                        Icons.rate_review_outlined,
                        'Grade Submissions',
                        'Evaluate student homework',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Recent Activity
                  const Text('Recent Platform Activity', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: recentActivities.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('No recent activity recorded yet.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: recentActivities.map((item) {
                              final title = item['title']?.toString() ?? 'Course';
                              final domain = item['domain']?.toString() ?? 'General';
                              final dateStr = item['created_at'] != null ? item['created_at'].toString().substring(0, 10) : '';

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFFEFFFD8), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.school_outlined, color: Color(0xFF65A30D)),
                                ),
                                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(domain),
                                trailing: Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
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

  Widget _buildSidebar(BuildContext context, bool isAdmin, String role, String fullName) {
    return Container(
      width: 250,
      color: const Color(0xFF111111),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EVOLVE', style: TextStyle(color: Color(0xFF84CC16), fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Staff Portal', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 36),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _menuItem(context, Icons.dashboard_outlined, 'Dashboard', onTap: _loadDashboardData),
                  _menuItem(context, Icons.school_outlined, 'My Courses',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesScreen()))),
                  _menuItem(context, Icons.play_lesson_outlined, 'Lessons',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonsScreen()))),
                  _menuItem(context, Icons.route_outlined, 'Formations',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormationsScreen()))),
                  _menuItem(context, Icons.assignment_outlined, 'Assignments',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen()))),
                  _menuItem(context, Icons.people_outline, 'Students Progress',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProgressScreen()))),
                  _menuItem(context, Icons.mail_outline, 'Student Messages',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()))),
                  _menuItem(context, Icons.analytics_outlined, 'Statistics',
                      onTap: _showStatsOverview),

                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    const Text('ADMINISTRATION', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _menuItem(context, Icons.manage_accounts_outlined, 'Users & Roles',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersManagementScreen()))),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // User Profile Card & Sign Out
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF84CC16),
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'E',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName.isEmpty ? 'Staff Member' : fullName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(role.toUpperCase(), style: const TextStyle(color: Color(0xFF84CC16), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(Icons.logout, color: Colors.white60, size: 18),
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
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
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: Material(
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
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black26),
                  ],
                ),
                const SizedBox(height: 18),
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionCard(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Expanded(
      child: Material(
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
                  decoration: BoxDecoration(color: const Color(0xFFEFFFD8), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: const Color(0xFF65A30D)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
