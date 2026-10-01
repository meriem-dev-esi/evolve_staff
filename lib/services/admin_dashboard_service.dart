import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardOverview {
  final int totalUsers;
  final int newUsersLastSevenDays;
  final int students;
  final int teachers;
  final int administrators;
  final int courses;
  final int publishedCourses;
  final int lessons;
  final int formations;
  final int pendingPayments;
  final int paidEnrollments;
  final List<Map<String, dynamic>> recentUsers;
  final List<Map<String, dynamic>> recentCourses;

  const AdminDashboardOverview({
    required this.totalUsers,
    required this.newUsersLastSevenDays,
    required this.students,
    required this.teachers,
    required this.administrators,
    required this.courses,
    required this.publishedCourses,
    required this.lessons,
    required this.formations,
    required this.pendingPayments,
    required this.paidEnrollments,
    required this.recentUsers,
    required this.recentCourses,
  });

  factory AdminDashboardOverview.fromMap(Map<String, dynamic> data) {
    int readCount(String key) {
      final value = data[key];
      if (value is! num || value < 0) {
        throw FormatException('Invalid admin dashboard metric: $key.');
      }
      return value.toInt();
    }

    List<Map<String, dynamic>> readRows(String key) {
      final value = data[key];
      if (value is! List) {
        throw FormatException('Invalid admin dashboard data: $key.');
      }
      return value.map((row) {
        if (row is! Map) {
          throw FormatException('Invalid admin dashboard data: $key.');
        }
        return Map<String, dynamic>.from(row);
      }).toList();
    }

    return AdminDashboardOverview(
      totalUsers: readCount('total_users'),
      newUsersLastSevenDays: readCount('new_users_7_days'),
      students: readCount('students'),
      teachers: readCount('teachers'),
      administrators: readCount('administrators'),
      courses: readCount('courses'),
      publishedCourses: readCount('published_courses'),
      lessons: readCount('lessons'),
      formations: readCount('formations'),
      pendingPayments: readCount('pending_payments'),
      paidEnrollments: readCount('paid_enrollments'),
      recentUsers: readRows('recent_users'),
      recentCourses: readRows('recent_courses'),
    );
  }

  static Future<AdminDashboardOverview> fetch() async {
    final response = await Supabase.instance.client.functions.invoke(
      'admin-dashboard',
    );
    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('Invalid admin dashboard response.');
    }
    return AdminDashboardOverview.fromMap(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
