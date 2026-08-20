import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/motion/app_motion.dart';
import 'package:fotdelsi/core/motion/entrance.dart';
import 'package:fotdelsi/core/motion/status_transition.dart';

/// Monte [child] avec le réglage système « réduire les animations » à [reduced].
///
/// Le `Column` reproduit l'usage réel — ces widgets sont toujours enfants
/// d'une liste — où la hauteur est libre et donc dictée par le contenu. Sans
/// lui, une boîte vide s'étirerait sur tout l'écran et la hauteur ne
/// mesurerait plus rien.
Widget host({required Widget child, bool reduced = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduced),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Column(mainAxisSize: MainAxisSize.min, children: [child]),
  ),
);

void main() {
  group('AppMotion.delayForIndex', () {
    test('décale les premiers éléments', () {
      expect(AppMotion.delayForIndex(0), Duration.zero);
      expect(AppMotion.delayForIndex(3), AppMotion.stagger * 3);
    });

    test('plafonne le retard des éléments suivants', () {
      // Sans plafond, la trentième ligne d'une file attendrait plus d'une
      // seconde avant d'exister.
      final max = AppMotion.stagger * AppMotion.maxStaggeredItems;
      expect(AppMotion.delayForIndex(30), max);
      expect(AppMotion.delayForIndex(200), max);
    });
  });

  group('EntranceFade', () {
    testWidgets('affiche son enfant une fois entré', (tester) async {
      await tester.pumpWidget(
        host(child: const EntranceFade(child: Text('ok'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('ok'), findsOneWidget);
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    });

    testWidgets('est immédiat quand l\'utilisateur réduit les animations', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(reduced: true, child: const EntranceFade(child: Text('ok'))),
      );
      // Un seul pump : le post-frame callback s'exécute, sans animation ensuite.
      await tester.pump();

      // Ces réglages sont souvent activés pour raisons médicales. Une entrée
      // qui glisse quand même n'est pas un détail de style.
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    });
  });

  group('AnimatedReveal', () {
    testWidgets('montre puis retire son enfant', (tester) async {
      Widget build(bool visible) => host(
        child: AnimatedReveal(visible: visible, child: const Text('bandeau')),
      );

      await tester.pumpWidget(build(true));
      await tester.pumpAndSettle();
      expect(find.text('bandeau'), findsOneWidget);

      await tester.pumpWidget(build(false));
      await tester.pumpAndSettle();

      // AnimatedCrossFade garde les deux enfants montés mais réduit la taille
      // à zéro : c'est la hauteur qui doit avoir disparu.
      expect(tester.getSize(find.byType(AnimatedReveal)).height, 0);
    });

    testWidgets('garde le dernier contenu pendant la disparition', (
      tester,
    ) async {
      // Le parent s'est déjà reconstruit avec un compteur à zéro. Sans
      // mémoire, on verrait « 0 client » s'effacer lentement — un texte que
      // l'utilisateur n'a jamais eu sous les yeux.
      await tester.pumpWidget(
        host(
          child: const AnimatedReveal(visible: true, child: Text('3 clients')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        host(
          child: const AnimatedReveal(visible: false, child: Text('0 client')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('3 clients'), findsOneWidget);
      expect(find.text('0 client'), findsNothing);
    });
  });

  group('StatusTransition', () {
    testWidgets('remplace le contenu quand le statut change', (tester) async {
      Widget build(String statut) => host(
        child: StatusTransition(statusKey: statut, child: Text(statut)),
      );

      await tester.pumpWidget(build('En cours'));
      await tester.pumpAndSettle();
      expect(find.text('En cours'), findsOneWidget);

      await tester.pumpWidget(build('Prêt'));
      await tester.pumpAndSettle();

      expect(find.text('Prêt'), findsOneWidget);
      expect(find.text('En cours'), findsNothing);
    });

    testWidgets('ne rejoue rien quand seul le contenu change', (tester) async {
      // Un compteur qui bouge à l'intérieur d'une carte ne doit pas faire
      // clignoter le badge : c'est la clé de statut qui décide, pas l'enfant.
      Widget build(String texte) => host(
        child: StatusTransition(statusKey: 'PRET', child: Text(texte)),
      );

      await tester.pumpWidget(build('Prêt · 3 pièces'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(build('Prêt · 4 pièces'));
      await tester.pump();

      // Sans transition en cours, l'ancien texte a déjà disparu.
      expect(find.text('Prêt · 4 pièces'), findsOneWidget);
      expect(find.text('Prêt · 3 pièces'), findsNothing);
    });
  });

  group('PulseDot', () {
    testWidgets('reste immobile quand il n\'est pas actif', (tester) async {
      await tester.pumpWidget(
        host(child: const PulseDot(color: Color(0xFF000000), active: false)),
      );
      await tester.pump();

      // Pas de FadeTransition : un statut d'attente qui clignote se lirait
      // comme une alerte.
      expect(find.byType(FadeTransition), findsNothing);
    });

    testWidgets('ne clignote pas si l\'utilisateur réduit les animations', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(reduced: true, child: const PulseDot(color: Color(0xFF000000))),
      );
      await tester.pump();

      // Une boucle infinie est précisément ce que ce réglage vise.
      expect(find.byType(FadeTransition), findsNothing);
    });
  });
}
