import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/features/dropoffs/data/models/drop_off_model.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off_status.dart';

/// Remise en attente, telle que le serveur la rend.
Map<String, dynamic> _json({
  required String status,
  bool? clientCycleFinished,
}) => {
  'id': 'dropoff-1',
  'code': '4821',
  'creationDay': '2026-08-25',
  'paymentId': 'payment-1',
  'contactPhone': '770000000',
  'customerName': 'Awa Diop',
  'laundry': {'pieces': 5, 'instructions': ''},
  'origin': 'SELF_SERVICE',
  'status': status,
  'withDrying': false,
  'clientCycleFinished': clientCycleFinished,
};

void main() {
  group('prise en charge — le client doit avoir fini son linge', () {
    test('autorisée quand le cycle du client est terminé', () {
      final dropOff = DropOffModel.fromJson(
        _json(status: 'AWAITING_HANDOFF', clientCycleFinished: true),
      );

      expect(dropOff.status, DropOffStatus.awaitingHandoff);
      expect(dropOff.canReceiveFromClient, isTrue);
    });

    test('REFUSÉE pendant que la machine du client tourne', () {
      // C'est la règle même : l'agent ne doit pas pouvoir prendre en charge un
      // linge encore dans un tambour.
      final dropOff = DropOffModel.fromJson(
        _json(status: 'AWAITING_HANDOFF', clientCycleFinished: false),
      );

      expect(dropOff.canReceiveFromClient, isFalse);
    });

    test('REFUSÉE quand le serveur ne se prononce pas', () {
      // Champ absent — une version de serveur antérieure, ou une incohérence.
      // Le défaut est le refus : proposer le geste mènerait à une erreur, et
      // c'est exactement ce que cette règle empêche.
      final dropOff = DropOffModel.fromJson(_json(status: 'AWAITING_HANDOFF'));

      expect(dropOff.clientCycleFinished, isNull);
      expect(dropOff.canReceiveFromClient, isFalse);
    });

    test('ne concerne pas un dépôt déjà pris en charge', () {
      // Le geste n'a plus lieu d'être : il ne doit pas réapparaître au motif
      // que le champ vaut `null`.
      final dropOff = DropOffModel.fromJson(
        _json(status: 'IN_PROGRESS', clientCycleFinished: null),
      );

      expect(dropOff.canReceiveFromClient, isFalse);
    });
  });
}
