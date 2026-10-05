import 'package:evolve_staff/services/admin_users_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminUsersService.parseResponse', () {
    test('parses returned profiles', () {
      final users = AdminUsersService.parseResponse({
        'users': [
          {
            'id': 'user-1',
            'full_name': 'Test User',
            'email': 'test@example.com',
            'role': 'teacher',
          },
        ],
      });

      expect(users.single['id'], 'user-1');
      expect(users.single['role'], 'teacher');
    });

    test('rejects missing user data', () {
      expect(() => AdminUsersService.parseResponse({}), throwsFormatException);
    });

    test('rejects malformed profiles', () {
      expect(
        () => AdminUsersService.parseResponse({
          'users': [
            {'full_name': 'Missing ID'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
