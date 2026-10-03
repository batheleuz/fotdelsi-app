import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/features/wash_session/domain/entities/session_payment_status.dart';

void main() {
  test('une confirmation tardive reste un paiement confirme dans app', () {
    expect(
      SessionPaymentStatus.fromApi('LATE_CONFIRMED'),
      SessionPaymentStatus.confirmed,
    );
  });
}
