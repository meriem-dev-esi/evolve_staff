import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _supabase = Supabase.instance.client;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController = TextEditingController();
  final priceController = TextEditingController(text: '0');
  final imageUrlController = TextEditingController();

  String selectedDomain = 'Web Development';
  String selectedLevel = 'All levels';
  String selectedType = 'Course';
  double practicePercentage = 50;

  bool isPublished = false;
  bool isBeginner = true;
  bool isPartner = false;
  bool isExclusive = false;
  bool isTrending = false;

  bool saving = false;
  String? error;

  final List<String> domains = [
    'Web Development',
    'Mobile Development',
    'UI/UX Design',
    'Data Science & AI',
    'Cybersecurity',
    'Cloud & DevOps',
    'Business & Tech',
  ];

  final List<String> levels = [
    'All levels',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  final List<String> types = ['Course', 'Workshop', 'Bootcamp', 'Masterclass'];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    priceController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _createCourse() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final duration = durationController.text.trim();
    final imageUrl = imageUrlController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0;

    if (title.isEmpty) {
      setState(() {
        error = 'Please enter a course title.';
      });
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User is not logged in.');
      }

      final insertData = {
        'title': title,
        'description': description.isEmpty ? null : description,
        'domain': selectedDomain,
        'level': selectedLevel,
        'type': selectedType,
        'duration': duration.isEmpty ? null : duration,
        'price': price,
        'image_url': imageUrl.isEmpty ? null : imageUrl,
        'practice_percentage': practicePercentage.round(),
        'is_published': isPublished,
        'is_beginner': isBeginner,
        'is_partner': isPartner,
        'is_exclusive': isExclusive,
        'is_trending': isTrending,
        'is_coming_soon': false,
      };

      final response = await _supabase
          .from('courses')
          .insert(insertData)
          .select('id')
          .single();

      final newCourseId = response['id'].toString();

      try {
        await _supabase.from('teacher_courses').insert({
          'teacher_id': user.id,
          'course_id': newCourseId,
        });
      } catch (assignmentError) {
        try {
          final deletedCourses = await _supabase
              .from('courses')
              .delete()
              .eq('id', newCourseId)
              .select('id');
          if (deletedCourses.isEmpty) {
            throw Exception('The new course could not be removed.');
          }
        } catch (cleanupError) {
          throw Exception(
            'Teacher assignment failed, and the new course could not be rolled back. '
            'Assignment error: $assignmentError. Cleanup error: $cleanupError',
          );
        }
        throw Exception(
          'Course creation was rolled back because your teacher assignment could not be saved: '
          '$assignmentError',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course created successfully!'),
          backgroundColor: Color(0xFF65A30D),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Create New Course',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Course Information',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Define title, domain, level and curriculum parameters.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextField(
                      controller: titleController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Course Title *',
                        hintText: 'e.g. Full-Stack Web Development Bootcamp',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Description
                    TextField(
                      controller: descriptionController,
                      enabled: !saving,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText:
                            'Describe what students will learn in this course...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Domain & Level Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedDomain,
                            decoration: const InputDecoration(
                              labelText: 'Domain / Category',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: domains
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                            onChanged: saving
                                ? null
                                : (v) => setState(() => selectedDomain = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedLevel,
                            decoration: const InputDecoration(
                              labelText: 'Difficulty Level',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.bar_chart_outlined),
                            ),
                            items: levels
                                .map(
                                  (l) => DropdownMenuItem(
                                    value: l,
                                    child: Text(l),
                                  ),
                                )
                                .toList(),
                            onChanged: saving
                                ? null
                                : (v) => setState(() => selectedLevel = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Duration & Price Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: durationController,
                            enabled: !saving,
                            decoration: const InputDecoration(
                              labelText: 'Duration',
                              hintText: 'e.g. 10 hours or 4 weeks',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timer_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            enabled: !saving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Price (DZD or USD)',
                              hintText: '0 for free',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.monetization_on_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Image URL
                    TextField(
                      controller: imageUrlController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Cover Image URL',
                        hintText: 'https://images.unsplash.com/...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (imageUrlController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrlController.text.trim(),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 100,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Text(
                              'Could not load image preview',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Practice % Slider
                    Text(
                      'Practice vs Theory: ${practicePercentage.round()}% Hands-On Practice',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: practicePercentage,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: const Color(0xFF84CC16),
                      label: '${practicePercentage.round()}%',
                      onChanged: saving
                          ? null
                          : (v) => setState(() => practicePercentage = v),
                    ),
                    const SizedBox(height: 16),

                    // Switches
                    SwitchListTile(
                      title: const Text(
                        'Publish Immediately',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Make this course visible to students immediately upon creation.',
                      ),
                      value: isPublished,
                      activeColor: const Color(0xFF84CC16),
                      onChanged: saving
                          ? null
                          : (v) => setState(() => isPublished = v),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Trending / Featured',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Feature this course in prominent dashboard spotlights.',
                      ),
                      value: isTrending,
                      activeColor: const Color(0xFF84CC16),
                      onChanged: saving
                          ? null
                          : (v) => setState(() => isTrending = v),
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: saving ? null : _createCourse,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF84CC16),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                          ),
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            saving ? 'Creating Course...' : 'Create Course',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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
