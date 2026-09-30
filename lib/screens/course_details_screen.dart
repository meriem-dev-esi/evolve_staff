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

  List<Map<String, dynamic>> lessons = [];

  bool loadingLessons = true;
  String? lessonsError;

  @override
  void initState() {
    super.initState();
    loadLessons();
  }

  Future<void> loadLessons() async {
    if (!mounted) return;

    setState(() {
      loadingLessons = true;
      lessonsError = null;
    });

    try {
      final courseId = widget.course['id'].toString();

      final response = await supabase
          .from('lessons')
          .select(
            'id, title, description, video_url, youtube_url, duration, order_index, is_free',
          )
          .eq('course_id', courseId)
          .order('order_index', ascending: true);

      if (!mounted) return;

      setState(() {
        lessons = List<Map<String, dynamic>>.from(response);
        loadingLessons = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        lessonsError = e.toString();
        loadingLessons = false;
      });
    }
  }

  Future<void> addLesson() async {
    final courseId = widget.course['id'].toString();

    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddLessonScreen(courseId: courseId)),
    );

    if (!mounted) return;

    if (created == true) {
      await loadLessons();
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    final title = course['title']?.toString() ?? 'Untitled Course';
    final description = course['description']?.toString() ?? '';
    final domain = course['domain']?.toString() ?? '';
    final level = course['level']?.toString() ?? '';
    final imageUrl = course['image_url']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourseHeader(
              title: title,
              description: description,
              domain: domain,
              level: level,
              imageUrl: imageUrl,
            ),

            const SizedBox(height: 32),

            _buildLessons(),

            const SizedBox(height: 32),

            _buildCourseFiles(),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseHeader({
    required String title,
    required String description,
    required String domain,
    required String level,
    required String imageUrl,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      width: double.infinity,
                      height: 220,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 60,
                      ),
                    );
                  },
                ),
              ),

            if (imageUrl.isNotEmpty) const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                ElevatedButton.icon(
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditCourseScreen(course: widget.course),
                      ),
                    );

                    if (!mounted) return;

                    if (updated == true) {
                      Navigator.pop(context, true);
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Course'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (domain.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.category_outlined, size: 18),
                    label: Text(domain),
                  ),

                if (level.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.signal_cellular_alt, size: 18),
                    label: Text(level),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              description.isEmpty
                  ? 'No course description available.'
                  : description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lessonsHeader(),

        const SizedBox(height: 16),

        if (loadingLessons)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          )
        else if (lessonsError != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Could not load lessons.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lessonsError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: loadLessons,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (lessons.isEmpty)
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 50,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No lessons yet.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: addLesson,
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Lesson'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: [for (final lesson in lessons) _buildLessonCard(lesson)],
          ),
      ],
    );
  }

  Widget _lessonsHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Lessons',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),

        ElevatedButton.icon(
          onPressed: addLesson,
          icon: const Icon(Icons.add),
          label: const Text('Add Lesson'),
        ),
      ],
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    final title = lesson['title']?.toString() ?? 'Untitled Lesson';
    final description = lesson['description']?.toString() ?? '';
    final orderIndex = lesson['order_index']?.toString() ?? '0';
    final duration = lesson['duration'];

    final youtubeUrl = lesson['youtube_url']?.toString() ?? '';
    final videoUrl = lesson['video_url']?.toString() ?? '';

    final isFree = lesson['is_free'] == true;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LessonDetailsScreen(lesson: lesson),
            ),
          );

          if (!mounted) return;

          if (updated == true) {
            await loadLessons();
          }
        },
        leading: CircleAvatar(child: Text(orderIndex)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description.isNotEmpty)
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (duration != null)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.timer_outlined, size: 16),
                      label: Text('$duration min'),
                    ),

                  if (youtubeUrl.isNotEmpty)
                    const Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(Icons.play_circle_outline, size: 16),
                      label: Text('YouTube'),
                    ),

                  if (videoUrl.isNotEmpty)
                    const Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(Icons.video_library_outlined, size: 16),
                      label: Text('Video'),
                    ),

                  if (isFree)
                    const Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(Icons.lock_open_outlined, size: 16),
                      label: Text('Free'),
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildCourseFiles() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Course Files',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Manage PDFs, documents, slides and other course files.',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseFilesScreen(course: widget.course),
                  ),
                );
              },
              icon: const Icon(Icons.folder_outlined),
              label: const Text('Manage Files'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LESSON DETAILS
// ============================================================

class LessonDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> lesson;

  const LessonDetailsScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final title = lesson['title']?.toString() ?? 'Untitled Lesson';
    final description = lesson['description']?.toString() ?? '';
    final orderIndex = lesson['order_index']?.toString() ?? '0';

    final youtubeUrl = lesson['youtube_url']?.toString() ?? '';
    final videoUrl = lesson['video_url']?.toString() ?? '';

    final duration = lesson['duration'];
    final isFree = lesson['is_free'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesson $orderIndex',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
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

                    const SizedBox(height: 20),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (duration != null)
                          Chip(
                            avatar: const Icon(Icons.timer_outlined),
                            label: Text('$duration minutes'),
                          ),

                        if (isFree)
                          const Chip(
                            avatar: Icon(Icons.lock_open_outlined),
                            label: Text('Free Lesson'),
                          )
                        else
                          const Chip(
                            avatar: Icon(Icons.lock_outline),
                            label: Text('Paid Lesson'),
                          ),

                        if (youtubeUrl.isNotEmpty)
                          const Chip(
                            avatar: Icon(Icons.play_circle_outline),
                            label: Text('YouTube'),
                          ),

                        if (videoUrl.isNotEmpty)
                          const Chip(
                            avatar: Icon(Icons.video_library_outlined),
                            label: Text('Video'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
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
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    if (youtubeUrl.isNotEmpty) ...[
                      const SizedBox(height: 28),

                      const Text(
                        'YouTube URL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      SelectableText(
                        youtubeUrl,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],

                    if (videoUrl.isNotEmpty) ...[
                      const SizedBox(height: 24),

                      const Text(
                        'Video URL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      SelectableText(
                        videoUrl,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],

                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditLessonScreen(lesson: lesson),
                          ),
                        );

                        if (!context.mounted) return;

                        if (updated == true) {
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

// ============================================================
// EDIT LESSON
// ============================================================

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
  late final TextEditingController youtubeController;
  late final TextEditingController videoController;
  late final TextEditingController durationController;

  bool isFree = false;
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

    youtubeController = TextEditingController(
      text: widget.lesson['youtube_url']?.toString() ?? '',
    );

    videoController = TextEditingController(
      text: widget.lesson['video_url']?.toString() ?? '',
    );

    durationController = TextEditingController(
      text: widget.lesson['duration']?.toString() ?? '',
    );

    isFree = widget.lesson['is_free'] == true;
  }

  Future<void> saveLesson() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    final orderIndex = int.tryParse(orderController.text.trim());

    final youtubeUrl = youtubeController.text.trim();
    final videoUrl = videoController.text.trim();

    final durationText = durationController.text.trim();

    final duration = durationText.isEmpty ? null : int.tryParse(durationText);

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

    if (durationText.isNotEmpty && (duration == null || duration < 0)) {
      setState(() {
        error = 'Please enter a valid duration.';
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
            'youtube_url': youtubeUrl.isEmpty ? null : youtubeUrl,
            'video_url': videoUrl.isEmpty ? null : videoUrl,
            'duration': duration,
            'is_free': isFree,
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
    youtubeController.dispose();
    videoController.dispose();
    durationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Lesson')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Edit Lesson',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: titleController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Lesson Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: descriptionController,
                      enabled: !saving,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: orderController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Order',
                        hintText: 'Example: 1',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: youtubeController,
                      enabled: !saving,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'YouTube URL',
                        hintText: 'https://www.youtube.com/watch?v=...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.play_circle_outline),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: videoController,
                      enabled: !saving,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Video URL',
                        hintText: 'https://...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.video_library_outlined),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: durationController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                        hintText: 'Example: 15',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Free Lesson',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Students can access this lesson for free.',
                      ),
                      value: isFree,
                      onChanged: saving
                          ? null
                          : (value) {
                              setState(() {
                                isFree = value;
                              });
                            },
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: saving
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
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

// ============================================================
// ADD LESSON
// ============================================================

class AddLessonScreen extends StatefulWidget {
  final String courseId;

  const AddLessonScreen({super.key, required this.courseId});

  @override
  State<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends State<AddLessonScreen> {
  final supabase = Supabase.instance.client;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final orderController = TextEditingController();

  final youtubeController = TextEditingController();
  final videoController = TextEditingController();
  final durationController = TextEditingController();

  bool isFree = false;
  bool saving = false;
  String? error;

  Future<void> createLesson() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    final orderIndex = int.tryParse(orderController.text.trim());

    final youtubeUrl = youtubeController.text.trim();
    final videoUrl = videoController.text.trim();

    final durationText = durationController.text.trim();

    final duration = durationText.isEmpty ? null : int.tryParse(durationText);

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

    if (durationText.isNotEmpty && (duration == null || duration < 0)) {
      setState(() {
        error = 'Please enter a valid duration.';
      });
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      await supabase.from('lessons').insert({
        'course_id': widget.courseId,
        'title': title,
        'description': description.isEmpty ? null : description,
        'order_index': orderIndex,
        'youtube_url': youtubeUrl.isEmpty ? null : youtubeUrl,
        'video_url': videoUrl.isEmpty ? null : videoUrl,
        'duration': duration,
        'is_free': isFree,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson created successfully.')),
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
    youtubeController.dispose();
    videoController.dispose();
    durationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Lesson')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add New Lesson',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: titleController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Lesson Title',
                        hintText: 'Example: Introduction to HTML',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: descriptionController,
                      enabled: !saving,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe what students will learn...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: orderController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Order',
                        hintText: 'Example: 1',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: youtubeController,
                      enabled: !saving,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'YouTube URL',
                        hintText: 'https://www.youtube.com/watch?v=...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.play_circle_outline),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: videoController,
                      enabled: !saving,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Video URL',
                        hintText: 'https://example.com/video.mp4',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.video_library_outlined),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: durationController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                        hintText: 'Example: 15',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Free Lesson',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Students can access this lesson for free.',
                      ),
                      value: isFree,
                      onChanged: saving
                          ? null
                          : (value) {
                              setState(() {
                                isFree = value;
                              });
                            },
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: saving
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
                          child: const Text('Cancel'),
                        ),

                        const SizedBox(width: 12),

                        ElevatedButton.icon(
                          onPressed: saving ? null : createLesson,
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(saving ? 'Creating...' : 'Create Lesson'),
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
