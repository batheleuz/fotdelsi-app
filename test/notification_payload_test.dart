import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/features/notifications/domain/entities/notification_kind.dart';
import 'package:fotdelsi/features/notifications/domain/entities/notification_payload.dart';

void main() {
  group('NotificationPayload.fromData', () {
    test('mappe un PAYMENT_REQUEST avec URLs', () {
      final p = NotificationPayload.fromData({
        'kind': 'PAYMENT_REQUEST',
        'notificationId': 'n1',
        'smsFallbackId': 's1',
        'primaryUrl': 'https://pay.wave.com/x',
        'fallbackUrl': 'https://om/x',
      });
      expect(p.kind, NotificationKind.paymentRequest);
      expect(p.notificationId, 'n1');
      expect(p.smsFallbackId, 's1');
      expect(p.primaryUrl, 'https://pay.wave.com/x');
      expect(p.fallbackUrl, 'https://om/x');
    });

    test('mappe WASH_READY avec dropOffId, sans smsFallbackId', () {
      final p = NotificationPayload.fromData({
        'kind': 'WASH_READY',
        'notificationId': 'n2',
        'dropOffId': 'd2',
      });
      expect(p.kind, NotificationKind.washReady);
      expect(p.dropOffId, 'd2');
      expect(p.smsFallbackId, isNull);
    });

    test('kind inconnu ou absent → unknown', () {
      expect(NotificationPayload.fromData({}).kind, NotificationKind.unknown);
      expect(
        NotificationPayload.fromData({'kind': 'FOO'}).kind,
        NotificationKind.unknown,
      );
    });
  });
}
