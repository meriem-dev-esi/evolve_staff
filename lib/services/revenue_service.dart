import 'package:supabase_flutter/supabase_flutter.dart';

class CourseRevenue {
  final String courseId;
  final String courseTitle;
  final int totalMinorUnits;
  final int refundsMinorUnits;
  final int netMinorUnits;
  final int paidEnrollments;
  final int enrollmentsWithoutAmount;

  const CourseRevenue({
    required this.courseId,
    required this.courseTitle,
    required this.totalMinorUnits,
    required this.refundsMinorUnits,
    required this.netMinorUnits,
    required this.paidEnrollments,
    required this.enrollmentsWithoutAmount,
  });

  String get formattedDzd {
    return _formatDzd(totalMinorUnits);
  }

  String get formattedNetDzd => _formatDzd(netMinorUnits);

  factory CourseRevenue.fromMap(Map<String, dynamic> data) {
    final courseId = data['course_id'];
    final courseTitle = data['course_title'];
    final totalMinorUnits = data['total_minor_units'];
    final refundsMinorUnits = data['refunds_minor_units'];
    final netMinorUnits = data['net_minor_units'];
    final paidEnrollments = data['paid_enrollments'];
    final enrollmentsWithoutAmount = data['enrollments_without_amount'];
    if (courseId is! String ||
        courseTitle is! String ||
        totalMinorUnits is! num ||
        refundsMinorUnits is! num ||
        netMinorUnits is! num ||
        paidEnrollments is! num ||
        enrollmentsWithoutAmount is! num ||
        totalMinorUnits < 0 ||
        refundsMinorUnits < 0 ||
        paidEnrollments < 0 ||
        enrollmentsWithoutAmount < 0) {
      throw const FormatException('Invalid course revenue record.');
    }
    if (netMinorUnits.toInt() !=
        totalMinorUnits.toInt() - refundsMinorUnits.toInt()) {
      throw const FormatException('Inconsistent course revenue totals.');
    }

    return CourseRevenue(
      courseId: courseId,
      courseTitle: courseTitle,
      totalMinorUnits: totalMinorUnits.toInt(),
      refundsMinorUnits: refundsMinorUnits.toInt(),
      netMinorUnits: netMinorUnits.toInt(),
      paidEnrollments: paidEnrollments.toInt(),
      enrollmentsWithoutAmount: enrollmentsWithoutAmount.toInt(),
    );
  }
}

class RevenueSummary {
  final int totalMinorUnits;
  final int refundsMinorUnits;
  final int expensesMinorUnits;
  final int netMinorUnits;
  final int paidEnrollments;
  final int pendingEnrollments;
  final int enrollmentsWithoutAmount;
  final List<CourseRevenue> courseRevenues;

  const RevenueSummary({
    required this.totalMinorUnits,
    required this.refundsMinorUnits,
    required this.expensesMinorUnits,
    required this.netMinorUnits,
    required this.paidEnrollments,
    required this.pendingEnrollments,
    required this.enrollmentsWithoutAmount,
    required this.courseRevenues,
  });

  String get formattedDzd {
    return _formatDzd(totalMinorUnits);
  }

  String get formattedNetDzd => _formatDzd(netMinorUnits);
  String get formattedRefundsDzd => _formatDzd(refundsMinorUnits);
  String get formattedExpensesDzd => _formatDzd(expensesMinorUnits);

  factory RevenueSummary.fromMap(Map<String, dynamic> data) {
    final totalMinorUnits = data['total_minor_units'];
    final refundsMinorUnits = data['refunds_minor_units'];
    final expensesMinorUnits = data['expenses_minor_units'];
    final netMinorUnits = data['net_minor_units'];
    final paidEnrollments = data['paid_enrollments'];
    final pendingEnrollments = data['pending_enrollments'];
    final enrollmentsWithoutAmount = data['enrollments_without_amount'];
    final courseRevenues = data['course_revenues'];
    if (totalMinorUnits is! num ||
        refundsMinorUnits is! num ||
        expensesMinorUnits is! num ||
        netMinorUnits is! num ||
        paidEnrollments is! num ||
        pendingEnrollments is! num ||
        enrollmentsWithoutAmount is! num ||
        courseRevenues is! List ||
        totalMinorUnits < 0 ||
        refundsMinorUnits < 0 ||
        expensesMinorUnits < 0 ||
        paidEnrollments < 0 ||
        pendingEnrollments < 0 ||
        enrollmentsWithoutAmount < 0) {
      throw const FormatException('Invalid revenue response.');
    }

    final parsedCourses = courseRevenues.map((course) {
      if (course is! Map) {
        throw const FormatException('Invalid course revenue record.');
      }
      return CourseRevenue.fromMap(Map<String, dynamic>.from(course));
    }).toList();
    final calculatedNet =
        totalMinorUnits.toInt() -
        refundsMinorUnits.toInt() -
        expensesMinorUnits.toInt();
    final courseGross = parsedCourses.fold<int>(
      0,
      (total, course) => total + course.totalMinorUnits,
    );
    final courseRefunds = parsedCourses.fold<int>(
      0,
      (total, course) => total + course.refundsMinorUnits,
    );
    if (netMinorUnits.toInt() != calculatedNet ||
        courseGross != totalMinorUnits.toInt() ||
        courseRefunds != refundsMinorUnits.toInt()) {
      throw const FormatException('Inconsistent revenue totals.');
    }

    return RevenueSummary(
      totalMinorUnits: totalMinorUnits.toInt(),
      refundsMinorUnits: refundsMinorUnits.toInt(),
      expensesMinorUnits: expensesMinorUnits.toInt(),
      netMinorUnits: netMinorUnits.toInt(),
      paidEnrollments: paidEnrollments.toInt(),
      pendingEnrollments: pendingEnrollments.toInt(),
      enrollmentsWithoutAmount: enrollmentsWithoutAmount.toInt(),
      courseRevenues: parsedCourses,
    );
  }
}

String _formatDzd(int minorUnits) {
  final wholeUnits = minorUnits.abs() ~/ 100;
  final fractionalUnits = minorUnits.abs() % 100;
  final sign = minorUnits < 0 ? '-' : '';
  return '$sign$wholeUnits.${fractionalUnits.toString().padLeft(2, '0')} DZD';
}

class RevenueService {
  static Future<RevenueSummary> fetchSummary() async {
    final client = Supabase.instance.client;
    final response = await client.functions.invoke('admin-revenue');
    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('Invalid revenue response.');
    }
    return RevenueSummary.fromMap(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
