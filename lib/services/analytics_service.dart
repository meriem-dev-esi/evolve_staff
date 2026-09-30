import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  /// Fetches analytics statistics based on the current user's role.
  /// Returns a map with keys: courses, students, formations, lessons.
  static Future<Map<String, int>> fetchStats(String role) async {
    final client = Supabase.instance.client;

    int courses = 0;
    try {
      final res = await client
          .from('courses')
          .select()
          .count(CountOption.exact);
      courses = res.count;
    } catch (_) {
      try {
        final res = await client
            .from('teacher_courses')
            .select()
            .count(CountOption.exact);
        courses = res.count;
      } catch (_) {}
    }

    int students = 0;
    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('role', 'student')
          .count(CountOption.exact);
      students = res.count;
    } catch (_) {}

    int formations = 0;
    try {
      final res = await client
          .from('course_series')
          .select()
          .count(CountOption.exact);
      formations = res.count;
    } catch (_) {
      try {
        final res = await client
            .from('formations')
            .select()
            .count(CountOption.exact);
        formations = res.count;
      } catch (_) {}
    }

    int lessons = 0;
    try {
      final res = await client
          .from('lessons')
          .select()
          .count(CountOption.exact);
      lessons = res.count;
    } catch (_) {}

    return {
      'courses': courses,
      'students': students,
      'formations': formations,
      'lessons': lessons,
    };
  }
}
