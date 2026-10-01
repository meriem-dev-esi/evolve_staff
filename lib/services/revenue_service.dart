import 'package:supabase_flutter/supabase_flutter.dart';

class RevenueSummary {
  final int totalMinorUnits;
  final int paidEnrollments;
  final int enrollmentsWithoutAmount;

  const RevenueSummary({
    required this.totalMinorUnits,
    required this.paidEnrollments,
    required this.enrollmentsWithoutAmount,
  });

  String get formattedDzd {
    final wholeUnits = totalMinorUnits ~/ 100;
    final fractionalUnits = (totalMinorUnits % 100).abs();
    return '$wholeUnits.${fractionalUnits.toString().padLeft(2, '0')} DZD';
  }
}

class RevenueService {
  static Future<RevenueSummary> fetchSummary() async {
    final client = Supabase.instance.client;
    final response = await client.functions.invoke('admin-revenue');
    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('Invalid revenue response.');
    }

    final data = response.data as Map<String, dynamic>;
    final totalMinorUnits = data['total_minor_units'];
    final paidEnrollments = data['paid_enrollments'];
    final enrollmentsWithoutAmount = data['enrollments_without_amount'];
    if (totalMinorUnits is! num ||
        paidEnrollments is! num ||
        enrollmentsWithoutAmount is! num) {
      throw const FormatException('Invalid revenue response.');
    }

    return RevenueSummary(
      totalMinorUnits: totalMinorUnits.toInt(),
      paidEnrollments: paidEnrollments.toInt(),
      enrollmentsWithoutAmount: enrollmentsWithoutAmount.toInt(),
    );
  }
}
