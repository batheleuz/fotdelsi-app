import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/features/dropoffs/data/models/pending_drop_off_payment_model.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/pending_payment_card.dart';

/// Ligne de `GET /drop-offs/pending-payment`, telle que le serveur la rend.
Map<String, dynamic> _json({
  required String kind,
  String state = 'AWAITING_PAYMENT',
  String? provider = 'WAVE',
  String? redirectUrl = 'https://pay.wave.com/abc',
}) => {
  'kind': kind,
  'draftId': kind == 'DROP_OFF' ? 'draft-1' : null,
  'paymentId': 'pay-1',
  'customerName': 'Awa Diop',
  'contactPhone': '771234567',
  'amount': 9000,
  'createdAt': '2026-09-09T10:00:00.000Z',
  'state': state,
  'formulaLabel': 'Prêt à ranger 12 kg',
  'provider': provider,
  'redirectUrl': redirectUrl,
  'requestedAt': '2026-09-09T10:00:00.000Z',
  'expiresAt': '2099-01-01T00:00:00.000Z',
};

Widget _host(Map<String, dynamic> json) => MaterialApp(
  home: Scaffold(
    body: PendingPaymentCard(
      payment: PendingDropOffPaymentModel.fromJson(json),
    ),
  ),
);

void main() {
  group('réafficher le QR d\'un paiement en attente', () {
    testWidgets('proposé pour un dépôt', (tester) async {
      // Le cas signalé : l'agent ferme l'assistant avant que le client n'ait
      // payé. Sans ce bouton, la commande restait ici visible et inerte, et il
      // fallait refaire toute la saisie.
      await tester.pumpWidget(_host(_json(kind: 'DROP_OFF')));

      expect(find.text('Afficher le QR Code'), findsOneWidget);
    });

    testWidgets('proposé pour un cycle direct, comme avant', (tester) async {
      await tester.pumpWidget(_host(_json(kind: 'DIRECT_CYCLE')));

      expect(find.text('Afficher le QR Code'), findsOneWidget);
    });

    testWidgets('absent quand le serveur ne donne aucun lien', (tester) async {
      // Un dépôt saisi sans demande de paiement n'a pas de code à montrer.
      // Proposer le bouton ouvrirait une feuille vide.
      await tester.pumpWidget(
        _host(
          _json(
            kind: 'DROP_OFF',
            state: 'NOT_INITIATED',
            provider: null,
            redirectUrl: null,
          ),
        ),
      );

      expect(find.text('Afficher le QR Code'), findsNothing);
    });

    testWidgets('absent une fois le lien expiré', (tester) async {
      // Le serveur n'envoie plus ces lignes, mais une application à jour face à
      // un serveur qui ne l'est pas ne doit pas proposer un code mort.
      await tester.pumpWidget(
        _host(_json(kind: 'DROP_OFF', state: 'PAYMENT_EXPIRED')),
      );

      expect(find.text('Afficher le QR Code'), findsNothing);
    });
  });

  group('affichage de la machine', () {
    testWidgets('affiche le nom de la machine pour un dépôt', (tester) async {
      final json = _json(kind: 'DROP_OFF');
      json['machineName'] = 'Machine 3';
      await tester.pumpWidget(_host(json));

      expect(find.text('(Machine 3)'), findsOneWidget);
    });

    testWidgets('affiche le nom de la machine pour un cycle direct', (tester) async {
      final json = _json(kind: 'DIRECT_CYCLE');
      json['machineName'] = 'Machine 1';
      await tester.pumpWidget(_host(json));

      expect(find.text('(Machine 1)'), findsOneWidget);
    });
  });
}
