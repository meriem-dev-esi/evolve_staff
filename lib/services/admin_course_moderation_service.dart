import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCourseModerationService {
  static Future<void> setPublished({
    required String courseId,
    required bool published,
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      'admin-course-moderation',
      body: {'course_id': courseId, 'is_published': published},
    );
    if (response.data is! Map<String, dynamic> ||
        response.data['course_id'] != courseId ||
        response.data['is_published'] != published) {
      throw const FormatException('Unable to confirm course publication.');
    }
  }
}
