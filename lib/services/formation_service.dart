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
    List<dynamic> rows = [];

    try {
      rows = await _supabase
          .from('course_series')
          .select('*')
          .order('created_at', ascending: false);
    } catch (_) {
      try {
        rows = await _supabase
            .from('formations')
            .select('*')
            .order('created_at', ascending: false);
      } catch (_) {
        rows = [];
      }
    }

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

    try {
      await _supabase.from('course_series').insert(payload);
    } catch (_) {
      await _supabase.from('formations').insert(payload);
    }
  }

  /// Fetches courses linked to a formation.
  static Future<List<Map<String, dynamic>>> fetchCoursesInFormation(
    String formationId,
  ) async {
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
          courses.add(Map<String, dynamic>.from(c));
        }
      }
      return courses;
    } catch (_) {
      return [];
    }
  }
}
