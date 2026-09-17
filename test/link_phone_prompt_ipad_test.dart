import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/features/client_auth/presentation/widgets/link_phone_prompt.dart';

/// iPad Pro 11" en portrait, en points logiques — l'appareil sur lequel la
/// revue App Store a constaté que « Plus tard » ne répondait pas.
const _ipadPro11 = Size(834, 1194);

Future<void> _ouvrir(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      // Texte agrandi, comme le règlent beaucoup d'utilisateurs — et comme
      // l'appareil de revue d'Apple. C'est ce qui fait déborder le contenu
      // au-delà du plafond de hauteur de la feuille : à taille standard, le
      // bug ne se voit pas.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 2.0,
        maxScaleFactor: 2.0,
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => LinkPhonePrompt.maybeShow(context),
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    serviceLocator.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
  });

  tearDown(() => serviceLocator.reset());

  testWidgets('« Plus tard » reste dans la feuille sur un écran d\'iPad', (
    tester,
  ) async {
    tester.view.physicalSize = _ipadPro11;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _ouvrir(tester);

    // La feuille modale est plafonnée à 9/16 de la hauteur d'écran tant qu'on
    // ne demande pas `isScrollControlled`. Le contenu qui dépasse est rogné :
    // le bouton existe, il est même à moitié visible, mais sa moitié basse ne
    // reçoit plus les touchers. C'est ce qu'a vu la revue App Store.
    final feuille = tester.getRect(find.byType(BottomSheet));
    final bouton = tester.getRect(find.text('Plus tard'));

    expect(
      bouton.bottom,
      lessThanOrEqualTo(feuille.bottom),
      reason: '« Plus tard » déborde de la feuille : il ne sera pas cliquable',
    );
    expect(
      bouton.bottom,
      lessThanOrEqualTo(_ipadPro11.height),
      reason: '« Plus tard » tombe sous le bord de l\'écran',
    );
  });

  testWidgets('un appui sur « Plus tard » ferme la feuille et retient le choix', (
    tester,
  ) async {
    tester.view.physicalSize = _ipadPro11;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _ouvrir(tester);

    // « Ne plus afficher » sert de témoin : la préférence n'est écrite que si
    // la feuille s'est fermée PAR le bouton. Un toucher qui tombe à côté
    // atteint le voile et referme la feuille sans résultat — indiscernable à
    // l'œil, mais le choix du client est perdu.
    await tester.tap(find.text('Ne plus afficher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();

    expect(find.text('Plus tard'), findsNothing);
    expect(
      serviceLocator<SharedPreferences>().getBool(
        'link_phone_prompt_dismissed',
      ),
      isTrue,
    );
  });
}
