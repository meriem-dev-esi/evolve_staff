import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/assignment_service.dart';

class AssignmentsScreen extends StatefulWidget {
  final String? initialCourseId;
  const AssignmentsScreen({super.key, this.initialCourseId});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final _supabase = Supabase.instance.client;

  bool loading = true;
  String? error;
  List<Assignment> assignments = [];
  List<Map<String, dynamic>> courses = [];
  String selectedCourseId = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialCourseId != null) {
      selectedCourseId = widget.initialCourseId!;
    }
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // 1. Fetch courses
      final cRes = await _supabase
          .from('courses')
          .select('id, title')
          .order('title', ascending: true);
      courses = List<Map<String, dynamic>>.from(cRes);

      // 2. Fetch assignments
      final asgList = await AssignmentService.fetchAssignments(
        courseId: selectedCourseId != 'all' ? selectedCourseId : null,
      );

      if (!mounted) return;
      setState(() {
        assignments = asgList;
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

  Future<void> _openCreateAssignment() async {
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a course first.')),
      );
      return;
    }

    String chosenCourseId = selectedCourseId != 'all' ? selectedCourseId : courses.first['id'].toString();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final maxScoreController = TextEditingController(text: '100');
    DateTime? dueDate = DateTime.now().add(const Duration(days: 7));

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: chosenCourseId,
                    decoration: const InputDecoration(labelText: 'Course *', border: OutlineInputBorder()),
                    items: courses.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['title']?.toString() ?? 'Course'))).toList(),
                    onChanged: (v) => setDialogState(() => chosenCourseId = v!),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Assignment Title *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Instructions / Requirements', border: OutlineInputBorder(), alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: maxScoreController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Max Score', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => dueDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today_outlined, size: 18),
                          label: Text(dueDate != null ? 'Due: ${dueDate!.toLocal().toString().substring(0, 10)}' : 'Select Due Date'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: Colors.black),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                final courseMatch = courses.firstWhere((c) => c['id'].toString() == chosenCourseId, orElse: () => {'title': 'Course'});
                final courseTitle = courseMatch['title']?.toString() ?? 'Course';
                final maxScore = int.tryParse(maxScoreController.text.trim()) ?? 100;

                await AssignmentService.createAssignment(
                  courseId: chosenCourseId,
                  courseTitle: courseTitle,
                  title: title,
                  description: descController.text.trim(),
                  dueDate: dueDate,
                  maxScore: maxScore,
                );

                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Create Assignment'),
            ),
          ],
        ),
      ),
    );

    if (created == true && mounted) {
      await loadData();
    }
  }

  void _openSubmissions(Assignment assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SubmissionsSheet(assignment: assignment),
    );
  }

  Future<void> _deleteAssignment(Assignment assignment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Delete "${assignment.title}"? All submissions will be removed.'),
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

    if (confirm == true) {
      await AssignmentService.deleteAssignment(assignment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assignment "${assignment.title}" deleted.')));
      await loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Assignments & Grading', style: TextStyle(fontWeight: FontWeight.bold)),
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
              onPressed: _openCreateAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84CC16),
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      // Course Filter bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCourseId,
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem(value: 'all', child: Text('Filter by: All Courses')),
                                    ...courses.map((c) => DropdownMenuItem(
                                          value: c['id'].toString(),
                                          child: Text(c['title']?.toString() ?? 'Course'),
                                        )),
                                  ],
                                  onChanged: (v) {
                                    setState(() => selectedCourseId = v!);
                                    loadData();
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: const Color(0xFFEFFFD8), borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              '${assignments.length} Assignment${assignments.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Color(0xFF65A30D), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Assignments List
                      Expanded(
                        child: assignments.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.assignment_outlined, size: 56, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    const Text('No assignments found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text('Create assignments for your courses to collect and grade student work.', style: TextStyle(color: Colors.grey.shade600)),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _openCreateAssignment,
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: Colors.black),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Create Assignment'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: assignments.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final asg = assignments[index];
                                  final dueStr = asg.dueDate != null ? asg.dueDate!.toLocal().toString().substring(0, 10) : 'No deadline';

                                  return Card(
                                    elevation: 0,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(color: const Color(0xFFEFFFD8), borderRadius: BorderRadius.circular(10)),
                                                child: Text(
                                                  asg.courseTitle,
                                                  style: const TextStyle(color: Color(0xFF65A30D), fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                                child: Text('Max: ${asg.maxScore} pts', style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                                              ),
                                              const Spacer(),
                                              Row(
                                                children: [
                                                  const Icon(Icons.event_outlined, size: 16, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text('Due: $dueStr', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(asg.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          if (asg.description.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(asg.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                          ],
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () => _openSubmissions(asg),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF84CC16),
                                                  foregroundColor: Colors.black,
                                                  elevation: 0,
                                                ),
                                                icon: const Icon(Icons.rate_review_outlined, size: 16),
                                                label: const Text('View Submissions & Grade', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                tooltip: 'Delete Assignment',
                                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                                onPressed: () => _deleteAssignment(asg),
                                              ),
                                            ],
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

class _SubmissionsSheet extends StatefulWidget {
  final Assignment assignment;
  const _SubmissionsSheet({required this.assignment});

  @override
  State<_SubmissionsSheet> createState() => _SubmissionsSheetState();
}

class _SubmissionsSheetState extends State<_SubmissionsSheet> {
  bool loading = true;
  List<Submission> submissions = [];

  @override
  void initState() {
    super.initState();
    loadSubmissions();
  }

  Future<void> loadSubmissions() async {
    setState(() => loading = true);
    final list = await AssignmentService.fetchSubmissions(widget.assignment.id);
    if (!mounted) return;
    setState(() {
      submissions = list;
      loading = false;
    });
  }

  void _gradeDialog(Submission sub) {
    final gradeController = TextEditingController(text: sub.grade?.toString() ?? '');
    final feedbackController = TextEditingController(text: sub.feedback ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Grade Submission - ${sub.studentName}'),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Submitted: ${sub.submittedAt.toLocal().toString().substring(0, 16)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(8)),
                child: SelectableText(sub.content, style: const TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gradeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Grade (out of ${widget.assignment.maxScore}) *',
                  border: const OutlineInputBorder(),
                  suffixText: '/ ${widget.assignment.maxScore}',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Teacher Feedback', border: OutlineInputBorder(), alignLabelWithHint: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: Colors.black),
            onPressed: () async {
              final g = double.tryParse(gradeController.text.trim());
              if (g == null) return;
              await AssignmentService.gradeSubmission(
                submissionId: sub.id,
                grade: g,
                feedback: feedbackController.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              await loadSubmissions();
            },
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: SizedBox(
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submissions: ${widget.assignment.title}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('${widget.assignment.courseTitle}  •  Max ${widget.assignment.maxScore} pts', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 28),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : submissions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              const Text('No submissions yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Student work will appear here when submitted.', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: submissions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final sub = submissions[index];
                            return Card(
                              elevation: 0,
                              color: const Color(0xFFF7F7F7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF84CC16),
                                  foregroundColor: Colors.black,
                                  child: Text(sub.studentName.isNotEmpty ? sub.studentName[0].toUpperCase() : 'S', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                title: Text(sub.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sub.studentEmail, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(sub.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                    if (sub.isGraded) ...[
                                      const SizedBox(height: 4),
                                      Text('Feedback: ${sub.feedback ?? 'None'}', style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontStyle: FontStyle.italic)),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: sub.isGraded ? const Color(0xFFEFFFD8) : Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        sub.isGraded ? '${sub.grade?.toStringAsFixed(0)} / ${widget.assignment.maxScore}' : 'Ungraded',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: sub.isGraded ? const Color(0xFF65A30D) : Colors.amber.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                      ),
                                      onPressed: () => _gradeDialog(sub),
                                      child: Text(sub.isGraded ? 'Edit Grade' : 'Grade'),
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
