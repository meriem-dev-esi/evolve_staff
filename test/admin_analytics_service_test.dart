import 'package:evolve_staff/services/admin_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminAnalytics.fromMap', () {
    test('parses operational metrics, trends, and course demand', () {
      final analytics = AdminAnalytics.fromMap(_validAnalytics);

      expect(analytics.users, 30);
      expect(analytics.enrollmentStatuses['paid'], 12);
      expect(analytics.enrollmentsThisMonth, 8);
      expect(analytics.monthlyActivity.single.signups, 4);
      expect(analytics.topCourses.single.formattedRevenue, '50.00 DZD');
      expect(analytics.monthlyFinancialReport.month, '2026-10');
      expect(analytics.monthlyFinancialReport.paidRevenueMinorUnits, 5000);
      expect(analytics.monthlyFinancialReport.netMinorUnits, 3500);
      expect(
        analytics.monthlyFinancialReport.historicalPaidWithoutTimestamp,
        2,
      );
      expect(
        analytics.monthlyFinancialReport.courseRevenues.single.title,
        'Flutter',
      );
      expect(analytics.ungradedSubmissions, 3);
    });

    test('rejects incomplete analytics instead of showing false zeros', () {
      expect(() => AdminAnalytics.fromMap({}), throwsFormatException);
    });

    test('rejects malformed course performance rows', () {
      expect(
        () => AdminAnalytics.fromMap({
          ..._validAnalytics,
          'top_courses': [
            {'course_id': 'course-1'},
          ],
        }),
        throwsFormatException,
      );
    });

    test('rejects an incomplete monthly financial report', () {
      expect(
        () => AdminAnalytics.fromMap({
          ..._validAnalytics,
          'monthly_financial_report': {'month': '2026-10'},
        }),
        throwsFormatException,
      );
    });
  });
}

const Map<String, dynamic> _validAnalytics = {
  'users': 30,
  'students': 27,
  'teachers': 2,
  'new_users_this_month': 4,
  'courses': 8,
  'published_courses': 7,
  'draft_courses': 1,
  'lessons': 32,
  'formations': 3,
  'assignments': 10,
  'published_assignments': 8,
  'submissions': 6,
  'ungraded_submissions': 3,
  'enrollment_statuses': {'paid': 12, 'pending': 2},
  'enrollments_this_month': 8,
  'enrollments_previous_month': 5,
  'paid_revenue_this_month_minor_units': 5000,
  'paid_revenue_previous_month_minor_units': 2500,
  'monthly_financial_report': {
    'month': '2026-10',
    'previous_month': '2026-09',
    'enrollments': 8,
    'paid_enrollments': 5,
    'pending_enrollments': 2,
    'previous_pending_enrollments': 1,
    'enrollments_without_amount': 1,
    'paid_revenue_minor_units': 5000,
    'refunds_minor_units': 500,
    'expenses_minor_units': 1000,
    'net_minor_units': 3500,
    'historical_paid_without_timestamp': 2,
    'previous_enrollments': 5,
    'previous_refunds_minor_units': 0,
    'previous_expenses_minor_units': 1000,
    'previous_net_minor_units': 1500,
    'previous_paid_enrollments': 3,
    'previous_paid_revenue_minor_units': 2500,
    'course_revenues': [
      {
        'course_id': 'course-1',
        'course_title': 'Flutter',
        'enrollments': 8,
        'paid_enrollments': 5,
        'revenue_minor_units': 5000,
      },
    ],
  },
  'monthly_activity': [
    {'month': '2026-10', 'signups': 4, 'enrollments': 8},
  ],
  'top_courses': [
    {
      'course_id': 'course-1',
      'course_title': 'Flutter',
      'enrollments': 12,
      'paid_enrollments': 10,
      'revenue_minor_units': 5000,
    },
  ],
};
