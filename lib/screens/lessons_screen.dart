import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'course_details_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> lessons = [];
  List<Map<String, dynamic>> courses = [];
  String selectedCourseId = 'all';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // 1. Fetch courses
      final coursesRes = await supabase
          .from('courses')
          .select('id, title')
          .order('title', ascending: true);
      courses = List<Map<String, dynamic>>.from(coursesRes);

      // 2. Fetch lessons with course join
      final lessonsRes = await supabase
          .from('lessons')
          .select('*, courses(title)')
          .order('order_index', ascending: true);

      lessons = List<Map<String, dynamic>>.from(lessonsRes);

      if (!mounted) return;
      setState(() {
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

  List<Map<String, dynamic>> get filteredLessons {
    return lessons.where((l) {
      final matchesCourse = selectedCourseId == 'all' || l['course_id']?.toString() == selectedCourseId;
      final title = (l['title']?.toString() ?? '').toLowerCase();
      final desc = (l['description']?.toString() ?? '').toLowerCase();
      final matchesSearch = searchQuery.isEmpty ||
          title.contains(searchQuery.toLowerCase()) ||
          desc.contains(searchQuery.toLowerCase());
      return matchesCourse && matchesSearch;
    }).toList();
  }

  Future<void> _openAddLesson() async {
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a course before adding lessons.')),
      );
      return;
    }

    String chosenCourseId = selectedCourseId != 'all' ? selectedCourseId : courses.first['id'].toString();

    final courseChosen = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String tempId = chosenCourseId;
        return AlertDialog(
          title: const Text('Select Course for New Lesson'),
          content: StatefulBuilder(
            builder: (ctx, setDialogState) => DropdownButtonFormField<String>(
              value: tempId,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Target Course'),
              items: courses.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['title']?.toString() ?? 'Course'))).toList(),
              onChanged: (v) => setDialogState(() => tempId = v!),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx, tempId),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (courseChosen == null || !mounted) return;

    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddLessonScreen(courseId: courseChosen)),
    );

    if (created == true && mounted) {
      await loadData();
    }
  }

  Future<void> _deleteLesson(Map<String, dynamic> lesson) async {
    final lessonId = lesson['id'].toString();
    final lessonTitle = lesson['title']?.toString() ?? 'Lesson';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Are you sure you want to delete "$lessonTitle"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('lessons').delete().eq('id', lessonId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lesson "$lessonTitle" deleted.')));
      await loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete lesson: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayed = filteredLessons;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Lessons Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadData,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _openAddLesson,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84CC16),
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Lesson', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
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
                      ElevatedButton(onPressed: loadData, child: const Text('Retry')),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Filter bar
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search lessons by title or description...',
                                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                onChanged: (v) => setState(() => searchQuery = v),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCourseId,
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem(value: 'all', child: Text('All Courses')),
                                    ...courses.map((c) => DropdownMenuItem(
                                          value: c['id'].toString(),
                                          child: Text(c['title']?.toString() ?? 'Course', overflow: TextOverflow.ellipsis),
                                        )),
                                  ],
                                  onChanged: (v) => setState(() => selectedCourseId = v!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: const Color(0xFFEFFFD8), borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              '${displayed.length} lesson${displayed.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Color(0xFF65A30D), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Lessons list
                      Expanded(
                        child: displayed.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_lesson_outlined, size: 56, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    const Text('No lessons found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text('Add a new lesson to get started.', style: TextStyle(color: Colors.grey.shade600)),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _openAddLesson,
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: Colors.black),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Lesson'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: displayed.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final lesson = displayed[index];
                                  final title = lesson['title']?.toString() ?? 'Lesson';
                                  final desc = lesson['description']?.toString() ?? '';
                                  final order = lesson['order_index']?.toString() ?? '1';
                                  final courseTitle = lesson['courses']?['title']?.toString() ?? 'Course';
                                  final duration = lesson['duration'];
                                  final isFree = lesson['is_free'] == true;
                                  final hasVideo = (lesson['video_url']?.toString() ?? '').isNotEmpty ||
                                      (lesson['youtube_url']?.toString() ?? '').isNotEmpty;

                                  return Card(
                                    elevation: 0,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFFEFFFD8),
                                        foregroundColor: const Color(0xFF65A30D),
                                        child: Text(order, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                            child: Text(courseTitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (desc.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                          ],
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              if (duration != null)
                                                Chip(
                                                  visualDensity: VisualDensity.compact,
                                                  avatar: const Icon(Icons.timer_outlined, size: 14),
                                                  label: Text('$duration min', style: const TextStyle(fontSize: 11)),
                                                ),
                                              if (hasVideo)
                                                const Chip(
                                                  visualDensity: VisualDensity.compact,
                                                  avatar: Icon(Icons.play_circle_outline, size: 14, color: Colors.red),
                                                  label: Text('Video', style: TextStyle(fontSize: 11)),
                                                ),
                                              if (isFree)
                                                const Chip(
                                                  visualDensity: VisualDensity.compact,
                                                  avatar: Icon(Icons.lock_open, size: 14, color: Colors.green),
                                                  label: Text('Free Preview', style: TextStyle(fontSize: 11)),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit Lesson',
                                            icon: const Icon(Icons.edit_outlined, size: 20),
                                            onPressed: () async {
                                              final updated = await Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => EditLessonScreen(lesson: lesson)),
                                              );
                                              if (updated == true && mounted) {
                                                await loadData();
                                              }
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'Delete Lesson',
                                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                            onPressed: () => _deleteLesson(lesson),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
