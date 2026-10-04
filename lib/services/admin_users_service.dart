import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersService {
  static List<Map<String, dynamic>> parseResponse(Object? response) {
    if (response is! Map || response['users'] is! List) {
      throw const FormatException('Invalid admin users response.');
    }

    return (response['users'] as List).map((row) {
      if (row is! Map) {
        throw const FormatException('Invalid admin user record.');
      }
      final user = Map<String, dynamic>.from(row);
      if (user['id'] is! String || user['role'] is! String) {
        throw const FormatException('Invalid admin user record.');
      }
      return user;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> fetch() async {
    final response = await Supabase.instance.client.functions.invoke(
      'admin-users',
    );
    return parseResponse(response.data);
  }
}
