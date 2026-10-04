import 'package:supabase_flutter/supabase_flutter.dart';

class AdminFinancialEntry {
  final String id;
  final String type;
  final int amountMinorUnits;
  final String category;
  final String note;
  final DateTime occurredAt;
  final String? enrollmentId;

  const AdminFinancialEntry({
    required this.id,
    required this.type,
    required this.amountMinorUnits,
    required this.category,
    required this.note,
    required this.occurredAt,
    required this.enrollmentId,
  });

  factory AdminFinancialEntry.fromMap(Map<String, dynamic> data) {
    final id = data['id'];
    final type = data['entry_type'];
    final amount = data['amount_minor_units'];
    final category = data['category'];
    final note = data['note'];
    final occurredAt = data['occurred_at'];
    final enrollmentId = data['enrollment_id'];
    if (id is! String ||
        (type != 'expense' && type != 'refund') ||
        amount is! num ||
        !amount.isFinite ||
        amount < 1 ||
        category is! String ||
        note is! String ||
        occurredAt is! String ||
        DateTime.tryParse(occurredAt) == null ||
        (enrollmentId != null && enrollmentId is! String)) {
      throw const FormatException('Invalid financial entry.');
    }
    return AdminFinancialEntry(
      id: id,
      type: type as String,
      amountMinorUnits: amount.toInt(),
      category: category,
      note: note,
      occurredAt: DateTime.parse(occurredAt),
      enrollmentId: enrollmentId as String?,
    );
  }
}

class AdminPaidEnrollment {
  final String id;
  final String courseTitle;
  final int amountMinorUnits;

  const AdminPaidEnrollment({
    required this.id,
    required this.courseTitle,
    required this.amountMinorUnits,
  });

  factory AdminPaidEnrollment.fromMap(Map<String, dynamic> data) {
    final id = data['id'];
    final courseTitle = data['course_title'];
    final amount = data['payment_amount'];
    if (id is! String ||
        courseTitle is! String ||
        amount is! num ||
        !amount.isFinite ||
        amount < 0) {
      throw const FormatException('Invalid paid enrollment.');
    }
    final amountMinorUnits = (amount * 100).round();
    if (amountMinorUnits <= 0) {
      throw const FormatException(
        'Paid enrollment has no valid recorded amount.',
      );
    }
    return AdminPaidEnrollment(
      id: id,
      courseTitle: courseTitle,
      amountMinorUnits: amountMinorUnits,
    );
  }

  String get label {
    final wholeUnits = amountMinorUnits ~/ 100;
    final fractionalUnits = amountMinorUnits % 100;
    return '$courseTitle · $wholeUnits.${fractionalUnits.toString().padLeft(2, '0')} DZD';
  }
}

class AdminFinancialService {
  static final _client = Supabase.instance.client;

  static Future<List<AdminFinancialEntry>> fetchEntries(String month) async {
    final response = await _client.functions.invoke(
      'admin-financials',
      body: {'action': 'list', 'month': month},
    );
    final data = response.data;
    if (data is! Map || data['entries'] is! List) {
      throw const FormatException('Invalid financial entries response.');
    }
    return (data['entries'] as List).map((entry) {
      if (entry is! Map) {
        throw const FormatException('Invalid financial entry.');
      }
      return AdminFinancialEntry.fromMap(Map<String, dynamic>.from(entry));
    }).toList();
  }

  static Future<List<AdminPaidEnrollment>> fetchPaidEnrollments() async {
    final response = await _client.functions.invoke(
      'admin-financials',
      body: {'action': 'paid-enrollments'},
    );
    final data = response.data;
    if (data is! Map || data['enrollments'] is! List) {
      throw const FormatException('Invalid paid enrollments response.');
    }
    return (data['enrollments'] as List).map((enrollment) {
      if (enrollment is! Map) {
        throw const FormatException('Invalid paid enrollment.');
      }
      return AdminPaidEnrollment.fromMap(Map<String, dynamic>.from(enrollment));
    }).toList();
  }

  static Future<void> createEntry({
    required String type,
    required int amountMinorUnits,
    required String category,
    required String note,
    required DateTime date,
    String? enrollmentId,
  }) async {
    if (type != 'expense' && type != 'refund') {
      throw ArgumentError.value(type, 'type', 'Unsupported financial entry.');
    }
    await _client.functions.invoke(
      'admin-financials',
      body: {
        'action': 'create',
        'entry_type': type,
        'amount_minor_units': amountMinorUnits,
        'category': category,
        'note': note,
        'occurred_at':
            '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
        if (enrollmentId != null) 'enrollment_id': enrollmentId,
      },
    );
  }
}
