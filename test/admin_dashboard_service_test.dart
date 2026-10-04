import 'package:evolve_staff/services/admin_dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminDashboardOverview.fromMap', () {
    test('parses metrics and recent platform records', () {
      final overview = AdminDashboardOverview.fromMap({
        'total_users': 12,
        'new_users_7_days': 3,
        'students': 8,
        'teachers': 2,
        'administrators': 2,
        'courses': 6,
        'published_courses': 5,
        'draft_courses': 1,
        'lessons': 30,
        'formations': 4,
        'pending_payments': 1,
        'paid_enrollments': 9,
        'recent_users': [
          {'id': 'user-1', 'full_name': 'Test User', 'role': 'student'},
        ],
        'recent_courses': [
          {'id': 'course-1', 'title': 'Test Course'},
        ],
      });

      expect(overview.totalUsers, 12);
      expect(overview.newUsersLastSevenDays, 3);
      expect(overview.teachers, 2);
      expect(overview.publishedCourses, 5);
      expect(overview.draftCourses, 1);
      expect(overview.pendingPayments, 1);
      expect(overview.recentUsers.single['full_name'], 'Test User');
      expect(overview.recentCourses.single['title'], 'Test Course');
    });

    test(
      'rejects missing or negative metrics instead of showing false zeros',
      () {
        expect(() => AdminDashboardOverview.fromMap({}), throwsFormatException);
        expect(
          () => AdminDashboardOverview.fromMap({
            ..._validOverview,
            'students': -1,
          }),
          throwsFormatException,
        );
      },
    );

    test('rejects invalid recent activity payloads', () {
      expect(
        () => AdminDashboardOverview.fromMap({
          ..._validOverview,
          'recent_users': [null],
        }),
        throwsFormatException,
      );
    });
  });
}

const Map<String, dynamic> _validOverview = {
  'total_users': 1,
  'new_users_7_days': 0,
  'students': 1,
  'teachers': 0,
  'administrators': 0,
  'courses': 0,
  'published_courses': 0,
  'draft_courses': 0,
  'lessons': 0,
  'formations': 0,
  'pending_payments': 0,
  'paid_enrollments': 0,
  'recent_users': <Map<String, dynamic>>[],
  'recent_courses': <Map<String, dynamic>>[],
};
