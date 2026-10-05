import 'package:flutter/material.dart';
import '../services/formation_service.dart';

String _formatErrorMessage(Object error) {
  final str = error.toString();
  if (str.contains('row-level security') || str.contains('42501')) {
    return 'Permission refusée par Supabase (RLS). Veuillez exécuter le script SQL dans Supabase SQL Editor pour autoriser la table series_courses / course_series.';
  }
  return str.replaceFirst('Exception: ', '').replaceFirst('PostgrestException(', '').replaceAll(')', '');
}

class FormationsScreen extends StatefulWidget {
  const FormationsScreen({super.key});

  @override
  State<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends State<FormationsScreen> {
  bool loading = true;
  String? error;
  List<FormationItem> formations = [];

  @override
  void initState() {
    super.initState();
    loadFormations();
  }

  Future<void> loadFormations() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final list = await FormationService.fetchFormations();
      if (!mounted) return;
      setState(() {
        formations = list;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = _formatErrorMessage(e);
        loading = false;
      });
    }
  }

  Future<void> _openCreateFormation() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final domainController = TextEditingController(text: 'Data Science');
    final levelController = TextEditingController(text: 'All levels');
    final imageController = TextEditingController();
    bool isPublished = true;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create New Formation / Series', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Formation Title *',
                      hintText: 'e.g., Parcours Data Scientist',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Objectives, career outcomes, and prerequisites...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: domainController,
                          decoration: const InputDecoration(
                            labelText: 'Domain / Field',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: levelController,
                          decoration: const InputDecoration(
                            labelText: 'Level',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'Cover Image URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Published (Active)'),
                    value: isPublished,
                    onChanged: (v) => setDialogState(() => isPublished = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84CC16),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                try {
                  await FormationService.createFormation(
                    title: title,
                    description: descController.text.trim(),
                    domain: domainController.text.trim(),
                    level: levelController.text.trim(),
                    imageUrl: imageController.text.trim(),
                    isPublished: isPublished,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Create Formation'),
            ),
          ],
        ),
      ),
    );

    if (created == true && mounted) {
      await loadFormations();
    }
  }

  Future<void> _openEditFormation(FormationItem item) async {
    final titleController = TextEditingController(text: item.title);
    final descController = TextEditingController(text: item.description);
    final domainController = TextEditingController(text: item.domain);
    final levelController = TextEditingController(text: item.level);
    final imageController = TextEditingController(text: item.imageUrl);
    bool isPublished = item.isPublished;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Formation', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Formation Title *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: domainController,
                          decoration: const InputDecoration(labelText: 'Domain / Field', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: levelController,
                          decoration: const InputDecoration(labelText: 'Level', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(labelText: 'Cover Image URL', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Published (Active)'),
                    value: isPublished,
                    onChanged: (v) => setDialogState(() => isPublished = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84CC16),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                try {
                  await FormationService.updateFormation(
                    id: item.id,
                    title: title,
                    description: descController.text.trim(),
                    domain: domainController.text.trim(),
                    level: levelController.text.trim(),
                    imageUrl: imageController.text.trim(),
                    isPublished: isPublished,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    if (updated == true && mounted) {
      await loadFormations();
    }
  }

  Future<void> _deleteFormation(FormationItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Formation', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${item.title}"? The courses themselves will not be deleted.'),
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
      try {
        await FormationService.deleteFormation(item.id);
        if (mounted) {
          setState(() {
            formations.removeWhere((f) => f.id == item.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Formation "${item.title}" deleted successfully.'),
              backgroundColor: const Color(0xFF65A30D),
            ),
          );
          await loadFormations();
        }
      } catch (e) {
        if (mounted) {
          final msg = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $msg'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  void _showFormationDetails(FormationItem item) {
    showDialog(
      context: context,
      builder: (ctx) => FormationDetailsDialog(
        initialItem: item,
        onFormationChanged: loadFormations,
        onEditRequested: () {
          Navigator.pop(ctx);
          _openEditFormation(item);
        },
        onDeleteRequested: () {
          Navigator.pop(ctx);
          _deleteFormation(item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Formations & Learning Paths', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadFormations,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _openCreateFormation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84CC16),
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Formation', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      ElevatedButton(onPressed: loadFormations, child: const Text('Retry')),
                    ],
                  ),
                )
              : formations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.route_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('No formations found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Create learning paths to guide students through structured curricula.', style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _openCreateFormation,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: Colors.black),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Formation'),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          mainAxisExtent: 260,
                        ),
                        itemCount: formations.length,
                        itemBuilder: (context, index) {
                          final item = formations[index];
                          return Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showFormationDetails(item),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(color: const Color(0xFFEFFFD8), borderRadius: BorderRadius.circular(12)),
                                          child: const Icon(Icons.route_outlined, color: Color(0xFF65A30D), size: 24),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: item.isPublished ? const Color(0xFFEFFFD8) : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item.isPublished ? 'Active' : 'Draft',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: item.isPublished ? const Color(0xFF65A30D) : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          tooltip: 'Delete Formation',
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _deleteFormation(item),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.description.isEmpty ? 'Structured learning path' : item.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Chip(visualDensity: VisualDensity.compact, label: Text(item.domain, style: const TextStyle(fontSize: 11))),
                                        const SizedBox(width: 6),
                                        Chip(visualDensity: VisualDensity.compact, label: Text('${item.coursesCount} Courses', style: const TextStyle(fontSize: 11))),
                                        const Spacer(),
                                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

/// Interactive Dialog for Formation Details, Course Management, and Ordering
class FormationDetailsDialog extends StatefulWidget {
  final FormationItem initialItem;
  final VoidCallback onFormationChanged;
  final VoidCallback onEditRequested;
  final VoidCallback onDeleteRequested;

  const FormationDetailsDialog({
    super.key,
    required this.initialItem,
    required this.onFormationChanged,
    required this.onEditRequested,
    required this.onDeleteRequested,
  });

  @override
  State<FormationDetailsDialog> createState() => _FormationDetailsDialogState();
}

class _FormationDetailsDialogState extends State<FormationDetailsDialog> {
  bool loadingCourses = true;
  String? coursesError;
  List<Map<String, dynamic>> courses = [];
  bool reordering = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      loadingCourses = true;
      coursesError = null;
    });

    try {
      final list = await FormationService.fetchCoursesInFormation(widget.initialItem.id);
      if (!mounted) return;
      setState(() {
        courses = list;
        loadingCourses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        coursesError = e.toString().replaceFirst('Exception: ', '');
        loadingCourses = false;
      });
    }
  }

  Future<void> _openAddCourseModal() async {
    final availableCourses = await FormationService.fetchAllAvailableCourses();
    if (!mounted) return;

    final existingCourseIds = courses.map((c) => c['id'].toString()).toSet();

    await showDialog(
      context: context,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = availableCourses.where((c) {
              final title = (c['title'] ?? '').toString().toLowerCase();
              final domain = (c['domain'] ?? '').toString().toLowerCase();
              final q = searchQuery.toLowerCase();
              return title.contains(q) || domain.contains(q);
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Courses to Formation', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 580,
                height: 480,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search by course title or domain...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onChanged: (v) => setModalState(() => searchQuery = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                searchQuery.isEmpty ? 'No courses available.' : 'No matching courses found.',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final course = filtered[i];
                                final courseId = course['id'].toString();
                                final isAdded = existingCourseIds.contains(courseId);

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFFFD8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.school_outlined, color: Color(0xFF65A30D)),
                                  ),
                                  title: Text(
                                    course['title']?.toString() ?? 'Untitled Course',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    '${course['domain'] ?? 'General'} · ${course['level'] ?? 'All levels'}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  trailing: isAdded
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.check_circle, color: Color(0xFF65A30D), size: 18),
                                            SizedBox(width: 4),
                                            Text('Added', style: TextStyle(color: Color(0xFF65A30D), fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        )
                                      : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF84CC16),
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            minimumSize: Size.zero,
                                          ),
                                          onPressed: () async {
                                            try {
                                              final nextOrder = courses.length + 1;
                                              await FormationService.addCourseToFormation(
                                                formationId: widget.initialItem.id,
                                                courseId: courseId,
                                                orderIndex: nextOrder,
                                              );
                                              existingCourseIds.add(courseId);
                                              setModalState(() {});
                                              await _loadCourses();
                                              widget.onFormationChanged();
                                            } catch (e) {
                                              if (ctx.mounted) {
                                                ScaffoldMessenger.of(ctx).showSnackBar(
                                                  SnackBar(content: Text('Error adding course: $e'), backgroundColor: Colors.red),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _moveCourse(int oldIndex, int newIndex) async {
    if (newIndex < 0 || newIndex >= courses.length || reordering) return;

    setState(() {
      final item = courses.removeAt(oldIndex);
      courses.insert(newIndex, item);
      reordering = true;
    });

    try {
      final orderedIds = courses.map((c) => c['id'].toString()).toList();
      await FormationService.reorderCoursesInFormation(
        formationId: widget.initialItem.id,
        orderedCourseIds: orderedIds,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving order: $e'), backgroundColor: Colors.red),
        );
      }
      await _loadCourses();
    } finally {
      if (mounted) {
        setState(() => reordering = false);
      }
    }
  }

  Future<void> _removeCourse(Map<String, dynamic> course) async {
    final title = course['title']?.toString() ?? 'Course';
    final courseId = course['id'].toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Course from Formation'),
        content: Text('Are you sure you want to remove "$title" from this learning path? The course will remain available on the platform.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FormationService.removeCourseFromFormation(
          formationId: widget.initialItem.id,
          courseId: courseId,
        );
        if (mounted) {
          setState(() {
            courses.removeWhere((c) => c['id'].toString() == courseId);
          });
          widget.onFormationChanged();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "$title" from formation'),
              backgroundColor: const Color(0xFF65A30D),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final msg = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing course: $msg'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.initialItem;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFEFFFD8), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.route_outlined, color: Color(0xFF65A30D), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(visualDensity: VisualDensity.compact, label: Text(item.domain, style: const TextStyle(fontSize: 11))),
                            const SizedBox(width: 6),
                            Chip(visualDensity: VisualDensity.compact, label: Text(item.level, style: const TextStyle(fontSize: 11))),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.isPublished ? const Color(0xFFEFFFD8) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.isPublished ? 'Active' : 'Draft',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: item.isPublished ? const Color(0xFF65A30D) : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit Formation Details',
                    onPressed: widget.onEditRequested,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Delete Formation',
                    onPressed: widget.onDeleteRequested,
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(item.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
              const Divider(height: 28),

              // Courses Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Courses in this Formation',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFFFD8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${courses.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF65A30D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84CC16),
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                    onPressed: _openAddCourseModal,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Courses', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Courses List
              Expanded(
                child: loadingCourses
                    ? const Center(child: CircularProgressIndicator())
                    : coursesError != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Error: $coursesError', style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 8),
                                ElevatedButton(onPressed: _loadCourses, child: const Text('Retry')),
                              ],
                            ),
                          )
                        : courses.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No courses linked to this formation yet.',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF84CC16),
                                        foregroundColor: Colors.black,
                                      ),
                                      onPressed: _openAddCourseModal,
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add First Course'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: courses.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (ctx, index) {
                                  final course = courses[index];
                                  final isFirst = index == 0;
                                  final isLast = index == courses.length - 1;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        // Sequence Step Badge
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFFFD8),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Color(0xFF65A30D),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Course Title & Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                course['title']?.toString() ?? 'Untitled Course',
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${course['domain'] ?? 'General'} · ${course['level'] ?? 'All levels'}',
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Reorder Up
                                        IconButton(
                                          tooltip: 'Move Up',
                                          icon: const Icon(Icons.arrow_upward, size: 18),
                                          color: isFirst ? Colors.grey.shade300 : Colors.black87,
                                          onPressed: isFirst ? null : () => _moveCourse(index, index - 1),
                                        ),

                                        // Reorder Down
                                        IconButton(
                                          tooltip: 'Move Down',
                                          icon: const Icon(Icons.arrow_downward, size: 18),
                                          color: isLast ? Colors.grey.shade300 : Colors.black87,
                                          onPressed: isLast ? null : () => _moveCourse(index, index + 1),
                                        ),

                                        const SizedBox(width: 4),

                                        // Remove Course
                                        IconButton(
                                          tooltip: 'Remove from Formation',
                                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                          onPressed: () => _removeCourse(course),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


