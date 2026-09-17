import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off_status.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/laundry.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/drop_off_timeline.dart';

DropOff _dropOff({
  required String origin,
  required DropOffStatus status,
  DateTime? clientCycleFinishedAt,
  DateTime? startedAt,
  DateTime? readyAt,
}) => DropOff(
  origin: origin,
  id: 'id-1',
  code: 'A42',
  customerName: 'Awa Diop',
  contactPhone: '770000000',
  laundry: const Laundry(pieces: 0, types: []),
  status: status,
  receivedAt: DateTime(2026, 8, 17, 9),
  clientCycleFinishedAt: clientCycleFinishedAt,
  startedAt: startedAt,
  readyAt: readyAt,
);

Future<void> _poser(WidgetTester tester, DropOff dropOff) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: DropOffTimeline(dropOff: dropOff))),
  );
}

void main() {
  group('dépôt né d\'un libre-service', () {
    testWidgets('ne réclame pas un lavage que le client a déjà fait', (
      tester,
    ) async {
      // Le reproche exact : « Lavage lancé » restait décoché alors que le
      // lavage ET le séchage étaient terminés. L'étape ne pouvait
      // structurellement pas se franchir — `assignMachine` interdit tout cycle
      // machine sur un dépôt libre-service, donc `startedAt` n'est pas un
      // lavage mais la prise en charge au comptoir.
      await _poser(
        tester,
        _dropOff(
          origin: 'SELF_SERVICE',
          status: DropOffStatus.awaitingHandoff,
        ),
      );

      expect(find.text('Lavage lancé'), findsNothing);
      expect(find.text('Lavé par le client'), findsOneWidget);
    });

    testWidgets('ne prétend pas avoir reçu un linge encore chez le client', (
      tester,
    ) async {
      // `receivedAt` est posé dès le paiement : « Reçu » se cochait alors que
      // rien n'était arrivé au comptoir.
      await _poser(
        tester,
        _dropOff(
          origin: 'SELF_SERVICE',
          status: DropOffStatus.awaitingHandoff,
        ),
      );

      expect(find.text('Reçu'), findsNothing);
      expect(find.text('Apporté au comptoir'), findsOneWidget);
    });

    testWidgets(
      'coche « Lavé par le client » uniquement quand le cycle est terminé',
      (tester) async {
        // Avant le fix : `receivedAt` (posé au PAIEMENT) cochait cette étape
        // dès l'achat. Désormais c'est `clientCycleFinishedAt` — timestamp réel
        // de fin de cycle renvoyé par le backend — qui fait foi.
        await _poser(
          tester,
          _dropOff(
            origin: 'SELF_SERVICE',
            status: DropOffStatus.awaitingHandoff,
            clientCycleFinishedAt: DateTime(2026, 8, 17, 10, 15),
          ),
        );

        // La date et l'heure ne s'affichent que sur une étape franchie.
        expect(find.text('17 août à 10:15'), findsOneWidget);
      },
    );

    testWidgets(
      '« Lavé par le client » reste non coché si le cycle n\'est pas encore terminé',
      (tester) async {
        await _poser(
          tester,
          _dropOff(
            origin: 'SELF_SERVICE',
            status: DropOffStatus.awaitingHandoff,
            // clientCycleFinishedAt non renseigné → case non cochée
          ),
        );

        expect(find.text('Lavé par le client'), findsOneWidget);
        // Aucun horodatage affiché : le linge n'est pas encore lavé
        expect(find.textContaining('août'), findsNothing);
      },
    );

    testWidgets('coche la remise une fois le linge apporté', (tester) async {
      await _poser(
        tester,
        _dropOff(
          origin: 'SELF_SERVICE',
          status: DropOffStatus.inProgress,
          startedAt: DateTime(2026, 8, 17, 11, 30),
        ),
      );

      // La date et l'heure ne s'affichent que sur une étape franchie.
      expect(find.text('17 août à 11:30'), findsOneWidget);
    });
  });

  group('dépôt confié au comptoir', () {
    testWidgets('garde son parcours agent', (tester) async {
      // L'agent lave lui-même : ces étapes-là restent les siennes.
      await _poser(
        tester,
        _dropOff(origin: 'AGENT', status: DropOffStatus.received),
      );

      expect(find.text('Reçu'), findsOneWidget);
      expect(find.text('Lavage lancé'), findsOneWidget);
      expect(find.text('Lavé par le client'), findsNothing);
    });
  });

  testWidgets('un linge pas encore apporté n\'est pas au stade « Remis »', (
    tester,
  ) async {
    // `awaitingHandoff` manquait au filtrage de l'étape active et retombait sur
    // le repli, qui désignait la DERNIÈRE étape.
    await _poser(
      tester,
      _dropOff(origin: 'SELF_SERVICE', status: DropOffStatus.awaitingHandoff),
    );

    final remis = tester.widget<Text>(find.text('Remis au client'));
    final apporte = tester.widget<Text>(find.text('Apporté au comptoir'));

    // L'étape en cours est la seule mise en gras.
    expect(apporte.style!.fontWeight, FontWeight.w600);
    expect(remis.style!.fontWeight, isNot(FontWeight.w600));
  });
}
