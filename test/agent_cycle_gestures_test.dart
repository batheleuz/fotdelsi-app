import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/features/dropoffs/data/models/drop_off_model.dart';

/// Ce que l'agent peut faire d'un dépôt, maintenant qu'aucune machine ne dit
/// plus qu'elle a fini.
///
/// C'est le parcours qui tournera en production avant les applications
/// publiques : un agent, un APK, et des dépôts à traiter. S'il reste bloqué
/// devant « Séchage lancé — patientez », la laverie s'arrête.

/// Dépôt confié au comptoir, tel que le serveur le rend.
Map<String, dynamic> _dropOff({
  required String status,
  bool withDrying = false,
  String? washCompletedAt,
  String? dryStartedAt,
  String? dryCompletedAt,
  bool awaitingPickup = false,
  String origin = 'AGENT',
}) => {
  'id': 'dropoff-1',
  'code': '4821',
  'creationDay': '2026-09-04',
  'paymentId': 'payment-1',
  'contactPhone': '770000000',
  'customerName': 'Awa Diop',
  'laundry': {'pieces': 5, 'instructions': ''},
  'origin': origin,
  'status': status,
  'withDrying': withDrying,
  'washSessionId': 'session-1',
  'washCompletedAt': washCompletedAt,
  'dryStartedAt': dryStartedAt,
  'dryCompletedAt': dryCompletedAt,
  'awaitingPickup': awaitingPickup,
};

const _uneHeureAvant = '2026-09-04T14:00:00.000Z';

void main() {
  group('dépôt sans séchage', () {
    test('rien à faire tant que le lavage est censé tourner', () {
      final dropOff = DropOffModel.fromJson(_dropOff(status: 'IN_PROGRESS'));

      expect(dropOff.canMarkReady, isFalse);
      expect(dropOff.isCycleRunning, isTrue);
    });

    test('« Marquer prêt » dès que le lavage est présumé fini', () {
      final dropOff = DropOffModel.fromJson(
        _dropOff(
          status: 'IN_PROGRESS',
          washCompletedAt: _uneHeureAvant,
          awaitingPickup: true,
        ),
      );

      expect(dropOff.canMarkReady, isTrue);
      expect(dropOff.isCycleRunning, isFalse);
    });
  });

  group('dépôt avec séchage', () {
    test('propose le séchage une fois le lavage présumé fini', () {
      final dropOff = DropOffModel.fromJson(
        _dropOff(
          status: 'IN_PROGRESS',
          withDrying: true,
          washCompletedAt: _uneHeureAvant,
        ),
      );

      expect(dropOff.canStartDrying, isTrue);
      // Surtout pas : il reste une machine à lancer.
      expect(dropOff.canMarkReady, isFalse);
    });

    test('rien à faire pendant le temps du séchage', () {
      final dropOff = DropOffModel.fromJson(
        _dropOff(
          status: 'IN_PROGRESS',
          withDrying: true,
          washCompletedAt: _uneHeureAvant,
          dryStartedAt: _uneHeureAvant,
        ),
      );

      expect(dropOff.canStartDrying, isFalse);
      expect(dropOff.canMarkReady, isFalse);
    });

    test('« Marquer prêt » sur la fin PRÉSUMÉE du séchage', () {
      // Le point qui bloquait tout : `dryCompletedAt` n'est plus posé par
      // personne — plus aucune machine ne dit qu'elle a fini. L'attendre
      // laissait l'agent devant « Séchage lancé — patientez » jusqu'au délai de
      // grâce, sur un tambour arrêté depuis longtemps.
      final dropOff = DropOffModel.fromJson(
        _dropOff(
          status: 'IN_PROGRESS',
          withDrying: true,
          washCompletedAt: _uneHeureAvant,
          dryStartedAt: _uneHeureAvant,
          awaitingPickup: true,
        ),
      );

      expect(dropOff.canMarkReady, isTrue);
      expect(dropOff.isCycleRunning, isFalse);
    });

    test('« Marquer prêt » aussi sur une fin CONSTATÉE', () {
      // Le jour où EQLink saura répondre, le relevé machine posera de nouveau
      // cette date : la règle doit continuer de l'accepter.
      final dropOff = DropOffModel.fromJson(
        _dropOff(
          status: 'IN_PROGRESS',
          withDrying: true,
          washCompletedAt: _uneHeureAvant,
          dryStartedAt: _uneHeureAvant,
          dryCompletedAt: _uneHeureAvant,
        ),
      );

      expect(dropOff.canMarkReady, isTrue);
    });
  });

  group('remise libre-service', () {
    test('aucun cycle machine à attendre', () {
      // Le lavage a eu lieu sur la session du client : ce dépôt-ci ne porte
      // que du travail manuel.
      final dropOff = DropOffModel.fromJson(
        _dropOff(status: 'IN_PROGRESS', origin: 'SELF_SERVICE'),
      );

      expect(dropOff.canMarkReady, isTrue);
      expect(dropOff.isCycleRunning, isFalse);
    });
  });
}
