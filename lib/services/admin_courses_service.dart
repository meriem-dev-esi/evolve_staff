import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCoursesService {
  static List<Map<String, dynamic>> parseResponse(Object? response) {
    if (response is! Map || response['courses'] is! List) {
      throw const FormatException('Invalid admin courses response.');
    }

    return (response['courses'] as List).map((row) {
      if (row is! Map) {
        throw const FormatException('Invalid admin course record.');
      }
      final course = Map<String, dynamic>.from(row);
      if (course['id'] is! String ||
          course['title'] is! String ||
          course['is_published'] is! bool) {
        throw const FormatException('Invalid admin course record.');
      }
      return course;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> fetch() async {
    final response = await Supabase.instance.client.functions.invoke(
      'admin-courses',
    );
    return parseResponse(response.data);
  }
}
