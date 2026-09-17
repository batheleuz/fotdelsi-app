import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/widgets/app_confirmation_dialog.dart';

/// iPhone SE — le plus petit écran encore vendu, en points logiques.
const _iphoneSe = Size(375, 667);

/// Le message de suppression de compte, celui qui énumère tout ce qui part.
const _messageLong =
    'Tout sera définitivement effacé de nos serveurs : votre numéro, votre '
    'nom, vos notifications, vos dépôts, vos lavages et vos paiements.\n\n'
    'Y compris ce qui est en cours : un dépôt non encore récupéré, du linge '
    'prêt qui vous attend, un paiement réglé dont le lavage n\'a pas encore '
    'été lancé. La laverie n\'aura plus aucune trace reliant ce linge à votre '
    'numéro.\n\nCette action est irréversible.';

Future<List<bool>> _ouvrir(WidgetTester tester, {double echelle = 1.0}) async {
  final reponses = <bool>[];

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: echelle,
        maxScaleFactor: echelle,
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async => reponses.add(
              await showAppConfirmationDialog(
                context: context,
                title: 'Supprimer mon compte ?',
                message: _messageLong,
                confirmLabel: 'Tout supprimer',
                destructive: true,
              ),
            ),
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
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('les deux boutons restent à l\'écran, même en texte agrandi', (
    tester,
  ) async {
    tester.view.physicalSize = _iphoneSe;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _ouvrir(tester, echelle: 2.0);

    // Le message est long, et c'est voulu : il énumère ce que le client perd.
    // Ce qui ne doit jamais arriver, c'est qu'il pousse « Annuler » hors de
    // l'écran — un client qui hésite doit toujours pouvoir renoncer.
    for (final libelle in ['Annuler', 'Tout supprimer']) {
      final bouton = tester.getRect(find.text(libelle));
      expect(
        bouton.bottom,
        lessThanOrEqualTo(_iphoneSe.height),
        reason: '« $libelle » tombe sous le bord de l\'écran',
      );
      expect(bouton.top, greaterThanOrEqualTo(0));
    }
  });

  testWidgets('« Annuler » renonce vraiment', (tester) async {
    tester.view.physicalSize = _iphoneSe;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final reponses = await _ouvrir(tester, echelle: 2.0);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    // Suppression irréversible : l'abandon doit être l'issue de tout ce qui
    // n'est pas un appui franc sur « Tout supprimer ».
    expect(reponses, [false]);
  });

  testWidgets('le message énonce ce qui est en cours', (tester) async {
    await _ouvrir(tester);

    final texte = tester.widget<Text>(find.text(_messageLong)).data!;
    expect(texte, contains('dépôt non encore récupéré'));
    expect(texte, contains('paiement réglé'));
    expect(texte, contains('irréversible'));
  });
}
