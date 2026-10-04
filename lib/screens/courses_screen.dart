import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'course_details_screen.dart';
import 'create_course_screen.dart';
import 'edit_course_screen.dart';
import '../services/admin_course_moderation_service.dart';
import '../services/admin_courses_service.dart';

class CoursesScreen extends StatefulWidget {
  final String initialStatusFilter;

  const CoursesScreen({super.key, this.initialStatusFilter = 'all'});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> allCourses = [];
  List<Map<String, dynamic>> displayedCourses = [];

  String searchQuery = '';
  String selectedFilterDomain = 'All';
  late String selectedStatusFilter;
  bool isAdmin = false;
  final Set<String> moderatingCourseIds = {};

  @override
  void initState() {
    super.initState();
    selectedStatusFilter = widget.initialStatusFilter;
    loadCourses();
  }

  Future<void> loadCourses() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User is not logged in.');
      }

      // Check current user role
      String userRole = 'teacher';
      try {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null && profile['role'] != null) {
          userRole = profile['role'].toString();
        }
      } catch (_) {}
      isAdmin = userRole == 'admin';

      List<Map<String, dynamic>> loadedCourses = [];

      // If admin, load all courses directly
      if (userRole == 'admin') {
        loadedCourses = await AdminCoursesService.fetch();
      } else {
        // Teacher: first try teacher_courses junction
        try {
          final response = await supabase
              .from('teacher_courses')
              .select('''
                course_id,
                courses (
                  id,
                  title,
                  description,
                  image_url,
                  level,
                  domain,
                  duration,
                  price,
                  is_published
                )
              ''')
              .eq('teacher_id', user.id);

          for (final item in response) {
            final c = item['courses'];
            if (c != null) {
              loadedCourses.add(Map<String, dynamic>.from(c));
            }
          }
        } catch (_) {}

        // If no courses found in teacher_courses, fallback to all courses
        if (loadedCourses.isEmpty) {
          final res = await supabase
              .from('courses')
              .select('*')
              .order('created_at', ascending: false);
          loadedCourses = List<Map<String, dynamic>>.from(res);
        }
      }

      if (!mounted) return;

      setState(() {
        allCourses = loadedCourses;
        _applyFilters();
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  void _applyFilters() {
    displayedCourses = allCourses.where((c) {
      final title = (c['title']?.toString() ?? '').toLowerCase();
      final desc = (c['description']?.toString() ?? '').toLowerCase();
      final domain = (c['domain']?.toString() ?? '');

      final matchesSearch =
          searchQuery.isEmpty ||
          title.contains(searchQuery.toLowerCase()) ||
          desc.contains(searchQuery.toLowerCase());

      final matchesDomain =
          selectedFilterDomain == 'All' || domain == selectedFilterDomain;
      final isPublished = c['is_published'] == true;
      final matchesStatus = switch (selectedStatusFilter) {
        'draft' => !isPublished,
        'published' => isPublished,
        _ => true,
      };

      return matchesSearch && matchesDomain && matchesStatus;
    }).toList();
  }

  Future<void> refreshCourses() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    await loadCourses();
  }

  Future<void> _openCreateCourse() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateCourseScreen()),
    );
    if (created == true && mounted) {
      await refreshCourses();
    }
  }

  Future<void> _deleteCourse(Map<String, dynamic> course) async {
    final courseId = course['id'].toString();
    final courseTitle = course['title']?.toString() ?? 'Course';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "$courseTitle"? All associated lessons will be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('courses').delete().eq('id', courseId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Course "$courseTitle" deleted.')));
      await refreshCourses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete course: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _moderateCourse(Map<String, dynamic> course) async {
    final courseId = course['id']?.toString() ?? '';
    if (courseId.isEmpty || moderatingCourseIds.contains(courseId)) return;
    final wasPublished = course['is_published'] == true;
    final shouldPublish = !wasPublished;
    final courseTitle = course['title']?.toString() ?? 'Course';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(shouldPublish ? 'Publish course?' : 'Unpublish course?'),
        content: Text(
          shouldPublish
              ? '"$courseTitle" will become visible to students.'
              : '"$courseTitle" will no longer be visible to students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(shouldPublish ? 'Publish' : 'Unpublish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => moderatingCourseIds.add(courseId));
    try {
      await AdminCourseModerationService.setPublished(
        courseId: courseId,
        published: shouldPublish,
      );
      if (!mounted) return;
      setState(() {
        allCourses = allCourses.map((item) {
          if (item['id']?.toString() == courseId) {
            return {...item, 'is_published': shouldPublish};
          }
          return item;
        }).toList();
        _applyFilters();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shouldPublish
                ? '"$courseTitle" published.'
                : '"$courseTitle" unpublished.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update course status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => moderatingCourseIds.remove(courseId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Courses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : refreshCourses,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _openCreateCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84CC16),
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Create Course',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(24), child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load courses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 500,
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: refreshCourses,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final domains = [
      'All',
      ...allCourses.map((c) => c['domain']?.toString() ?? 'General').toSet(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search and Filters Bar
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search courses by title or description...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFFFD8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${displayedCourses.length} of ${allCourses.length} courses',
                style: const TextStyle(
                  color: Color(0xFF65A30D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: DropdownButton<String>(
              value: selectedStatusFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All statuses')),
                DropdownMenuItem(value: 'draft', child: Text('Needs review')),
                DropdownMenuItem(value: 'published', child: Text('Published')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedStatusFilter = value;
                  _applyFilters();
                });
              },
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Domain filter tags
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: domains.map((d) {
              final isSelected = selectedFilterDomain == d;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(d),
                  selected: isSelected,
                  selectedColor: const Color(0xFF84CC16),
                  checkmarkColor: Colors.black,
                  backgroundColor: Colors.white,
                  onSelected: (selected) {
                    setState(() {
                      selectedFilterDomain = d;
                      _applyFilters();
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Course list/grid
        if (displayedCourses.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No courses found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    allCourses.isEmpty
                        ? 'Get started by creating your first course.'
                        : 'Try changing your search query or filters.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _openCreateCourse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84CC16),
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Course'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                mainAxisExtent: 340,
              ),
              itemCount: displayedCourses.length,
              itemBuilder: (context, index) {
                final course = displayedCourses[index];
                return _courseCard(context, course);
              },
            ),
          ),
      ],
    );
  }

  Widget _courseCard(BuildContext context, Map<String, dynamic> course) {
    final imageUrl = course['image_url']?.toString() ?? '';
    final title = course['title']?.toString() ?? 'Untitled Course';
    final domain = course['domain']?.toString() ?? 'General';
    final level = course['level']?.toString() ?? 'All levels';
    final description = course['description']?.toString() ?? '';
    final isPublished = course['is_published'] == true;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailsScreen(course: course),
            ),
          );
          if (updated == true && mounted) {
            await refreshCourses();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badge overlay
            Stack(
              children: [
                _courseImage(imageUrl),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPublished
                          ? const Color(0xFF84CC16)
                          : Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPublished ? 'Published' : 'Draft',
                      style: TextStyle(
                        color: isPublished ? Colors.black : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Flexible(
                          child: _tag(
                            domain,
                            const Color(0xFFEFFFD8),
                            const Color(0xFF65A30D),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _tag(
                            level,
                            Colors.grey.shade100,
                            Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Action buttons footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isAdmin)
                          TextButton.icon(
                            onPressed:
                                moderatingCourseIds.contains(
                                  course['id']?.toString(),
                                )
                                ? null
                                : () => _moderateCourse(course),
                            icon:
                                moderatingCourseIds.contains(
                                  course['id']?.toString(),
                                )
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    isPublished
                                        ? Icons.visibility_off_outlined
                                        : Icons.publish_outlined,
                                    size: 18,
                                  ),
                            label: Text(isPublished ? 'Unpublish' : 'Publish'),
                          ),
                        IconButton(
                          tooltip: 'Edit Course',
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditCourseScreen(course: course),
                              ),
                            );
                            if (updated == true && mounted) {
                              await refreshCourses();
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Delete Course',
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteCourse(course),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: Icon(
          Icons.school_outlined,
          size: 50,
          color: Colors.grey.shade500,
        ),
      );
    }

    return SizedBox(
      height: 140,
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: Icon(
            Icons.school_outlined,
            size: 50,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
