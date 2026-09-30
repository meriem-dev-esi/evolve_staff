import 'package:flutter/material.dart';
import '../services/student_progress_service.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  bool loading = true;
  String? error;
  List<StudentOverview> allStudents = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final list = await StudentProgressService.fetchStudentsProgress();
      if (!mounted) return;
      setState(() {
        allStudents = list;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  List<StudentOverview> get displayedStudents {
    if (searchQuery.isEmpty) return allStudents;
    final q = searchQuery.toLowerCase();
    return allStudents.where((s) {
      return s.fullName.toLowerCase().contains(q) || s.email.toLowerCase().contains(q);
    }).toList();
  }

  void _showStudentDetail(StudentOverview student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _StudentDetailSheet(student: student),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayed = displayedStudents;

    // Aggregate statistics
    int totalStudents = allStudents.length;
    int totalCompletedLessons = allStudents.fold(0, (acc, s) => acc + s.completedLessonsCount);
    double avgCompletion = totalStudents > 0
        ? allStudents.fold(0.0, (acc, s) => acc + s.overallPercentage) / totalStudents
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Student Progress Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadStudents,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text('Error: $error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: loadStudents, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stat Cards
                      Row(
                        children: [
                          _statCard('Total Students', totalStudents.toString(), Icons.people_outline, const Color(0xFF84CC16)),
                          const SizedBox(width: 16),
                          _statCard('Avg. Course Completion', '${avgCompletion.toStringAsFixed(1)}%', Icons.pie_chart_outline, const Color(0xFF3B82F6)),
                          const SizedBox(width: 16),
                          _statCard('Completed Lessons', totalCompletedLessons.toString(), Icons.check_circle_outline, const Color(0xFF10B981)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Search bar
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search students by name or email...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (v) => setState(() => searchQuery = v),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Student list
                      if (displayed.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              Icon(Icons.person_search_outlined, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No students found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('Enrolled students will appear here with live completion rates.', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayed.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final s = displayed[index];
                            final pct = s.overallPercentage;
                            final color = pct >= 80 ? const Color(0xFF16A34A) : (pct >= 40 ? const Color(0xFF65A30D) : const Color(0xFFF59E0B));

                            return Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFF84CC16).withValues(alpha: 0.2),
                                  child: Text(
                                    s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ),
                                title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(s.email.isNotEmpty ? s.email : 'No email provided', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          '${s.enrolledCoursesCount} Courses  •  ${s.completedLessonsCount} / ${s.totalLessonsCount} Lessons',
                                          style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                                        ),
                                        const Spacer(),
                                        Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: s.totalLessonsCount > 0 ? (s.completedLessonsCount / s.totalLessonsCount) : 0,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(color),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF7F7F7),
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                  ),
                                  onPressed: () => _showStudentDetail(s),
                                  icon: const Icon(Icons.analytics_outlined, size: 16),
                                  label: const Text('Inspect'),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentDetailSheet extends StatefulWidget {
  final StudentOverview student;
  const _StudentDetailSheet({required this.student});

  @override
  State<_StudentDetailSheet> createState() => _StudentDetailSheetState();
}

class _StudentDetailSheetState extends State<_StudentDetailSheet> {
  String? selectedCourseId;
  List<LessonProgressItem> lessonItems = [];
  bool loadingLessons = false;

  @override
  void initState() {
    super.initState();
    if (widget.student.coursesProgress.isNotEmpty) {
      _selectCourse(widget.student.coursesProgress.first.courseId);
    }
  }

  Future<void> _selectCourse(String courseId) async {
    setState(() {
      selectedCourseId = courseId;
      loadingLessons = true;
    });

    final items = await StudentProgressService.fetchStudentCourseLessons(
      widget.student.id,
      courseId,
    );

    if (!mounted) return;
    setState(() {
      lessonItems = items;
      loadingLessons = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: SizedBox(
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Header
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF84CC16),
                  child: Text(
                    s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(s.email.isNotEmpty ? s.email : 'No email provided', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 32),

            // Courses Tabs
            if (s.coursesProgress.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('This student has not enrolled in any courses yet.'),
                ),
              )
            else ...[
              const Text('Enrolled Courses:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: s.coursesProgress.map((cp) {
                    final isSelected = selectedCourseId == cp.courseId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${cp.courseTitle} (${cp.percentage.toStringAsFixed(0)}%)'),
                        selected: isSelected,
                        selectedColor: const Color(0xFF84CC16),
                        onSelected: (_) => _selectCourse(cp.courseId),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Lesson Details
              const Text('Lesson Progress Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),

              Expanded(
                child: loadingLessons
                    ? const Center(child: CircularProgressIndicator())
                    : lessonItems.isEmpty
                        ? Center(child: Text('No lessons found in this course.', style: TextStyle(color: Colors.grey.shade600)))
                        : ListView.separated(
                            itemCount: lessonItems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final l = lessonItems[i];
                              return ListTile(
                                tileColor: const Color(0xFFF7F7F7),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                leading: Icon(
                                  l.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: l.completed ? const Color(0xFF16A34A) : Colors.grey,
                                  size: 24,
                                ),
                                title: Text(l.title, style: TextStyle(fontWeight: FontWeight.w600, decoration: l.completed ? TextDecoration.lineThrough : null)),
                                subtitle: Text(
                                  l.completed
                                      ? 'Completed ${l.updatedAt != null ? '• ${l.updatedAt!.substring(0, 10)}' : ''}'
                                      : 'Incomplete (${l.progressPercentage}%)',
                                  style: TextStyle(color: l.completed ? const Color(0xFF16A34A) : Colors.grey.shade600, fontSize: 12),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
