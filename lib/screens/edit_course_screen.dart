import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditCourseScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const EditCourseScreen({super.key, required this.course});

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  final supabase = Supabase.instance.client;

  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController domainController;
  late final TextEditingController levelController;
  late final TextEditingController durationController;
  late final TextEditingController priceController;
  late final TextEditingController imageUrlController;

  bool published = false;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.course['title']?.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.course['description']?.toString() ?? '',
    );

    domainController = TextEditingController(
      text: widget.course['domain']?.toString() ?? '',
    );

    levelController = TextEditingController(
      text: widget.course['level']?.toString() ?? '',
    );

    durationController = TextEditingController(
      text: widget.course['duration']?.toString() ?? '',
    );

    priceController = TextEditingController(
      text: widget.course['price']?.toString() ?? '0',
    );

    imageUrlController = TextEditingController(
      text: widget.course['image_url']?.toString() ?? '',
    );

    published = widget.course['is_published'] == true;
  }

  Future<void> saveCourse() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final domain = domainController.text.trim();
    final level = levelController.text.trim();
    final duration = durationController.text.trim();
    final imageUrl = imageUrlController.text.trim();

    final price = double.tryParse(priceController.text.trim());

    if (title.isEmpty) {
      setState(() {
        error = 'Course title is required.';
      });
      return;
    }

    if (price == null || price < 0) {
      setState(() {
        error = 'Please enter a valid price.';
      });
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      await supabase
          .from('courses')
          .update({
            'title': title,
            'description': description.isEmpty ? null : description,
            'domain': domain.isEmpty ? null : domain,
            'level': level.isEmpty ? null : level,
            'duration': duration.isEmpty ? null : duration,
            'price': price,
            'image_url': imageUrl.isEmpty ? null : imageUrl,
            'is_published': published,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', widget.course['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course updated successfully.')),
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
    domainController.dispose();
    levelController.dispose();
    durationController.dispose();
    priceController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Edit Course',
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
                      'Course Information',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Course Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Description
                    TextField(
                      controller: descriptionController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Domain
                    TextField(
                      controller: domainController,
                      decoration: const InputDecoration(
                        labelText: 'Domain',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Level
                    TextField(
                      controller: levelController,
                      decoration: const InputDecoration(
                        labelText: 'Level',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Duration
                    TextField(
                      controller: durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        hintText: 'Example: 12 hours',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Price
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Price (DA)',
                        hintText: '0 = gratuit',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                        suffixText: 'DA',
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Image URL + preview
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        hintText: 'Lien direct vers une image (.jpg, .png)',
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
                    const SizedBox(height: 18),

                    // Published
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Published',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Make this course visible to students.',
                      ),
                      value: published,
                      onChanged: saving
                          ? null
                          : (value) {
                              setState(() {
                                published = value;
                              });
                            },
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],

                    const SizedBox(height: 28),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: saving
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: saving ? null : saveCourse,
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
