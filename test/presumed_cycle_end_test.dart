import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/features/wash_session/domain/entities/wash_cycle.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/confirm_pickup_sheet.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/start_command_sent_sheet.dart';

/// Ce que l'application dit quand plus aucune machine ne sait dire ce qu'elle
/// fait.
///
/// EQLink ne rend ni l'état réel d'une machine ni son temps restant, et
/// « démarrer » ne lance pas le tambour : cela crédite une pièce, et c'est la
/// personne devant la machine qui appuie ensuite sur son écran. Ces deux
/// feuilles portent tout ce qui reste — la consigne, et la confirmation.

/// Ouvre une feuille depuis un bouton, comme le fait un vrai écran.
Future<void> _open(
  WidgetTester tester,
  Future<void> Function(BuildContext) show,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => show(context),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  group('commande de démarrage envoyée', () {
    testWidgets('donne les deux gestes, dans l\'ordre', (tester) async {
      // Sans le second, la pièce est créditée et rien ne tourne — personne ne
      // le voit côté serveur, et le client attend devant une machine à
      // l'arrêt.
      await _open(
        tester,
        (context) => showStartCommandSent(context, machineName: 'Laveuse 03'),
      );

      expect(find.text('Commande de démarrage envoyée'), findsOneWidget);
      expect(find.text('Laveuse 03'), findsOneWidget);
      expect(
        find.text('Mettez votre linge à l\'intérieur de la machine.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Appuyez sur le bouton Démarrer sur l\'écran de la machine.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('parle de la sécheuse au second temps', (tester) async {
      // La laveuse est arrêtée depuis longtemps : nommer le mauvais geste
      // enverrait le client devant la mauvaise machine.
      await _open(
        tester,
        (context) => showStartCommandSent(
          context,
          machineName: 'Sécheuse 01',
          drying: true,
        ),
      );

      expect(
        find.text('Mettez votre linge dans la sécheuse.'),
        findsOneWidget,
      );
    });

    testWidgets('annonce une durée plancher, pas une estimation', (
      tester,
    ) async {
      // C'est la seule chose que le parc garantisse. Promettre une fin précise
      // demanderait un capteur qui n'existe plus.
      await _open(tester, (context) => showStartCommandSent(context));

      expect(
        find.textContaining('au moins 27 minutes'),
        findsOneWidget,
      );
    });
  });

  group('confirmation de récupération', () {
    testWidgets('ne termine le cycle que sur un oui explicite', (tester) async {
      // Ce geste clôt le cycle et rien ne le rouvre : la commande passe en
      // historique, le code de remise est délivré, la machine est rendue.
      final reponses = <bool>[];
      await _open(tester, (context) async {
        reponses.add(await confirmLaundryPickup(context));
      });

      await tester.tap(find.text('Oui, j\'ai récupéré mon linge'));
      await tester.pumpAndSettle();

      expect(reponses, [true]);
    });

    testWidgets('refuse quand on renonce', (tester) async {
      final reponses = <bool>[];
      await _open(tester, (context) async {
        reponses.add(await confirmLaundryPickup(context));
      });

      await tester.tap(find.text('Pas encore'));
      await tester.pumpAndSettle();

      expect(reponses, [false]);
    });

    testWidgets('refuse aussi quand la feuille est simplement refermée', (
      tester,
    ) async {
      // Un glissement, un bouton retour : `showModalBottomSheet` renvoie alors
      // `null`, et le prendre pour un accord terminerait un cycle qui tourne
      // peut-être encore.
      final reponses = <bool>[];
      await _open(tester, (context) async {
        reponses.add(await confirmLaundryPickup(context));
      });

      await tester.tapAt(const Offset(20, 20)); // hors de la feuille
      await tester.pumpAndSettle();

      expect(reponses, [false]);
    });

    testWidgets('pose la question du réel, pas celle du bouton', (
      tester,
    ) async {
      // La notification annonce une fin PRÉSUMÉE : le tambour peut encore
      // tourner. « Avez-vous confirmé ? » n'aurait aucun sens ; « votre linge
      // est-il sorti ? » se vérifie d'un regard.
      await _open(tester, (context) => confirmLaundryPickup(context));

      expect(
        find.text('Votre linge est-il sorti de la machine ?'),
        findsOneWidget,
      );
      expect(find.textContaining('Si le cycle tourne encore'), findsOneWidget);
    });
  });

  group('état du cycle', () {
    test('le statut seul ne suffit pas à reconnaître un linge qui attend', () {
      // La session reste `RUNNING` : c'est le drapeau du serveur qui fait la
      // différence, exactement comme pour le temps mort avant le séchage.
      expect(CycleState.fromApi('RUNNING'), CycleState.running);
      expect(
        CycleState.fromApi('RUNNING', awaitingPickup: true),
        CycleState.awaitingPickup,
      );
    });

    test('récupérer son linge réclame un geste', () {
      // C'est ce geste, et lui seul, qui termine un cycle depuis qu'aucune
      // machine ne sait le dire : le compteur d'alerte doit le porter.
      expect(CycleState.awaitingPickup.needsAction, isTrue);
      expect(CycleState.running.needsAction, isFalse);
    });

    test('le séchage à lancer prime sur le linge à récupérer', () {
      // Les deux drapeaux ne coexistent pas côté serveur, mais l'ordre doit
      // rester explicite : tant qu'il reste une machine à lancer, ce n'est pas
      // la fin du cycle.
      expect(
        CycleState.fromApi(
          'RUNNING',
          canStartDrying: true,
          awaitingPickup: true,
        ),
        CycleState.dryingToStart,
      );
    });
  });
}
