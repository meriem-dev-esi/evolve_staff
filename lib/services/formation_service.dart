import 'package:supabase_flutter/supabase_flutter.dart';

class FormationItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String level;
  final String domain;
  final bool isPublished;
  final int coursesCount;

  FormationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.level,
    required this.domain,
    required this.isPublished,
    required this.coursesCount,
  });

  factory FormationItem.fromMap(
    Map<String, dynamic> map, {
    int coursesCount = 0,
  }) {
    return FormationItem(
      id: map['id'].toString(),
      title: map['title']?.toString() ?? 'Untitled Formation',
      description: map['description']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      level: map['level']?.toString() ?? 'All levels',
      domain: map['domain']?.toString() ?? 'General',
      isPublished: map['is_published'] == true,
      coursesCount: coursesCount,
    );
  }
}

class FormationService {
  static final _supabase = Supabase.instance.client;

  /// Fetches all formations / series and their course counts.
  static Future<List<FormationItem>> fetchFormations() async {
    final List<dynamic> rows = await _supabase
        .from('course_series')
        .select('*')
        .order('created_at', ascending: false);

    if (rows.isEmpty) return [];

    final seriesIds = rows.map((r) => r['id'].toString()).toList();
    final Map<String, int> counts = {};

    try {
      final junctionRows = await _supabase
          .from('series_courses')
          .select('series_id')
          .inFilter('series_id', seriesIds);

      for (var j in junctionRows) {
        final sId = j['series_id']?.toString() ?? '';
        counts[sId] = (counts[sId] ?? 0) + 1;
      }
    } catch (_) {}

    return rows.map<FormationItem>((r) {
      final sId = r['id'].toString();
      return FormationItem.fromMap(r, coursesCount: counts[sId] ?? 0);
    }).toList();
  }

  /// Creates a new formation.
  static Future<void> createFormation({
    required String title,
    required String description,
    required String domain,
    required String level,
    required String imageUrl,
    required bool isPublished,
  }) async {
    final payload = {
      'title': title,
      'description': description.isEmpty ? null : description,
      'domain': domain.isEmpty ? null : domain,
      'level': level.isEmpty ? null : level,
      'image_url': imageUrl.isEmpty ? null : imageUrl,
      'is_published': isPublished,
    };

    await _supabase.from('course_series').insert(payload);
  }

  /// Updates an existing formation.
  static Future<void> updateFormation({
    required String id,
    required String title,
    required String description,
    required String domain,
    required String level,
    required String imageUrl,
    required bool isPublished,
  }) async {
    final payload = {
      'title': title,
      'description': description.isEmpty ? null : description,
      'domain': domain.isEmpty ? null : domain,
      'level': level.isEmpty ? null : level,
      'image_url': imageUrl.isEmpty ? null : imageUrl,
      'is_published': isPublished,
    };

    await _supabase.from('course_series').update(payload).eq('id', id);
  }

  /// Deletes a formation and unlinks its courses.
  static Future<void> deleteFormation(String id) async {
    // 1. Delete associated course junction links first to avoid foreign key errors
    try {
      await _supabase.from('series_courses').delete().eq('series_id', id);
    } catch (_) {}

    // 2. Delete the formation from course_series
    await _supabase.from('course_series').delete().eq('id', id);
  }

  /// Fetches courses linked to a formation, ordered by order_index.
  static Future<List<Map<String, dynamic>>> fetchCoursesInFormation(String formationId) async {
    try {
      final junction = await _supabase
          .from('series_courses')
          .select('course_id, order_index, courses(*)')
          .eq('series_id', formationId)
          .order('order_index', ascending: true);

      final List<Map<String, dynamic>> courses = [];
      for (var item in junction) {
        final c = item['courses'];
        if (c != null) {
          final courseMap = Map<String, dynamic>.from(c);
          courseMap['order_index'] = item['order_index'] ?? 0;
          courses.add(courseMap);
        }
      }
      return courses;
    } catch (_) {
      return [];
    }
  }

  /// Fetches all available courses on the platform.
  static Future<List<Map<String, dynamic>>> fetchAllAvailableCourses() async {
    try {
      final res = await _supabase
          .from('courses')
          .select('id, title, description, domain, level, image_url, is_published')
          .order('title', ascending: true);

      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  /// Links a course to a formation with a given order index.
  static Future<void> addCourseToFormation({
    required String formationId,
    required String courseId,
    required int orderIndex,
  }) async {
    await _supabase.from('series_courses').insert({
      'series_id': formationId,
      'course_id': courseId,
      'order_index': orderIndex,
    });
  }

  /// Removes a course link from a formation.
  static Future<void> removeCourseFromFormation({
    required String formationId,
    required String courseId,
  }) async {
    await _supabase
        .from('series_courses')
        .delete()
        .eq('series_id', formationId)
        .eq('course_id', courseId);
  }

  /// Updates the ordering index of courses within a formation.
  static Future<void> reorderCoursesInFormation({
    required String formationId,
    required List<String> orderedCourseIds,
  }) async {
    for (int i = 0; i < orderedCourseIds.length; i++) {
      final courseId = orderedCourseIds[i];
      final newIndex = i + 1;

      try {
        await _supabase
            .from('series_courses')
            .update({'order_index': newIndex})
            .eq('series_id', formationId)
            .eq('course_id', courseId);
      } catch (_) {}
    }
  }
}
