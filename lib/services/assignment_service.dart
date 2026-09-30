import 'package:supabase_flutter/supabase_flutter.dart';

class Assignment {
  final String id;
  final String courseId;
  final String courseTitle;
  final String title;
  final String description;
  final DateTime? dueDate;
  final int maxScore;
  final DateTime createdAt;

  Assignment({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.title,
    required this.description,
    this.dueDate,
    required this.maxScore,
    required this.createdAt,
  });

  factory Assignment.fromMap(Map<String, dynamic> map, {String courseTitle = 'Course'}) {
    return Assignment(
      id: map['id'].toString(),
      courseId: map['course_id']?.toString() ?? '',
      courseTitle: courseTitle,
      title: map['title']?.toString() ?? 'Untitled Assignment',
      description: map['description']?.toString() ?? '',
      dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date'].toString()) : null,
      maxScore: (map['max_score'] as num?)?.toInt() ?? 100,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final DateTime submittedAt;
  final String content;
  double? grade;
  String? feedback;
  bool isGraded;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.submittedAt,
    required this.content,
    this.grade,
    this.feedback,
    required this.isGraded,
  });
}

class AssignmentService {
  static final _supabase = Supabase.instance.client;

  // Local fallback storage for assignments and submissions when table is not in Supabase yet
  static final List<Assignment> _localAssignments = [
    Assignment(
      id: 'demo-asg-1',
      courseId: 'demo-c-1',
      courseTitle: 'Full-Stack Web Development',
      title: 'Build a REST API with Authentication',
      description: 'Implement JWT authentication and CRUD endpoints for a blog platform.',
      dueDate: DateTime.now().add(const Duration(days: 7)),
      maxScore: 100,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Assignment(
      id: 'demo-asg-2',
      courseId: 'demo-c-1',
      courseTitle: 'Full-Stack Web Development',
      title: 'Responsive Dashboard UI',
      description: 'Design and build a responsive analytics dashboard with dark mode support.',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      maxScore: 100,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  static final List<Submission> _localSubmissions = [
    Submission(
      id: 'sub-1',
      assignmentId: 'demo-asg-1',
      studentId: 'stud-1',
      studentName: 'Karim Mansouri',
      studentEmail: 'karim@example.com',
      submittedAt: DateTime.now().subtract(const Duration(hours: 14)),
      content: 'https://github.com/karim/rest-api-challenge - Implemented with Node.js and PostgreSQL with tests.',
      grade: 92,
      feedback: 'Excellent clean architecture and comprehensive unit tests!',
      isGraded: true,
    ),
    Submission(
      id: 'sub-2',
      assignmentId: 'demo-asg-1',
      studentId: 'stud-2',
      studentName: 'Amina Belkacem',
      studentEmail: 'amina@example.com',
      submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
      content: 'https://github.com/amina/jwt-blog-api - All requirements fulfilled.',
      grade: null,
      feedback: null,
      isGraded: false,
    ),
    Submission(
      id: 'sub-3',
      assignmentId: 'demo-asg-2',
      studentId: 'stud-3',
      studentName: 'Yassine Taleb',
      studentEmail: 'yassine@example.com',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      content: 'https://vercel.app/yassine-dashboard - Responsive Tailwind UI with charts.',
      grade: null,
      feedback: null,
      isGraded: false,
    ),
  ];

  /// Fetches assignments, optionally filtered by courseId.
  static Future<List<Assignment>> fetchAssignments({String? courseId}) async {
    try {
      // 1. Try Supabase table 'assignments'
      var query = _supabase.from('assignments').select('*, courses(title)');
      if (courseId != null && courseId.isNotEmpty) {
        query = query.eq('course_id', courseId);
      }
      final response = await query.order('created_at', ascending: false);

      final List<Assignment> list = [];
      for (var item in response) {
        final courseTitle = item['courses']?['title']?.toString() ?? 'Course';
        list.add(Assignment.fromMap(item, courseTitle: courseTitle));
      }
      return list;
    } catch (_) {
      // Return local fallback
      if (courseId != null && courseId.isNotEmpty) {
        return _localAssignments.where((a) => a.courseId == courseId).toList();
      }
      return List.from(_localAssignments);
    }
  }

  /// Creates a new assignment.
  static Future<Assignment> createAssignment({
    required String courseId,
    required String courseTitle,
    required String title,
    required String description,
    required DateTime? dueDate,
    required int maxScore,
  }) async {
    try {
      final res = await _supabase.from('assignments').insert({
        'course_id': courseId,
        'title': title,
        'description': description,
        'due_date': dueDate?.toIso8601String(),
        'max_score': maxScore,
      }).select().single();

      return Assignment.fromMap(res, courseTitle: courseTitle);
    } catch (_) {
      final newAsg = Assignment(
        id: 'asg-${DateTime.now().millisecondsSinceEpoch}',
        courseId: courseId,
        courseTitle: courseTitle,
        title: title,
        description: description,
        dueDate: dueDate,
        maxScore: maxScore,
        createdAt: DateTime.now(),
      );
      _localAssignments.insert(0, newAsg);
      return newAsg;
    }
  }

  /// Deletes an assignment by id.
  static Future<void> deleteAssignment(String id) async {
    try {
      await _supabase.from('assignments').delete().eq('id', id);
    } catch (_) {
      _localAssignments.removeWhere((a) => a.id == id);
      _localSubmissions.removeWhere((s) => s.assignmentId == id);
    }
  }

  /// Fetches submissions for an assignment.
  static Future<List<Submission>> fetchSubmissions(String assignmentId) async {
    try {
      final res = await _supabase
          .from('submissions')
          .select('*, profiles(*)')
          .eq('assignment_id', assignmentId)
          .order('submitted_at', ascending: false);

      return res.map<Submission>((item) {
        final profile = item['profiles'] ?? {};
        final gradeNum = item['grade'] as num?;
        return Submission(
          id: item['id'].toString(),
          assignmentId: assignmentId,
          studentId: item['student_id']?.toString() ?? '',
          studentName: profile['full_name']?.toString() ?? 'Student',
          studentEmail: profile['email']?.toString() ?? '',
          submittedAt: DateTime.tryParse(item['submitted_at'].toString()) ?? DateTime.now(),
          content: item['file_url']?.toString() ?? item['content']?.toString() ?? '',
          grade: gradeNum?.toDouble(),
          feedback: item['feedback']?.toString(),
          isGraded: gradeNum != null,
        );
      }).toList();
    } catch (_) {
      return _localSubmissions.where((s) => s.assignmentId == assignmentId).toList();
    }
  }

  /// Grades a submission.
  static Future<void> gradeSubmission({
    required String submissionId,
    required double grade,
    required String feedback,
  }) async {
    try {
      await _supabase.from('submissions').update({
        'grade': grade,
        'feedback': feedback,
      }).eq('id', submissionId);
    } catch (_) {
      final sub = _localSubmissions.firstWhere(
        (s) => s.id == submissionId,
        orElse: () => throw Exception('Submission not found'),
      );
      sub.grade = grade;
      sub.feedback = feedback;
      sub.isGraded = true;
    }
  }
}
