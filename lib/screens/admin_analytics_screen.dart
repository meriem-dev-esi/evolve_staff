import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/admin_analytics_service.dart';
import '../services/admin_financial_service.dart';
import '../services/financial_report_download.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  late Future<AdminAnalytics> _analytics;
  late String _selectedFinancialMonth;

  @override
  void initState() {
    super.initState();
    _selectedFinancialMonth = _monthKey(DateTime.now());
    _analytics = AdminAnalytics.fetch(month: _selectedFinancialMonth);
  }

  void _refresh() {
    setState(
      () => _analytics = AdminAnalytics.fetch(month: _selectedFinancialMonth),
    );
  }

  void _selectFinancialMonth(String month) {
    setState(() {
      _selectedFinancialMonth = month;
      _analytics = AdminAnalytics.fetch(month: month);
    });
  }

  Future<void> _copyFinancialReport(AdminMonthlyFinancialReport report) async {
    final csv = _monthlyReportCsv(report);
    final downloaded = downloadFinancialReport(
      'evolve-financial-report-${report.month}.csv',
      csv,
    );
    if (!downloaded) {
      await Clipboard.setData(ClipboardData(text: csv));
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          downloaded
              ? 'Monthly CSV report downloaded.'
              : 'Monthly CSV report copied to clipboard.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Management Statistics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh statistics',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<AdminAnalytics>(
        future: _analytics,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load management statistics: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final analytics = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final columns = constraints.maxWidth >= 1100
                  ? 4
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Platform health and operational performance',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: columns == 1 ? 3.2 : 1.8,
                    children: [
                      _MetricCard(
                        title: 'Total users',
                        value: '${analytics.users}',
                        caption:
                            '${analytics.students} students · ${analytics.teachers} teachers',
                        icon: Icons.people_outline,
                        color: const Color(0xFF2563EB),
                      ),
                      _MetricCard(
                        title: 'New users this month',
                        value: '${analytics.newUsersThisMonth}',
                        caption: 'New accounts created this month',
                        icon: Icons.person_add_alt_1_outlined,
                        color: const Color(0xFF0891B2),
                      ),
                      _MetricCard(
                        title: 'Enrollments this month',
                        value: '${analytics.enrollmentsThisMonth}',
                        caption: _changeCaption(
                          analytics.enrollmentsThisMonth,
                          analytics.enrollmentsPreviousMonth,
                        ),
                        icon: Icons.how_to_reg_outlined,
                        color: const Color(0xFF7C3AED),
                      ),
                      _MetricCard(
                        title: 'Paid revenue this month',
                        value: _formatDzd(
                          analytics.paidRevenueThisMonthMinorUnits,
                        ),
                        caption:
                            'Previous month: ${_formatDzd(analytics.paidRevenuePreviousMonthMinorUnits)}',
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF65A30D),
                      ),
                      _MetricCard(
                        title: 'Course publication',
                        value:
                            '${analytics.publishedCourses}/${analytics.courses}',
                        caption: '${analytics.draftCourses} drafts to review',
                        icon: Icons.public_outlined,
                        color: const Color(0xFFEA580C),
                      ),
                      _MetricCard(
                        title: 'Assignments to grade',
                        value: '${analytics.ungradedSubmissions}',
                        caption:
                            '${analytics.submissions} total student submissions',
                        icon: Icons.rate_review_outlined,
                        color: const Color(0xFFDB2777),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _MonthlyFinancialReportSection(
                    report: analytics.monthlyFinancialReport,
                    months: _financialReportMonths(),
                    selectedMonth: _selectedFinancialMonth,
                    onMonthChanged: _selectFinancialMonth,
                    onCopyReport: _copyFinancialReport,
                  ),
                  const SizedBox(height: 12),
                  _FinancialLedgerSection(
                    key: ValueKey(_selectedFinancialMonth),
                    month: _selectedFinancialMonth,
                    onSaved: _refresh,
                  ),
                  const SizedBox(height: 28),
                  _SectionCard(
                    title: 'Enrollment payment funnel',
                    subtitle: 'Current status of all course enrollments',
                    child: _EnrollmentStatuses(
                      statuses: analytics.enrollmentStatuses,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Six-month activity',
                    subtitle: 'New accounts and enrollments by month',
                    child: _MonthlyActivityChart(
                      activity: analytics.monthlyActivity,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Course demand',
                    subtitle:
                        'Top ${analytics.topCourses.length} courses ranked by total enrollments',
                    child: _CourseDemandTable(
                      courses: analytics.topCourses,
                      wide: wide,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Learning content',
                    subtitle: 'Content available across the platform',
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _CountChip(label: 'Lessons', count: analytics.lessons),
                        _CountChip(
                          label: 'Formations',
                          count: analytics.formations,
                        ),
                        _CountChip(
                          label: 'Assignments',
                          count: analytics.assignments,
                        ),
                        _CountChip(
                          label: 'Published assignments',
                          count: analytics.publishedAssignments,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

String _monthKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

List<String> _financialReportMonths() {
  final current = DateTime.now();
  return List.generate(
    36,
    (index) => _monthKey(DateTime(current.year, current.month - index)),
  );
}

String _monthLabel(String month) {
  final parts = month.split('-');
  final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${names[date.month - 1]} ${date.year}';
}

String _monthlyReportCsv(AdminMonthlyFinancialReport report) {
  String escape(String value) => '"${value.replaceAll('"', '""')}"';
  final rows = <List<String>>[
    ['Evolve Staff monthly financial report', _monthLabel(report.month)],
    ['Metric', 'Value'],
    ['Gross revenue received (DZD)', _formatDzd(report.paidRevenueMinorUnits)],
    ['Refunds issued (DZD)', _formatDzd(report.refundsMinorUnits)],
    ['Expenses recorded (DZD)', _formatDzd(report.expensesMinorUnits)],
    ['Net cash movement (DZD)', _formatDzd(report.netMinorUnits)],
    ['Payments received', '${report.paidEnrollments}'],
    ['Total enrollments', '${report.enrollments}'],
    ['Pending enrollments', '${report.pendingEnrollments}'],
    ['Paid enrollments missing amount', '${report.enrollmentsWithoutAmount}'],
    [
      'Historical payments missing paid date',
      '${report.historicalPaidWithoutTimestamp}',
    ],
    [
      'Previous month (${_monthLabel(report.previousMonth)}) revenue (DZD)',
      _formatDzd(report.previousPaidRevenueMinorUnits),
    ],
    ['Previous month payments received', '${report.previousPaidEnrollments}'],
    [
      'Previous month refunds (DZD)',
      _formatDzd(report.previousRefundsMinorUnits),
    ],
    [
      'Previous month expenses (DZD)',
      _formatDzd(report.previousExpensesMinorUnits),
    ],
    [
      'Previous month net cash movement (DZD)',
      _formatDzd(report.previousNetMinorUnits),
    ],
    ['Previous month total enrollments', '${report.previousEnrollments}'],
    ['', ''],
    ['Course', 'Revenue (DZD)', 'Paid enrollments', 'All enrollments'],
    ...report.courseRevenues.map(
      (course) => [
        course.title,
        _formatDzd(course.revenueMinorUnits),
        '${course.paidEnrollments}',
        '${course.enrollments}',
      ],
    ),
    ['', ''],
    [
      'Decision note',
      'Payment income is grouped by actual paid date. Expenses and refunds are manual entries. Net cash movement excludes processor fees and is not accounting profit.',
    ],
  ];
  return rows.map((row) => row.map(escape).join(',')).join('\r\n');
}

class _MonthlyFinancialReportSection extends StatelessWidget {
  final AdminMonthlyFinancialReport report;
  final List<String> months;
  final String selectedMonth;
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<AdminMonthlyFinancialReport> onCopyReport;

  const _MonthlyFinancialReportSection({
    required this.report,
    required this.months,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onCopyReport,
  });

  @override
  Widget build(BuildContext context) {
    final netComparison = _financialComparison(
      report.netMinorUnits,
      report.previousNetMinorUnits,
    );
    final revenueChange = _financialComparison(
      report.paidRevenueMinorUnits,
      report.previousPaidRevenueMinorUnits,
    );

    return _SectionCard(
      title: 'Monthly financial report',
      subtitle:
          'Payments by actual paid date, less recorded refunds and expenses',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              DropdownButton<String>(
                value: selectedMonth,
                onChanged: (month) {
                  if (month != null) onMonthChanged(month);
                },
                items: months
                    .map(
                      (month) => DropdownMenuItem(
                        value: month,
                        child: Text(_monthLabel(month)),
                      ),
                    )
                    .toList(),
              ),
              OutlinedButton.icon(
                onPressed: () => onCopyReport(report),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Download CSV report'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _FinancialReportMetric(
                label: 'Gross recorded revenue',
                value: _formatDzd(report.paidRevenueMinorUnits),
                detail: '${revenueChange.label} vs previous month',
                color: const Color(0xFF65A30D),
                detailColor: revenueChange.color,
                icon: Icons.account_balance_wallet_outlined,
              ),
              _FinancialReportMetric(
                label: 'Net cash movement',
                value: _formatDzd(report.netMinorUnits),
                detail: '${netComparison.label} vs previous month',
                color: const Color(0xFF2563EB),
                detailColor: netComparison.color,
                icon: Icons.account_balance_outlined,
              ),
              _FinancialReportMetric(
                label: 'Refunds issued',
                value: _formatDzd(report.refundsMinorUnits),
                detail: '${report.paidEnrollments} payments received',
                color: const Color(0xFF7C3AED),
                icon: Icons.reply_outlined,
              ),
              _FinancialReportMetric(
                label: 'Expenses recorded',
                value: _formatDzd(report.expensesMinorUnits),
                detail: 'Enter expenses in the ledger below',
                color: const Color(0xFFD97706),
                icon: Icons.money_off_csred_outlined,
              ),
              _FinancialReportMetric(
                label: 'Pending checkouts',
                value: '${report.pendingEnrollments}',
                detail: '${report.enrollments} enrollments in selected month',
                color: const Color(0xFF0891B2),
                detailColor: Colors.blueGrey,
                icon: Icons.pending_actions_outlined,
              ),
              if (report.enrollmentsWithoutAmount > 0)
                _FinancialReportMetric(
                  label: 'Amounts not recorded',
                  value: '${report.enrollmentsWithoutAmount}',
                  detail: 'Paid enrollments excluded from revenue',
                  color: const Color(0xFFDC2626),
                  icon: Icons.warning_amber_outlined,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Previous month net cash movement: '
            '${_formatDzd(report.previousNetMinorUnits)} '
            '(${_formatDzd(report.previousPaidRevenueMinorUnits)} received, '
            '${_formatDzd(report.previousRefundsMinorUnits)} refunded, '
            '${_formatDzd(report.previousExpensesMinorUnits)} expenses).',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payments received by course',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (report.courseRevenues.isEmpty)
            const Text('No enrollments recorded for this month.')
          else
            ...report.courseRevenues.map(
              (course) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${course.title}\n'
                        '${course.enrollments} enrollments this month · '
                        '${course.previousEnrollments} previous month',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDzd(course.revenueMinorUnits),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            'Decision note: new payments are grouped by their actual paid date. '
            'Historical payments without a saved paid date cannot be assigned '
            'to a month and are excluded from this report. Expenses and refunds '
            'are manual records. Net cash movement does not include payment '
            'processor fees and is not accounting profit.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          if (report.historicalPaidWithoutTimestamp > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${report.historicalPaidWithoutTimestamp} historical paid '
              'enrollments do not have a payment date; they are excluded from '
              'monthly revenue totals.',
              style: const TextStyle(color: Color(0xFFD97706), fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          _FinancialAlerts(report: report),
        ],
      ),
    );
  }
}

({String label, Color color}) _financialComparison(int current, int previous) {
  if (previous == 0) {
    return (
      label: current == 0 ? 'No change' : 'No prior-month baseline',
      color: Colors.blueGrey,
    );
  }
  if (previous < 0) {
    return (
      label: current > previous
          ? 'Improved from prior deficit'
          : 'Prior deficit',
      color: current > previous
          ? const Color(0xFF65A30D)
          : const Color(0xFFDC2626),
    );
  }
  final change = ((current - previous) * 100 / previous).round();
  final prefix = change > 0 ? '+' : '';
  return (
    label: '$prefix$change%',
    color: change > 0
        ? const Color(0xFF65A30D)
        : change < 0
        ? const Color(0xFFDC2626)
        : Colors.blueGrey,
  );
}

class _FinancialReportMetric extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final Color color;
  final Color? detailColor;
  final IconData icon;

  const _FinancialReportMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
    this.detailColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      detail,
                      style: TextStyle(
                        color: detailColor ?? color,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinancialAlerts extends StatelessWidget {
  final AdminMonthlyFinancialReport report;

  const _FinancialAlerts({required this.report});

  @override
  Widget build(BuildContext context) {
    final alerts = <({String message, Color color, IconData icon})>[];
    if (report.previousPaidRevenueMinorUnits > 0 &&
        report.paidRevenueMinorUnits <=
            report.previousPaidRevenueMinorUnits * 0.8) {
      alerts.add((
        message:
            'Payment revenue is down at least 20% from the previous month.',
        color: const Color(0xFFDC2626),
        icon: Icons.trending_down,
      ));
    }
    if (report.pendingEnrollments > report.previousPendingEnrollments &&
        report.pendingEnrollments > 0) {
      alerts.add((
        message:
            'Pending checkouts in this month’s enrollment cohort increased from '
            '${report.previousPendingEnrollments} in the previous cohort to '
            '${report.pendingEnrollments}; follow up on these checkouts.',
        color: const Color(0xFFD97706),
        icon: Icons.pending_actions_outlined,
      ));
    }
    final decliningCourses = report.courseRevenues
        .where(
          (course) =>
              course.previousEnrollments > 0 &&
              course.enrollments < course.previousEnrollments,
        )
        .take(3)
        .toList();
    for (final course in decliningCourses) {
      alerts.add((
        message:
            '${course.title} enrollments declined from '
            '${course.previousEnrollments} to ${course.enrollments}.',
        color: const Color(0xFFD97706),
        icon: Icons.school_outlined,
      ));
    }
    if (alerts.isEmpty) {
      return const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF65A30D), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No financial or enrollment alerts for this comparison.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Decision alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        ...alerts.map(
          (alert) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(alert.icon, color: alert.color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.message,
                    style: TextStyle(color: alert.color, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FinancialLedgerSection extends StatefulWidget {
  final String month;
  final VoidCallback onSaved;

  const _FinancialLedgerSection({
    super.key,
    required this.month,
    required this.onSaved,
  });

  @override
  State<_FinancialLedgerSection> createState() =>
      _FinancialLedgerSectionState();
}

class _FinancialLedgerSectionState extends State<_FinancialLedgerSection> {
  late Future<List<AdminFinancialEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = AdminFinancialService.fetchEntries(widget.month);
  }

  void _refresh() {
    setState(() {
      _entries = AdminFinancialService.fetchEntries(widget.month);
    });
  }

  Future<void> _addEntry(String type) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _FinancialEntryDialog(entryType: type),
    );
    if (saved != true || !mounted) return;
    _refresh();
    widget.onSaved();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          type == 'expense' ? 'Expense recorded.' : 'Refund recorded.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Expenses and refunds ledger',
      subtitle:
          'Manually record one-time expenses and refunds already issued; recording a refund here does not send money. Saved entries cannot be edited here.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _addEntry('expense'),
                icon: const Icon(Icons.add),
                label: const Text('Add expense'),
              ),
              OutlinedButton.icon(
                onPressed: () => _addEntry('refund'),
                icon: const Icon(Icons.reply_outlined),
                label: const Text('Record refund'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<AdminFinancialEntry>>(
            future: _entries,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unable to load financial entries: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    TextButton(onPressed: _refresh, child: const Text('Retry')),
                  ],
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final entries = snapshot.data!;
              if (entries.isEmpty) {
                return const Text(
                  'No expenses or refunds recorded for this month.',
                  style: TextStyle(color: Colors.black54),
                );
              }
              return Column(
                children: entries
                    .map(
                      (entry) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              (entry.type == 'expense'
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF7C3AED))
                                  .withValues(alpha: 0.12),
                          foregroundColor: entry.type == 'expense'
                              ? const Color(0xFFD97706)
                              : const Color(0xFF7C3AED),
                          child: Icon(
                            entry.type == 'expense'
                                ? Icons.money_off_csred_outlined
                                : Icons.reply_outlined,
                          ),
                        ),
                        title: Text(
                          '${entry.category} · ${entry.note}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${entry.type == 'expense' ? 'Expense' : 'Refund'} · '
                          '${entry.occurredAt.toLocal().toString().split(' ').first}',
                        ),
                        trailing: Text(
                          _formatDzd(entry.amountMinorUnits),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FinancialEntryDialog extends StatefulWidget {
  final String entryType;

  const _FinancialEntryDialog({required this.entryType});

  @override
  State<_FinancialEntryDialog> createState() => _FinancialEntryDialogState();
}

class _FinancialEntryDialogState extends State<_FinancialEntryDialog> {
  static const _expenseCategories = [
    'Marketing',
    'Software',
    'Rent',
    'Salaries',
    'Materials',
    'Other',
  ];
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _date;
  late String _category;
  String? _enrollmentId;
  late Future<List<AdminPaidEnrollment>> _paidEnrollments;
  bool _saving = false;

  bool get _isRefund => widget.entryType == 'refund';

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _category = _isRefund ? 'Course refund' : _expenseCategories.first;
    _paidEnrollments = _isRefund
        ? AdminFinancialService.fetchPaidEnrollments()
        : Future.value(const []);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? _amountMinorUnits(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) return null;
    final parts = normalized.split('.');
    final whole = int.tryParse(parts.first);
    final fractional = parts.length == 1
        ? 0
        : int.parse(parts[1].padRight(2, '0'));
    if (whole == null || whole > (0x1fffffffffffff - fractional) ~/ 100) {
      return null;
    }
    final result = whole * 100 + fractional;
    return result > 0 ? result : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _amountMinorUnits(_amountController.text);
    if (amount == null) return;
    if (_isRefund && _enrollmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a paid enrollment with a recorded amount.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await AdminFinancialService.createEntry(
        type: widget.entryType,
        amountMinorUnits: amount,
        category: _category,
        note: _noteController.text.trim(),
        date: _date,
        enrollmentId: _isRefund ? _enrollmentId : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save financial entry: $error')),
      );
    }
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isRefund ? 'Record refund' : 'Add expense';
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isRefund)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'This records a refund already issued outside this screen; it does not send money to the learner.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ),
                if (_isRefund)
                  FutureBuilder<List<AdminPaidEnrollment>>(
                    future: _paidEnrollments,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          'Unable to load paid enrollments: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      if (snapshot.data!.isEmpty) {
                        return const Text(
                          'No paid enrollments with a recorded amount are available.',
                        );
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: _enrollmentId,
                        decoration: const InputDecoration(
                          labelText: 'Paid enrollment',
                        ),
                        items: snapshot.data!
                            .map(
                              (enrollment) => DropdownMenuItem(
                                value: enrollment.id,
                                child: Text(
                                  enrollment.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() {
                                _enrollmentId = value;
                              }),
                        validator: (value) => value == null
                            ? 'Select the enrollment being refunded'
                            : null,
                      );
                    },
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _expenseCategories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _category = value);
                            }
                          },
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (DZD)',
                    hintText: '0.00',
                  ),
                  validator: (value) => _amountMinorUnits(value ?? '') == null
                      ? 'Enter a positive amount with up to 2 decimals'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'What was this expense or refund for?',
                  ),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? 'Enter a note' : null,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    'Date: ${_date.toLocal().toString().split(' ').first}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}

String _formatDzd(int minorUnits) {
  final wholeUnits = minorUnits ~/ 100;
  final fractionalUnits = (minorUnits % 100).abs();
  return '$wholeUnits.${fractionalUnits.toString().padLeft(2, '0')} DZD';
}

String _changeCaption(int current, int previous) {
  if (previous == 0) {
    return current == 0
        ? 'No enrollments in either period'
        : 'No prior-month baseline';
  }
  final change = ((current - previous) * 100 / previous).round();
  final prefix = change > 0 ? '+' : '';
  return '$prefix$change% vs previous month ($previous)';
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _EnrollmentStatuses extends StatelessWidget {
  final Map<String, int> statuses;

  const _EnrollmentStatuses({required this.statuses});

  @override
  Widget build(BuildContext context) {
    final entries = statuses.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    if (entries.isEmpty) return const Text('No enrollment data available.');

    final total = statuses.values.fold<int>(0, (sum, value) => sum + value);
    return LayoutBuilder(
      builder: (context, constraints) {
        final chart = Semantics(
          label: 'Enrollment status chart, $total total enrollments',
          child: SizedBox(
            width: 176,
            height: 176,
            child: CustomPaint(
              painter: _EnrollmentDonutPainter(statuses: statuses),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'enrollments',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final legend = Column(
          mainAxisSize: MainAxisSize.min,
          children: entries.map((entry) {
            final label = entry.key.isEmpty
                ? 'Unknown'
                : '${entry.key[0].toUpperCase()}${entry.key.substring(1)}';
            final color = _statusColor(entry.key);
            final percentage = total == 0
                ? 0
                : (entry.value * 100 / total).round();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: Text(label)),
                  Text(
                    '$percentage%',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${entry.value}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

        if (constraints.maxWidth < 470) {
          return Column(children: [chart, const SizedBox(height: 12), legend]);
        }
        return Row(
          children: [
            chart,
            const SizedBox(width: 20),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

Color _statusColor(String status) => switch (status) {
  'paid' => const Color(0xFF65A30D),
  'pending' => const Color(0xFFD97706),
  'failed' => const Color(0xFFDC2626),
  'cancelled' => const Color(0xFF64748B),
  'refunded' => const Color(0xFF7C3AED),
  _ => const Color(0xFF0891B2),
};

class _EnrollmentDonutPainter extends CustomPainter {
  final Map<String, int> statuses;

  const _EnrollmentDonutPainter({required this.statuses});

  @override
  void paint(Canvas canvas, Size size) {
    final total = statuses.values.fold<int>(0, (sum, value) => sum + value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 13;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final backgroundPaint = Paint()
      ..color = const Color(0xFFE9EEF3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;
    canvas.drawCircle(center, radius, backgroundPaint);
    if (total == 0) return;

    var startAngle = -math.pi / 2;
    for (final entry in statuses.entries) {
      if (entry.value <= 0) continue;
      final sweepAngle = entry.value / total * math.pi * 2;
      final paint = Paint()
        ..color = _statusColor(entry.key)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_EnrollmentDonutPainter oldDelegate) =>
      oldDelegate.statuses != statuses;
}

class _MonthlyActivityChart extends StatelessWidget {
  final List<AdminMonthlyActivity> activity;

  const _MonthlyActivityChart({required this.activity});

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) return const Text('No recent activity available.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _ChartLegend(color: Color(0xFF2563EB), label: 'New accounts'),
            _ChartLegend(color: Color(0xFF65A30D), label: 'Enrollments'),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Semantics(
            label:
                'Monthly activity: ${activity.map((month) => '${_formatMonth(month.month)}: ${month.signups} new accounts, ${month.enrollments} enrollments').join('; ')}',
            child: CustomPaint(
              painter: _MonthlyActivityPainter(activity: activity),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _MonthlyActivityPainter extends CustomPainter {
  final List<AdminMonthlyActivity> activity;
  static const _signupsColor = Color(0xFF2563EB);
  static const _enrollmentsColor = Color(0xFF65A30D);

  const _MonthlyActivityPainter({required this.activity});

  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0;
    const right = 10.0;
    const top = 12.0;
    const bottom = 34.0;
    final chartWidth = math.max(0.0, size.width - left - right);
    final chartHeight = math.max(0.0, size.height - top - bottom);
    if (chartWidth == 0 || chartHeight == 0) return;

    final maxValue = activity.fold<int>(
      1,
      (max, month) => math.max(max, math.max(month.signups, month.enrollments)),
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EDF2)
      ..strokeWidth = 1;
    final axisLabelStyle = TextStyle(
      color: Colors.blueGrey.shade400,
      fontSize: 10,
    );

    for (var index = 0; index <= 4; index++) {
      final ratio = index / 4;
      final y = top + chartHeight * ratio;
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
      final value = (maxValue * (1 - ratio)).round();
      _paintText(
        canvas,
        '$value',
        Offset(0, y - 6),
        axisLabelStyle,
        width: left - 8,
        align: TextAlign.right,
      );
    }

    final xStep = activity.length <= 1
        ? 0.0
        : chartWidth / (activity.length - 1);
    final signupPoints = <Offset>[];
    final enrollmentPoints = <Offset>[];
    for (var index = 0; index < activity.length; index++) {
      final month = activity[index];
      final x = left + xStep * index;
      final signupY = top + chartHeight * (1 - month.signups / maxValue);
      final enrollmentY =
          top + chartHeight * (1 - month.enrollments / maxValue);
      signupPoints.add(Offset(x, signupY));
      enrollmentPoints.add(Offset(x, enrollmentY));
      _paintText(
        canvas,
        _formatMonth(month.month),
        Offset(x - 32, top + chartHeight + 10),
        axisLabelStyle,
        width: 64,
        align: TextAlign.center,
        maxLines: 1,
      );
    }

    _drawSeries(canvas, signupPoints, _signupsColor);
    _drawSeries(canvas, enrollmentPoints, _enrollmentsColor);
  }

  void _drawSeries(Canvas canvas, List<Offset> points, Color color) {
    if (points.isEmpty) return;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    final pointPaint = Paint()..color = color;
    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(point, 4, pointBorderPaint);
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double width,
    TextAlign align = TextAlign.left,
    int maxLines = 2,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_MonthlyActivityPainter oldDelegate) =>
      oldDelegate.activity != activity;
}

class _CourseDemandTable extends StatelessWidget {
  final List<AdminCoursePerformance> courses;
  final bool wide;

  const _CourseDemandTable({required this.courses, required this.wide});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const Text('No courses available.');
    return Column(
      children: [
        if (wide)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(flex: 5, child: Text('Course')),
                Expanded(child: Text('Enrolled')),
                Expanded(child: Text('Paid')),
                Expanded(flex: 2, child: Text('Revenue')),
              ],
            ),
          ),
        ...courses.map(
          (course) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: wide
                ? null
                : Text(
                    '${course.enrollments} enrolled · '
                    '${course.paidEnrollments} paid',
                  ),
            trailing: wide
                ? SizedBox(
                    width: 300,
                    child: Row(
                      children: [
                        Expanded(child: Text('${course.enrollments}')),
                        Expanded(child: Text('${course.paidEnrollments}')),
                        Expanded(flex: 2, child: Text(course.formattedRevenue)),
                      ],
                    ),
                  )
                : Text(
                    course.formattedRevenue,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;

  const _CountChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.insights_outlined, size: 17),
      label: Text('$label · $count'),
      backgroundColor: const Color(0xFFF1F5F9),
    );
  }
}

String _formatMonth(String value) {
  final parts = value.split('-');
  if (parts.length != 2) return value;
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = int.tryParse(parts[1]);
  if (month == null || month < 1 || month > 12) return value;
  return '${names[month - 1]} ${parts[0]}';
}
