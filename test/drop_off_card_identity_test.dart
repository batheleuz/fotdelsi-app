import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/features/dropoffs/data/models/drop_off_model.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/drop_off_queue_card.dart';

/// Remise en attente, telle que le serveur la rend.
Map<String, dynamic> _json({
  required String code,
  required String phone,
  String name = 'Mor Diop',
  int quantity = 1,
  int cyclesStarted = 0,
}) => {
  'id': 'dropoff-$code',
  'code': code,
  'creationDay': '2026-09-04',
  'paymentId': 'payment-$code',
  'contactPhone': phone,
  'customerName': name,
  'laundry': {'pieces': 0, 'instructions': ''},
  'origin': 'SELF_SERVICE',
  'status': 'AWAITING_HANDOFF',
  'withDrying': true,
  'clientCycleFinished': true,
  'quantity': quantity,
  'cyclesStarted': cyclesStarted,
};

Widget _host(List<Widget> cards) => MaterialApp(
  home: Scaffold(body: ListView(children: cards)),
);

void main() {
  group('carte de remise — le numéro identifie, pas le nom', () {
    testWidgets('affiche le numéro sous le nom', (tester) async {
      await tester.pumpWidget(
        _host([
          DropOffQueueCard(
            dropOff: DropOffModel.fromJson(
              _json(code: 'HXX6', phone: '772128245'),
            ),
          ),
        ]),
      );

      expect(find.text('Mor Diop'), findsOneWidget);
      // Groupé, et non neuf chiffres collés : l'agent le lit à l'oral pour
      // joindre le client.
      expect(find.text('77 212 82 45'), findsOneWidget);
    });

    testWidgets('distingue deux clients qui portent le même nom', (
      tester,
    ) async {
      // Le cas vécu : cinq remises affichées « Mor Diop », dont une appartenant
      // à un autre numéro. Rien à l'écran ne permettait de le voir, ni ici ni
      // au moment de rendre le linge.
      await tester.pumpWidget(
        _host([
          DropOffQueueCard(
            dropOff: DropOffModel.fromJson(
              _json(code: 'HXX6', phone: '772128245'),
            ),
          ),
          DropOffQueueCard(
            dropOff: DropOffModel.fromJson(
              _json(code: 'CYWP', phone: '775982667'),
            ),
          ),
        ]),
      );

      expect(find.text('Mor Diop'), findsNWidgets(2));
      expect(find.text('77 212 82 45'), findsOneWidget);
      expect(find.text('77 598 26 67'), findsOneWidget);
    });

    testWidgets('ne laisse pas de ligne vide sans numéro', (tester) async {
      await tester.pumpWidget(
        _host([
          DropOffQueueCard(
            dropOff: DropOffModel.fromJson(_json(code: 'ABCD', phone: '')),
          ),
        ]),
      );

      expect(find.text('Mor Diop'), findsOneWidget);
      expect(find.textContaining('  '), findsNothing);
    });

    testWidgets('affiche la progression d’un achat multiple', (tester) async {
      await tester.pumpWidget(
        _host([
          DropOffQueueCard(
            dropOff: DropOffModel.fromJson(
              _json(
                code: 'MULT',
                phone: '771234567',
                quantity: 2,
                cyclesStarted: 1,
              ),
            ),
          ),
        ]),
      );

      expect(find.text('2 cycles · 1/2 lancés'), findsOneWidget);
    });
  });
}
