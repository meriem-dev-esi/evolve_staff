import 'package:evolve_staff/services/admin_financial_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminFinancialEntry.fromMap', () {
    test('parses a refund ledger entry', () {
      final entry = AdminFinancialEntry.fromMap({
        'id': 'entry-1',
        'entry_type': 'refund',
        'amount_minor_units': 1250,
        'category': 'Course refund',
        'note': 'Partial refund approved',
        'occurred_at': '2026-10-01T12:00:00.000Z',
        'enrollment_id': 'enrollment-1',
      });

      expect(entry.type, 'refund');
      expect(entry.amountMinorUnits, 1250);
      expect(entry.enrollmentId, 'enrollment-1');
    });

    test('rejects malformed records', () {
      expect(
        () => AdminFinancialEntry.fromMap({'entry_type': 'write-off'}),
        throwsFormatException,
      );
    });
  });

  group('AdminPaidEnrollment.fromMap', () {
    test('converts DZD amounts to minor units', () {
      final enrollment = AdminPaidEnrollment.fromMap({
        'id': 'enrollment-1',
        'course_title': 'Flutter',
        'payment_amount': 2500.75,
      });

      expect(enrollment.amountMinorUnits, 250075);
      expect(enrollment.label, 'Flutter · 2500.75 DZD');
    });

    test('rejects missing paid amounts', () {
      expect(
        () => AdminPaidEnrollment.fromMap({
          'id': 'enrollment-1',
          'course_title': 'Flutter',
          'payment_amount': 0,
        }),
        throwsFormatException,
      );
    });
  });
}
