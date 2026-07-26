import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/features/auth/domain/entities/auth_role.dart';

void main() {
  group('AuthRole.fromApi', () {
    test('mappe les rôles backend connus', () {
      expect(AuthRole.fromApi('ADMIN'), AuthRole.admin);
      expect(AuthRole.fromApi('AGENT'), AuthRole.agent);
    });

    test('retourne null pour un rôle inconnu', () {
      expect(AuthRole.fromApi('CLIENT'), isNull);
      expect(AuthRole.fromApi(''), isNull);
    });

    test('apiValue est réversible', () {
      expect(AuthRole.fromApi(AuthRole.agent.apiValue), AuthRole.agent);
      expect(AuthRole.fromApi(AuthRole.admin.apiValue), AuthRole.admin);
    });
  });
}
