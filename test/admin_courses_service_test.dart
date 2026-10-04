import 'package:evolve_staff/services/admin_courses_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminCoursesService.parseResponse', () {
    test('parses published and draft courses', () {
      final courses = AdminCoursesService.parseResponse({
        'courses': [
          {'id': 'course-1', 'title': 'Published', 'is_published': true},
          {'id': 'course-2', 'title': 'Draft', 'is_published': false},
        ],
      });

      expect(courses, hasLength(2));
      expect(courses.last['is_published'], false);
    });

    test('rejects malformed course records', () {
      expect(
        () => AdminCoursesService.parseResponse({
          'courses': [
            {'id': 'course-1', 'title': 'Missing status'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
