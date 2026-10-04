import 'package:flutter/material.dart';

import '../services/revenue_service.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  late Future<RevenueSummary> _summary;

  @override
  void initState() {
    super.initState();
    _summary = RevenueService.fetchSummary();
  }

  void _refresh() {
    setState(() {
      _summary = RevenueService.fetchSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Revenue',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<RevenueSummary>(
        future: _summary,
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
                      'Unable to load revenue: ${snapshot.error}',
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

          final summary = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _MetricCard(
                title: 'Net recorded cash movement',
                value: summary.formattedNetDzd,
                subtitle:
                    '${summary.formattedDzd} gross − ${summary.formattedRefundsDzd} refunds − ${summary.formattedExpensesDzd} expenses',
                icon: Icons.account_balance_wallet_outlined,
                color: summary.netMinorUnits < 0
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF65A30D),
              ),
              const SizedBox(height: 16),
              _MetricCard(
                title: 'Gross recorded revenue',
                value: summary.formattedDzd,
                subtitle:
                    'Payments recorded for paid enrollments with an amount',
                icon: Icons.trending_up_outlined,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 16),
              _MetricCard(
                title: 'Refunds issued',
                value: summary.formattedRefundsDzd,
                subtitle: 'Refund entries recorded by administrators',
                icon: Icons.reply_outlined,
                color: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 16),
              _MetricCard(
                title: 'Expenses recorded',
                value: summary.formattedExpensesDzd,
                subtitle: 'One-time expenses entered by administrators',
                icon: Icons.money_off_csred_outlined,
                color: const Color(0xFFD97706),
              ),
              const SizedBox(height: 16),
              _MetricCard(
                title: 'Paid enrollments',
                value: '${summary.paidEnrollments}',
                subtitle: 'All enrollments marked paid',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 16),
              _MetricCard(
                title: 'Pending checkouts',
                value: '${summary.pendingEnrollments}',
                subtitle:
                    'Awaiting payment confirmation; not counted as revenue',
                icon: Icons.pending_actions_outlined,
                color: const Color(0xFFD97706),
              ),
              if (summary.enrollmentsWithoutAmount > 0) ...[
                const SizedBox(height: 16),
                _MetricCard(
                  title: 'Historical amounts unavailable',
                  value: '${summary.enrollmentsWithoutAmount}',
                  subtitle:
                      'These paid enrollments have no usable saved purchase amount and are excluded. Current course prices are not substituted for historical payments.',
                  icon: Icons.info_outline,
                  color: const Color(0xFFD97706),
                ),
              ],
              const SizedBox(height: 28),
              const Text(
                'Revenue by course',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (summary.courseRevenues.isEmpty)
                const Card(
                  elevation: 0,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No courses found.'),
                  ),
                )
              else
                ...summary.courseRevenues.map(
                  (course) => Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFFFD8),
                        foregroundColor: Color(0xFF65A30D),
                        child: Icon(Icons.school_outlined),
                      ),
                      title: Text(
                        course.courseTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${course.paidEnrollments} paid '
                        '${course.paidEnrollments == 1 ? 'enrollment' : 'enrollments'}'
                        '${course.refundsMinorUnits > 0 ? ' · ${course.formattedDzd} gross − ${_formatRevenueDzd(course.refundsMinorUnits)} refunds' : ''}'
                        '${course.enrollmentsWithoutAmount > 0 ? ' · ${course.enrollmentsWithoutAmount} without recorded amount' : ''}',
                      ),
                      trailing: Text(
                        course.formattedNetDzd,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: course.netMinorUnits < 0
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF65A30D),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _formatRevenueDzd(int minorUnits) {
  final wholeUnits = minorUnits ~/ 100;
  final fractionalUnits = minorUnits % 100;
  return '$wholeUnits.${fractionalUnits.toString().padLeft(2, '0')} DZD';
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
