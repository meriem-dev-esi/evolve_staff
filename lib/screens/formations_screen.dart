import 'package:flutter/material.dart';
import '../services/formation_service.dart';

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
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _openCreateFormation() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final domainController = TextEditingController(text: 'Web Development');
    final levelController = TextEditingController(text: 'All levels');
    final imageController = TextEditingController();
    bool isPublished = true;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create New Formation / Series', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
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
                    title: const Text('Published'),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: Colors.black),
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
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (created == true && mounted) {
      await loadFormations();
    }
  }

  void _showFormationDetails(FormationItem item) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>>>(
        future: FormationService.fetchCoursesInFormation(item.id),
        builder: (ctx, snapshot) {
          final courses = snapshot.data ?? [];
          final loadingCourses = snapshot.connectionState == ConnectionState.waiting;

          return Padding(
            padding: const EdgeInsets.all(28),
            child: SizedBox(
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.description.isEmpty ? 'No description' : item.description, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Chip(label: Text(item.domain)),
                      const SizedBox(width: 8),
                      Chip(label: Text(item.level)),
                      const SizedBox(width: 8),
                      Chip(label: Text('${item.coursesCount} Courses')),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Courses in this Formation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: loadingCourses
                        ? const Center(child: CircularProgressIndicator())
                        : courses.isEmpty
                            ? Center(
                                child: Text('No courses linked to this formation yet.', style: TextStyle(color: Colors.grey.shade600)),
                              )
                            : ListView.separated(
                                itemCount: courses.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (ctx, i) {
                                  final c = courses[i];
                                  return ListTile(
                                    tileColor: const Color(0xFFF7F7F7),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFEFFFD8),
                                      child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF65A30D), fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(c['title']?.toString() ?? 'Course', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(c['domain']?.toString() ?? 'General'),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
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
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
