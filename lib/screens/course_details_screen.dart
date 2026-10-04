import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_course_screen.dart';
import 'course_files_screen.dart';


class CourseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final supabase = Supabase.instance.client;

  bool loadingLessons = true;
  String? error;

  List<Map<String, dynamic>> lessons = [];

  @override
  void initState() {
    super.initState();
    loadLessons();
  }

  Future<void> loadLessons() async {
    try {
      final courseId = widget.course['id'];

      final response = await supabase
          .from('lessons')
          .select('id, title, description, order_index')
          .eq('course_id', courseId)
          .order('order_index', ascending: true);

      if (!mounted) return;

      setState(() {
        lessons = List<Map<String, dynamic>>.from(response);

        loadingLessons = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loadingLessons = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.course['title']?.toString() ?? 'Untitled Course';

    final description = widget.course['description']?.toString() ?? '';

    final level = widget.course['level']?.toString() ?? 'All levels';

    final domain = widget.course['domain']?.toString() ?? 'General';

    final imageUrl = widget.course['image_url']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: const Text(
          'Course Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // =========================
            // COURSE HEADER
            // =========================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                _courseImage(imageUrl),

                const SizedBox(width: 24),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          _tag(
                            domain,
                            const Color(0xFFEFFFD8),
                            const Color(0xFF65A30D),
                          ),

                          const SizedBox(width: 8),

                          _tag(
                            level,
                            Colors.grey.shade200,
                            Colors.grey.shade700,
                          ),
                        ],
                      ),

                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 16),

                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditCourseScreen(course: widget.course),
                            ),
                          );

                          if (updated == true && mounted) {
                            Navigator.pop(context, true);
                          }
                        },

                        icon: const Icon(Icons.edit_outlined),

                        label: const Text('Edit Course'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // =========================
            // LESSONS
            // =========================
            const Text(
              'Lessons',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            _buildLessons(),

            const SizedBox(height: 40),

            // =========================
            // COURSE FILES
            // =========================
            const Text(
              'Course Files',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFFFD8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      color: Color(0xFF65A30D),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course Resources',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Upload PDFs, videos, documents, images, ZIP files and other course materials.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseFilesScreen(
                            course: widget.course,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Manage Files'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessons() {
    if (loadingLessons) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),

            const SizedBox(height: 12),

            const Text(
              'Failed to load lessons',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  loadingLessons = true;
                  error = null;
                });

                loadLessons();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (lessons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),

        child: Column(
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 50,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 12),

            const Text(
              'No lessons yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Add lessons to this course.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(lessons.length, (index) {
        final lesson = lessons[index];

        return Card(
          elevation: 0,

          margin: const EdgeInsets.only(bottom: 12),

          child: ListTile(
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LessonDetailsScreen(lesson: lesson),
                ),
              );

              if (updated == true && mounted) {
                loadLessons();
              }
            },

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),

            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEFFFD8),

              child: Text(
                '${index + 1}',

                style: const TextStyle(
                  color: Color(0xFF65A30D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            title: Text(
              lesson['title']?.toString() ?? 'Untitled Lesson',

              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            subtitle: lesson['description'] != null
                ? Text(
                    lesson['description'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,

            trailing: const Icon(Icons.chevron_right),
          ),
        );
      }),
    );
  }

  Widget _courseImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),

      child: imageUrl.isEmpty
          ? Container(
              width: 260,
              height: 160,
              color: Colors.grey.shade200,

              child: Icon(
                Icons.school_outlined,
                size: 60,
                color: Colors.grey.shade500,
              ),
            )
          : Image.network(
              imageUrl,
              width: 260,
              height: 160,
              fit: BoxFit.cover,

              errorBuilder: (_, __, ___) {
                return Container(
                  width: 260,
                  height: 160,
                  color: Colors.grey.shade200,

                  child: Icon(
                    Icons.school_outlined,
                    size: 60,
                    color: Colors.grey.shade500,
                  ),
                );
              },
            ),
    );
  }

  Widget _tag(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        text,

        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================
// LESSON DETAILS SCREEN
// =============================================================

class LessonDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> lesson;

  const LessonDetailsScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final title = lesson['title']?.toString() ?? 'Untitled Lesson';

    final description = lesson['description']?.toString() ?? '';

    final orderIndex = lesson['order_index']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: const Text(
          'Lesson Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),

            child: Card(
              elevation: 0,
              color: Colors.white,

              child: Padding(
                padding: const EdgeInsets.all(28),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Lesson $orderIndex',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      description.isEmpty
                          ? 'No description available.'
                          : description,

                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditLessonScreen(lesson: lesson),
                          ),
                        );

                        if (updated == true && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },

                      icon: const Icon(Icons.edit_outlined),

                      label: const Text('Edit Lesson'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// EDIT LESSON SCREEN
// =============================================================

class EditLessonScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;

  const EditLessonScreen({super.key, required this.lesson});

  @override
  State<EditLessonScreen> createState() => _EditLessonScreenState();
}

class _EditLessonScreenState extends State<EditLessonScreen> {
  final supabase = Supabase.instance.client;

  late final TextEditingController titleController;

  late final TextEditingController descriptionController;

  late final TextEditingController orderController;

  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.lesson['title']?.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.lesson['description']?.toString() ?? '',
    );

    orderController = TextEditingController(
      text: widget.lesson['order_index']?.toString() ?? '1',
    );
  }

  Future<void> saveLesson() async {
    final title = titleController.text.trim();

    final description = descriptionController.text.trim();

    final orderIndex = int.tryParse(orderController.text.trim());

    if (title.isEmpty) {
      setState(() {
        error = 'Lesson title is required.';
      });
      return;
    }

    if (orderIndex == null || orderIndex < 1) {
      setState(() {
        error = 'Please enter a valid order number.';
      });
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      await supabase
          .from('lessons')
          .update({
            'title': title,
            'description': description.isEmpty ? null : description,
            'order_index': orderIndex,
          })
          .eq('id', widget.lesson['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson updated successfully.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    orderController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: const Text(
          'Edit Lesson',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),

            child: Card(
              elevation: 0,
              color: Colors.white,

              child: Padding(
                padding: const EdgeInsets.all(28),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Lesson Information',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: titleController,

                      decoration: const InputDecoration(
                        labelText: 'Lesson Title',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: descriptionController,

                      maxLines: 6,

                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: orderController,

                      keyboardType: TextInputType.number,

                      decoration: const InputDecoration(
                        labelText: 'Order',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 16),

                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,

                      children: [
                        OutlinedButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(context),

                          child: const Text('Cancel'),
                        ),

                        const SizedBox(width: 12),

                        ElevatedButton.icon(
                          onPressed: saving ? null : saveLesson,

                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),

                          label: Text(saving ? 'Saving...' : 'Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
