import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/features/dropoffs/data/models/pending_drop_off_payment_model.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/pending_drop_off_payment.dart';

Map<String, dynamic> json({String? state, String? requestedAt}) => {
  'draftId': 'draft-1',
  'customerName': 'Awa Diop',
  'contactPhone': '771234567',
  'amount': 9000,
  'createdAt': '2026-08-09T10:00:00.000Z',
  'state': state,
  'formulaCode': 'PRET_A_RANGER',
  'sizeKg': 12,
  'requestedAt': requestedAt,
};

void main() {
  group('PendingPaymentState.fromApi', () {
    test('reconnaît les quatre états du backend', () {
      expect(
        PendingPaymentState.fromApi('AWAITING_PAYMENT'),
        PendingPaymentState.awaitingPayment,
      );
      expect(
        PendingPaymentState.fromApi('PAYMENT_EXPIRED'),
        PendingPaymentState.paymentExpired,
      );
      expect(
        PendingPaymentState.fromApi('PAYMENT_FAILED'),
        PendingPaymentState.paymentFailed,
      );
      expect(
        PendingPaymentState.fromApi('NOT_INITIATED'),
        PendingPaymentState.notInitiated,
      );
    });

    test('retombe sur l\'attente pour un état inconnu', () {
      // Un backend plus récent ne doit pas faire disparaître une ligne : le
      // linge est au comptoir même si l'app ne sait pas nommer son état.
      expect(
        PendingPaymentState.fromApi('ETAT_FUTUR'),
        PendingPaymentState.awaitingPayment,
      );
      expect(
        PendingPaymentState.fromApi(null),
        PendingPaymentState.awaitingPayment,
      );
    });

    test('ne signale une action que pour ce qui en réclame une', () {
      // Un client en train de payer n'est pas une alerte : le compter en rouge
      // apprendrait à l'agent à ignorer le badge.
      expect(PendingPaymentState.awaitingPayment.needsAction, isFalse);
      expect(PendingPaymentState.paymentExpired.needsAction, isTrue);
      expect(PendingPaymentState.paymentFailed.needsAction, isTrue);
      expect(PendingPaymentState.notInitiated.needsAction, isTrue);
    });
  });

  group('PendingDropOffPaymentModel', () {
    test('lit une ligne complète', () {
      final p = PendingDropOffPaymentModel.fromJson(
        json(state: 'PAYMENT_FAILED', requestedAt: '2026-08-09T10:05:00.000Z'),
      );

      expect(p.draftId, 'draft-1');
      expect(p.customerName, 'Awa Diop');
      expect(p.contactPhone, '771234567');
      expect(p.amount, 9000);
      expect(p.state, PendingPaymentState.paymentFailed);
      expect(p.sizeKg, 12);
      expect(p.requestedAt, isNotNull);
    });

    test('accepte une demande de paiement jamais envoyée', () {
      final p = PendingDropOffPaymentModel.fromJson(
        json(state: 'NOT_INITIATED'),
      );

      expect(p.requestedAt, isNull);
      expect(p.state, PendingPaymentState.notInitiated);
    });

    test('lit la fin de validité du lien', () {
      final raw = json(state: 'AWAITING_PAYMENT')
        ..['expiresAt'] = DateTime.now()
            .toUtc()
            .add(const Duration(hours: 2))
            .toIso8601String();

      final p = PendingDropOffPaymentModel.fromJson(raw);

      expect(p.expiresAt, isNotNull);
      expect(p.validFor, isNotNull);
      expect(p.validFor!.inMinutes, greaterThan(100));
    });

    test('ne compte aucun temps restant sur un lien déjà mort', () {
      // Une durée négative afficherait « expire dans -3 h ».
      final raw = json(state: 'PAYMENT_EXPIRED')
        ..['expiresAt'] = DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 3))
            .toIso8601String();

      expect(PendingDropOffPaymentModel.fromJson(raw).validFor, isNull);
    });

    test('survit à une date de création absente', () {
      // Plutôt que de lever : un dépôt dont le linge est au comptoir ne doit
      // pas disparaître de l'écran pour un champ manquant.
      final raw = json()..remove('createdAt');

      expect(() => PendingDropOffPaymentModel.fromJson(raw), returnsNormally);
    });
  });
}
