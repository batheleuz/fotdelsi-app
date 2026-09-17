import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/features/dropoffs/data/models/drop_off_model.dart';

Map<String, dynamic> _json({String? receivedAt}) => {
  'id': 'id-1',
  'code': 'A42',
  'customerName': 'Awa Diop',
  'contactPhone': '770000000',
  'status': 'AWAITING_HANDOFF',
  'origin': 'SELF_SERVICE',
  'laundry': {'pieces': 0, 'instructions': ''},
  'receivedAt': receivedAt,
};

void main() {
  group('Date de réception — ne rien inventer', () {
    test('reste nulle quand le serveur n\'en donne aucune', () {
      // L'app comblait l'absence par `DateTime.now()`, ce qui affichait
      // « déposé à l'instant » sur une remise dont le client garde encore son
      // linge. Inventer une date ne rend pas l'écran plus complet, il le rend
      // faux.
      final dropOff = DropOffModel.fromJson(_json());

      expect(dropOff.receivedAt, isNull);
      expect(dropOff.isReceived, isFalse);
      expect(dropOff.receivedLabel, isNull);
    });

    test('annonce le dépôt une fois le linge arrivé', () {
      final dropOff = DropOffModel.fromJson(
        _json(receivedAt: DateTime.now().toUtc().toIso8601String()),
      );

      expect(dropOff.isReceived, isTrue);
      expect(dropOff.receivedLabel, startsWith('déposé'));
    });
  });
}
