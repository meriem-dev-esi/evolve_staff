import 'package:supabase_flutter/supabase_flutter.dart';

class AdminMonthlyActivity {
  final String month;
  final int signups;
  final int enrollments;

  const AdminMonthlyActivity({
    required this.month,
    required this.signups,
    required this.enrollments,
  });

  factory AdminMonthlyActivity.fromMap(Map<String, dynamic> data) {
    final month = data['month'];
    final signups = data['signups'];
    final enrollments = data['enrollments'];
    if (month is! String ||
        signups is! num ||
        enrollments is! num ||
        signups < 0 ||
        enrollments < 0) {
      throw const FormatException('Invalid monthly management activity.');
    }
    return AdminMonthlyActivity(
      month: month,
      signups: signups.toInt(),
      enrollments: enrollments.toInt(),
    );
  }
}

class AdminCoursePerformance {
  final String courseId;
  final String title;
  final int enrollments;
  final int previousEnrollments;
  final int paidEnrollments;
  final int revenueMinorUnits;

  const AdminCoursePerformance({
    required this.courseId,
    required this.title,
    required this.enrollments,
    this.previousEnrollments = 0,
    required this.paidEnrollments,
    required this.revenueMinorUnits,
  });

  String get formattedRevenue {
    final wholeUnits = revenueMinorUnits ~/ 100;
    final fractionalUnits = (revenueMinorUnits % 100).abs();
    return '$wholeUnits.${fractionalUnits.toString().padLeft(2, '0')} DZD';
  }

  factory AdminCoursePerformance.fromMap(Map<String, dynamic> data) {
    final courseId = data['course_id'];
    final title = data['course_title'];
    final enrollments = data['enrollments'];
    final previousEnrollments = data['previous_enrollments'] ?? 0;
    final paidEnrollments = data['paid_enrollments'];
    final revenueMinorUnits = data['revenue_minor_units'];
    if (courseId is! String ||
        title is! String ||
        enrollments is! num ||
        previousEnrollments is! num ||
        paidEnrollments is! num ||
        revenueMinorUnits is! num ||
        enrollments < 0 ||
        previousEnrollments < 0 ||
        paidEnrollments < 0 ||
        revenueMinorUnits < 0) {
      throw const FormatException('Invalid course performance record.');
    }
    return AdminCoursePerformance(
      courseId: courseId,
      title: title,
      enrollments: enrollments.toInt(),
      previousEnrollments: previousEnrollments.toInt(),
      paidEnrollments: paidEnrollments.toInt(),
      revenueMinorUnits: revenueMinorUnits.toInt(),
    );
  }
}

class AdminMonthlyFinancialReport {
  final String month;
  final String previousMonth;
  final int enrollments;
  final int paidEnrollments;
  final int pendingEnrollments;
  final int previousPendingEnrollments;
  final int enrollmentsWithoutAmount;
  final int paidRevenueMinorUnits;
  final int refundsMinorUnits;
  final int expensesMinorUnits;
  final int netMinorUnits;
  final int historicalPaidWithoutTimestamp;
  final int previousEnrollments;
  final int previousPaidEnrollments;
  final int previousPaidRevenueMinorUnits;
  final int previousRefundsMinorUnits;
  final int previousExpensesMinorUnits;
  final int previousNetMinorUnits;
  final List<AdminCoursePerformance> courseRevenues;

  const AdminMonthlyFinancialReport({
    required this.month,
    required this.previousMonth,
    required this.enrollments,
    required this.paidEnrollments,
    required this.pendingEnrollments,
    required this.previousPendingEnrollments,
    required this.enrollmentsWithoutAmount,
    required this.paidRevenueMinorUnits,
    required this.refundsMinorUnits,
    required this.expensesMinorUnits,
    required this.netMinorUnits,
    required this.historicalPaidWithoutTimestamp,
    required this.previousEnrollments,
    required this.previousPaidEnrollments,
    required this.previousPaidRevenueMinorUnits,
    required this.previousRefundsMinorUnits,
    required this.previousExpensesMinorUnits,
    required this.previousNetMinorUnits,
    required this.courseRevenues,
  });

  factory AdminMonthlyFinancialReport.fromMap(Map<String, dynamic> data) {
    int readCount(String key) {
      final value = data[key];
      if (value is! num || value < 0) {
        throw FormatException('Invalid monthly financial report: $key.');
      }
      return value.toInt();
    }

    int readSignedAmount(String key) {
      final value = data[key];
      if (value is! num) {
        throw FormatException('Invalid monthly financial report: $key.');
      }
      return value.toInt();
    }

    final month = data['month'];
    final previousMonth = data['previous_month'];
    final courseRevenues = data['course_revenues'];
    if (month is! String ||
        !RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month) ||
        previousMonth is! String ||
        !RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(previousMonth) ||
        courseRevenues is! List) {
      throw const FormatException('Invalid monthly financial report.');
    }

    return AdminMonthlyFinancialReport(
      month: month,
      previousMonth: previousMonth,
      enrollments: readCount('enrollments'),
      paidEnrollments: readCount('paid_enrollments'),
      pendingEnrollments: readCount('pending_enrollments'),
      previousPendingEnrollments: readCount('previous_pending_enrollments'),
      enrollmentsWithoutAmount: readCount('enrollments_without_amount'),
      paidRevenueMinorUnits: readCount('paid_revenue_minor_units'),
      refundsMinorUnits: readCount('refunds_minor_units'),
      expensesMinorUnits: readCount('expenses_minor_units'),
      netMinorUnits: readSignedAmount('net_minor_units'),
      historicalPaidWithoutTimestamp: readCount(
        'historical_paid_without_timestamp',
      ),
      previousEnrollments: readCount('previous_enrollments'),
      previousPaidEnrollments: readCount('previous_paid_enrollments'),
      previousPaidRevenueMinorUnits: readCount(
        'previous_paid_revenue_minor_units',
      ),
      previousRefundsMinorUnits: readCount('previous_refunds_minor_units'),
      previousExpensesMinorUnits: readCount('previous_expenses_minor_units'),
      previousNetMinorUnits: readSignedAmount('previous_net_minor_units'),
      courseRevenues: courseRevenues.map((course) {
        if (course is! Map) {
          throw const FormatException('Invalid monthly course revenue record.');
        }
        return AdminCoursePerformance.fromMap(
          Map<String, dynamic>.from(course),
        );
      }).toList(),
    );
  }
}

class AdminAnalytics {
  final int users;
  final int students;
  final int teachers;
  final int newUsersThisMonth;
  final int courses;
  final int publishedCourses;
  final int draftCourses;
  final int lessons;
  final int formations;
  final int assignments;
  final int publishedAssignments;
  final int submissions;
  final int ungradedSubmissions;
  final Map<String, int> enrollmentStatuses;
  final int enrollmentsThisMonth;
  final int enrollmentsPreviousMonth;
  final int paidRevenueThisMonthMinorUnits;
  final int paidRevenuePreviousMonthMinorUnits;
  final AdminMonthlyFinancialReport monthlyFinancialReport;
  final List<AdminMonthlyActivity> monthlyActivity;
  final List<AdminCoursePerformance> topCourses;

  const AdminAnalytics({
    required this.users,
    required this.students,
    required this.teachers,
    required this.newUsersThisMonth,
    required this.courses,
    required this.publishedCourses,
    required this.draftCourses,
    required this.lessons,
    required this.formations,
    required this.assignments,
    required this.publishedAssignments,
    required this.submissions,
    required this.ungradedSubmissions,
    required this.enrollmentStatuses,
    required this.enrollmentsThisMonth,
    required this.enrollmentsPreviousMonth,
    required this.paidRevenueThisMonthMinorUnits,
    required this.paidRevenuePreviousMonthMinorUnits,
    required this.monthlyFinancialReport,
    required this.monthlyActivity,
    required this.topCourses,
  });

  factory AdminAnalytics.fromMap(Map<String, dynamic> data) {
    int readCount(String key) {
      final value = data[key];
      if (value is! num || value < 0) {
        throw FormatException('Invalid management statistic: $key.');
      }
      return value.toInt();
    }

    List<T> readRows<T>(String key, T Function(Map<String, dynamic>) parse) {
      final value = data[key];
      if (value is! List) {
        throw FormatException('Invalid management activity: $key.');
      }
      return value.map((row) {
        if (row is! Map) {
          throw FormatException('Invalid management activity: $key.');
        }
        return parse(Map<String, dynamic>.from(row));
      }).toList();
    }

    final statuses = data['enrollment_statuses'];
    if (statuses is! Map) {
      throw const FormatException('Invalid enrollment status statistics.');
    }
    final financialReport = data['monthly_financial_report'];
    if (financialReport is! Map) {
      throw const FormatException('Invalid monthly financial report.');
    }
    final enrollmentStatuses = <String, int>{};
    for (final entry in statuses.entries) {
      if (entry.key is! String || entry.value is! num || entry.value < 0) {
        throw const FormatException('Invalid enrollment status statistics.');
      }
      enrollmentStatuses[entry.key as String] = (entry.value as num).toInt();
    }

    return AdminAnalytics(
      users: readCount('users'),
      students: readCount('students'),
      teachers: readCount('teachers'),
      newUsersThisMonth: readCount('new_users_this_month'),
      courses: readCount('courses'),
      publishedCourses: readCount('published_courses'),
      draftCourses: readCount('draft_courses'),
      lessons: readCount('lessons'),
      formations: readCount('formations'),
      assignments: readCount('assignments'),
      publishedAssignments: readCount('published_assignments'),
      submissions: readCount('submissions'),
      ungradedSubmissions: readCount('ungraded_submissions'),
      enrollmentStatuses: enrollmentStatuses,
      enrollmentsThisMonth: readCount('enrollments_this_month'),
      enrollmentsPreviousMonth: readCount('enrollments_previous_month'),
      paidRevenueThisMonthMinorUnits: readCount(
        'paid_revenue_this_month_minor_units',
      ),
      paidRevenuePreviousMonthMinorUnits: readCount(
        'paid_revenue_previous_month_minor_units',
      ),
      monthlyFinancialReport: AdminMonthlyFinancialReport.fromMap(
        Map<String, dynamic>.from(financialReport),
      ),
      monthlyActivity: readRows(
        'monthly_activity',
        AdminMonthlyActivity.fromMap,
      ),
      topCourses: readRows('top_courses', AdminCoursePerformance.fromMap),
    );
  }

  static Future<AdminAnalytics> fetch({String? month}) async {
    final response = await Supabase.instance.client.functions.invoke(
      'admin-analytics',
      body: month == null ? null : {'month': month},
    );
    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('Invalid management analytics response.');
    }
    return AdminAnalytics.fromMap(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
