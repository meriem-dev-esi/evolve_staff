import 'package:evolve_staff/services/revenue_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RevenueSummary.fromMap', () {
    test('parses revenue by course, including zero-revenue courses', () {
      final summary = RevenueSummary.fromMap({
        'total_minor_units': 12550,
        'refunds_minor_units': 2500,
        'expenses_minor_units': 1000,
        'net_minor_units': 9050,
        'paid_enrollments': 2,
        'pending_enrollments': 1,
        'enrollments_without_amount': 1,
        'course_revenues': [
          {
            'course_id': 'course-1',
            'course_title': 'Course with revenue',
            'total_minor_units': 12550,
            'refunds_minor_units': 2500,
            'net_minor_units': 10050,
            'paid_enrollments': 2,
            'enrollments_without_amount': 1,
          },
          {
            'course_id': 'course-2',
            'course_title': 'Course without revenue',
            'total_minor_units': 0,
            'refunds_minor_units': 0,
            'net_minor_units': 0,
            'paid_enrollments': 0,
            'enrollments_without_amount': 0,
          },
        ],
      });

      expect(summary.courseRevenues, hasLength(2));
      expect(summary.courseRevenues.first.formattedDzd, '125.50 DZD');
      expect(summary.formattedDzd, '125.50 DZD');
      expect(summary.formattedRefundsDzd, '25.00 DZD');
      expect(summary.formattedExpensesDzd, '10.00 DZD');
      expect(summary.formattedNetDzd, '90.50 DZD');
      expect(summary.courseRevenues.first.formattedNetDzd, '100.50 DZD');
      expect(summary.courseRevenues.last.totalMinorUnits, 0);
      expect(summary.courseRevenues.first.enrollmentsWithoutAmount, 1);
    });

    test('rejects missing course breakdown', () {
      expect(
        () => RevenueSummary.fromMap({
          'total_minor_units': 0,
          'refunds_minor_units': 0,
          'expenses_minor_units': 0,
          'net_minor_units': 0,
          'paid_enrollments': 0,
          'pending_enrollments': 0,
          'enrollments_without_amount': 0,
        }),
        throwsFormatException,
      );
    });

    test('rejects totals that do not reconcile with course breakdown', () {
      expect(
        () => RevenueSummary.fromMap({
          'total_minor_units': 1000,
          'refunds_minor_units': 100,
          'expenses_minor_units': 0,
          'net_minor_units': 900,
          'paid_enrollments': 1,
          'pending_enrollments': 0,
          'enrollments_without_amount': 0,
          'course_revenues': [
            {
              'course_id': 'course-1',
              'course_title': 'Course',
              'total_minor_units': 900,
              'refunds_minor_units': 100,
              'net_minor_units': 800,
              'paid_enrollments': 1,
              'enrollments_without_amount': 0,
            },
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
