import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/features/dropoffs/presentation/widgets/cycle_not_finished_notice.dart';

/// Reproduit l'emplacement REEL de l'encart : la `bottomNavigationBar` d'un
/// Scaffold.
///
/// C'est ce détail qui a cassé l'écran. Le Scaffold y pose des contraintes
/// LÂCHES sur toute la hauteur disponible : tout ce qui n'a pas de hauteur
/// propre les remplit jusqu'en haut, par-dessus l'AppBar et le contenu. Un test
/// qui aurait rendu l'encart seul, dans un `Center`, n'aurait rien vu.
Future<void> _pumpInBottomBar(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        appBar: null,
        body: Center(child: Text('contenu de la page')),
        bottomNavigationBar: SafeArea(
          minimum: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: CycleNotFinishedNotice(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('reste une barre basse et ne recouvre pas l\'écran', (
    tester,
  ) async {
    await _pumpInBottomBar(tester);

    final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final notice = tester.getSize(find.byType(CycleNotFinishedNotice)).height;

    // Le seuil est large à dessein : ce test ne fige pas une maquette, il
    // attrape l'encart qui s'étire sur toute la hauteur. Au moment du bug il
    // occupait la totalité de l'écran.
    expect(
      notice,
      lessThan(screen / 3),
      reason: 'l\'encart s\'étire au lieu de tenir en bas de page',
    );
  });

  testWidgets('laisse le contenu de la page visible', (tester) async {
    // Symptôme direct du bug : la page entière avait disparu derrière
    // l'encart.
    await _pumpInBottomBar(tester);

    expect(find.text('contenu de la page'), findsOneWidget);
  });

  testWidgets('dit pourquoi le geste est indisponible', (tester) async {
    await _pumpInBottomBar(tester);

    expect(find.text('Le cycle du client n\'est pas terminé'), findsOneWidget);
    expect(find.textContaining('dès la fin du cycle'), findsOneWidget);
  });
}
