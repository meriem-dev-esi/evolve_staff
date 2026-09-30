import 'package:supabase_flutter/supabase_flutter.dart';

class StudentOverview {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final int enrolledCoursesCount;
  final int completedLessonsCount;
  final int totalLessonsCount;
  final double overallPercentage;
  final List<StudentCourseProgress> coursesProgress;

  StudentOverview({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.enrolledCoursesCount,
    required this.completedLessonsCount,
    required this.totalLessonsCount,
    required this.overallPercentage,
    required this.coursesProgress,
  });
}

class StudentCourseProgress {
  final String courseId;
  final String courseTitle;
  final int totalLessons;
  final int completedLessons;
  final double percentage;

  StudentCourseProgress({
    required this.courseId,
    required this.courseTitle,
    required this.totalLessons,
    required this.completedLessons,
    required this.percentage,
  });
}

class LessonProgressItem {
  final String lessonId;
  final String title;
  final int orderIndex;
  final bool completed;
  final int progressPercentage;
  final String? updatedAt;

  LessonProgressItem({
    required this.lessonId,
    required this.title,
    required this.orderIndex,
    required this.completed,
    required this.progressPercentage,
    this.updatedAt,
  });
}

class StudentProgressService {
  static final _supabase = Supabase.instance.client;

  /// Fetches all students and computes their course completion statistics.
  static Future<List<StudentOverview>> fetchStudentsProgress() async {
    try {
      // 1. Fetch student profiles
      List<dynamic> profilesData = [];
      try {
        profilesData = await _supabase
            .from('profiles')
            .select('*')
            .eq('role', 'student');
      } catch (_) {
        try {
          profilesData = await _supabase
              .from('profiles')
              .select('*');
        } catch (_) {
          profilesData = [];
        }
      }

      if (profilesData.isEmpty) {
        return [];
      }

      // 2. Fetch all courses
      List<dynamic> coursesData = [];
      try {
        coursesData = await _supabase
            .from('courses')
            .select('id, title');
      } catch (_) {}

      final Map<String, String> courseTitles = {
        for (var c in coursesData) c['id'].toString(): c['title']?.toString() ?? 'Course'
      };

      // 3. Fetch all lessons to know how many lessons per course
      List<dynamic> lessonsData = [];
      try {
        lessonsData = await _supabase
            .from('lessons')
            .select('id, course_id, title, order_index');
      } catch (_) {}

      final Map<String, List<Map<String, dynamic>>> courseLessonsMap = {};
      for (var l in lessonsData) {
        final cId = l['course_id']?.toString() ?? '';
        courseLessonsMap.putIfAbsent(cId, () => []).add(Map<String, dynamic>.from(l));
      }

      // 4. Fetch enrollments
      List<dynamic> enrollmentsData = [];
      try {
        enrollmentsData = await _supabase
            .from('enrollments')
            .select('user_id, course_id, payment_status');
      } catch (_) {}

      // 5. Fetch all lesson progress
      List<dynamic> progressData = [];
      try {
        progressData = await _supabase
            .from('lesson_progress')
            .select('user_id, lesson_id, completed, progress_percentage, updated_at');
      } catch (_) {}

      // Group lesson progress by user_id -> set of completed lesson_ids
      final Map<String, Set<String>> userCompletedLessons = {};
      for (var p in progressData) {
        final uId = p['user_id']?.toString() ?? '';
        final lId = p['lesson_id']?.toString() ?? '';
        final isCompleted = p['completed'] == true || (p['progress_percentage'] ?? 0) >= 100;
        if (isCompleted) {
          userCompletedLessons.putIfAbsent(uId, () => {}).add(lId);
        }
      }

      // Group enrollments by user_id
      final Map<String, Set<String>> userEnrolledCourses = {};
      for (var e in enrollmentsData) {
        final uId = e['user_id']?.toString() ?? '';
        final cId = e['course_id']?.toString() ?? '';
        if (cId.isNotEmpty) {
          userEnrolledCourses.putIfAbsent(uId, () => {}).add(cId);
        }
      }

      final List<StudentOverview> results = [];

      for (var p in profilesData) {
        final studentId = p['id'].toString();
        final fullName = p['full_name']?.toString() ?? 'Student';
        final email = p['email']?.toString() ?? '';
        final avatarUrl = p['avatar_url']?.toString();

        final enrolledCourseIds = userEnrolledCourses[studentId] ?? {};
        final completedLessonIds = userCompletedLessons[studentId] ?? {};

        // If no explicit enrollment, check if student has any progress in any course
        final activeCourseIds = Set<String>.from(enrolledCourseIds);
        if (activeCourseIds.isEmpty) {
          // Check if any completed lesson matches a course
          for (var entry in courseLessonsMap.entries) {
            for (var l in entry.value) {
              if (completedLessonIds.contains(l['id'].toString())) {
                activeCourseIds.add(entry.key);
                break;
              }
            }
          }
        }

        final List<StudentCourseProgress> coursesProg = [];
        int totalStudentLessons = 0;
        int completedStudentLessons = 0;

        for (var cId in activeCourseIds) {
          final title = courseTitles[cId] ?? 'Course $cId';
          final cLessons = courseLessonsMap[cId] ?? [];
          final totalInCourse = cLessons.length;
          final completedInCourse = cLessons.where((l) => completedLessonIds.contains(l['id'].toString())).length;

          totalStudentLessons += totalInCourse;
          completedStudentLessons += completedInCourse;

          final double pct = totalInCourse > 0 ? (completedInCourse / totalInCourse) * 100 : 0.0;
          coursesProg.add(StudentCourseProgress(
            courseId: cId,
            courseTitle: title,
            totalLessons: totalInCourse,
            completedLessons: completedInCourse,
            percentage: pct,
          ));
        }

        final double overallPct = totalStudentLessons > 0
            ? (completedStudentLessons / totalStudentLessons) * 100
            : 0.0;

        results.add(StudentOverview(
          id: studentId,
          fullName: fullName,
          email: email,
          avatarUrl: avatarUrl,
          enrolledCoursesCount: activeCourseIds.length,
          completedLessonsCount: completedStudentLessons,
          totalLessonsCount: totalStudentLessons,
          overallPercentage: overallPct,
          coursesProgress: coursesProg,
        ));
      }

      return results;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches detailed lesson-by-lesson progress for a student in a course.
  static Future<List<LessonProgressItem>> fetchStudentCourseLessons(
    String studentId,
    String courseId,
  ) async {
    try {
      final lessons = await _supabase
          .from('lessons')
          .select('id, title, order_index')
          .eq('course_id', courseId)
          .order('order_index', ascending: true);

      final lessonIds = lessons.map((l) => l['id'].toString()).toList();

      List<dynamic> progress = [];
      if (lessonIds.isNotEmpty) {
        try {
          progress = await _supabase
              .from('lesson_progress')
              .select('lesson_id, completed, progress_percentage, updated_at')
              .eq('user_id', studentId)
              .inFilter('lesson_id', lessonIds);
        } catch (_) {}
      }

      final Map<String, Map<String, dynamic>> progressMap = {
        for (var p in progress) p['lesson_id'].toString(): Map<String, dynamic>.from(p)
      };

      return lessons.map<LessonProgressItem>((l) {
        final lId = l['id'].toString();
        final p = progressMap[lId];
        return LessonProgressItem(
          lessonId: lId,
          title: l['title']?.toString() ?? 'Lesson',
          orderIndex: (l['order_index'] as num?)?.toInt() ?? 1,
          completed: p?['completed'] == true || (p?['progress_percentage'] ?? 0) >= 100,
          progressPercentage: (p?['progress_percentage'] as num?)?.toInt() ?? 0,
          updatedAt: p?['updated_at']?.toString(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
