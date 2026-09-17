import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/catalog/presentation/widgets/formula_card.dart';

/// « Prêt à porter » : lavage, séchage, pliage, repassage — donc une formule
/// qui réclame un agent, et qui se ferme quand il quitte la laverie.
ServiceFormula _pretAPorter({required bool sellable, String? message}) =>
    ServiceFormula(
      code: 'LAVAGE_SECHAGE_PLIAGE_REPASSAGE',
      label: 'Prêt à porter',
      items: const [
        ServiceItem(
          kind: ServiceItemKind.washing,
          label: 'Lavage',
          requiresAgent: false,
        ),
        ServiceItem(
          kind: ServiceItemKind.ironing,
          label: 'Repassage',
          requiresAgent: true,
        ),
      ],
      includesDrying: true,
      requiresAgent: true,
      selfServiceEnabled: true,
      displayOrder: 3,
      prices: const [FormulaPrice(sizeKg: 12, price: 9000)],
      availability: FormulaAvailability(
        selfService: sellable,
        dropOff: sellable,
        message: message,
      ),
    );

Future<int> _tapCount(WidgetTester tester, {required bool available}) async {
  var taps = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FormulaCard(
          formula: _pretAPorter(
            sellable: available,
            message: available ? null : 'Disponible de 9h à 18h.',
          ),
          available: available,
          onTap: () => taps++,
        ),
      ),
    ),
  );

  await tester.tap(find.byType(FormulaCard));
  await tester.pumpAndSettle();
  return taps;
}

void main() {
  group('formule fermée hors présence de l\'agent', () {
    testWidgets('n\'est PAS cliquable', (tester) async {
      // Le défaut signalé le 26 août : la carte était grisée et portait son
      // message, mais le tap passait quand même. Le client traversait le
      // scan et le choix de machine pour se voir refuser au paiement.
      expect(await _tapCount(tester, available: false), 0);
    });

    testWidgets('reste visible, avec son explication', (tester) async {
      // La masquer ferait croire qu'elle n'existe pas, alors qu'elle revient
      // le lendemain : c'est l'horaire de l'agent qui la retient.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormulaCard(
              formula: _pretAPorter(
                sellable: false,
                message: 'Disponible de 9h à 18h.',
              ),
              available: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Prêt à porter'), findsOneWidget);
      expect(find.text('Disponible de 9h à 18h.'), findsOneWidget);
    });

    testWidgets('redevient cliquable quand l\'agent est là', (tester) async {
      expect(await _tapCount(tester, available: true), 1);
    });
  });
}
