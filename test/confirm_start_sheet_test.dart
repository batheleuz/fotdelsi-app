import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/features/wash_session/presentation/widgets/confirm_start_sheet.dart';

/// Ouvre la feuille et retient ce qu'elle a renvoyé.
Future<List<bool>> ouvrir(WidgetTester tester, {String? machineName}) async {
  final reponses = <bool>[];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              reponses.add(
                await confirmMachineStart(context, machineName: machineName),
              );
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return reponses;
}

void main() {
  testWidgets('ne démarre que sur confirmation explicite', (tester) async {
    // Tout l'objet de cette feuille : un cycle lancé ne s'annule pas, ni côté
    // EQLink ni côté domaine.
    final reponses = await ouvrir(tester);

    await tester.tap(find.text('Démarrer la machine'));
    await tester.pumpAndSettle();

    expect(reponses, [true]);
  });

  testWidgets('refuse quand on renonce', (tester) async {
    final reponses = await ouvrir(tester);

    await tester.tap(find.text('Pas encore'));
    await tester.pumpAndSettle();

    expect(reponses, [false]);
  });

  testWidgets('refuse aussi quand la feuille est simplement refermée', (
    tester,
  ) async {
    // Un glissement, un bouton retour : l'abandon doit être l'issue par
    // défaut. `showModalBottomSheet` renvoie alors `null`, et prendre ce `null`
    // pour un accord lancerait la machine sur un geste d'annulation.
    final reponses = await ouvrir(tester);

    await tester.tapAt(const Offset(20, 20)); // hors de la feuille
    await tester.pumpAndSettle();

    expect(reponses, [false]);
  });

  testWidgets('rappelle la machine concernée quand on la connaît', (
    tester,
  ) async {
    // L'agent en manipule plusieurs : nommer celle qui va tourner est le seul
    // moyen de rattraper une erreur de sélection avant qu'elle coûte un cycle.
    await ouvrir(tester, machineName: 'Lavage 12kg');

    expect(find.text('Lavage 12kg'), findsOneWidget);
  });
}
