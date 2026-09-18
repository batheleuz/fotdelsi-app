import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/features/catalog/domain/entities/drying_duration_tier.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/payment/presentation/widgets/order_recap_card.dart';
import 'package:flutter/material.dart';

void main() {
  const formulaLavageSechage = ServiceFormula(
    code: 'LAVAGE_SECHAGE',
    label: 'Lavage & Séchage',
    items: [
      ServiceItem(
        kind: ServiceItemKind.washing,
        label: 'Lavage',
        requiresAgent: false,
      ),
      ServiceItem(
        kind: ServiceItemKind.drying,
        label: 'Séchage',
        requiresAgent: false,
      ),
    ],
    includesDrying: true,
    requiresAgent: false,
    selfServiceEnabled: true,
    displayOrder: 1,
    prices: [
      FormulaPrice(sizeKg: 12, price: 7000),
      FormulaPrice(sizeKg: 15, price: 8000),
    ],
  );

  const washer12 = Machine(
    id: 'w1',
    code: 'W1',
    name: 'Laveuse 1',
    type: MachineType.washer,
    status: MachineStatus.available,
    price: 7000,
    size: 12,
  );

  const dryer = Machine(
    id: 'd1',
    code: 'D1',
    name: 'Sécheuse 1',
    type: MachineType.dryer,
    status: MachineStatus.available,
    price: 3000,
  );

  group('Self-service drying verification', () {
    test('Formula with drying: lowest price includes default drying tier', () {
      // 12kg base (7000) + default drying tier (45 min = 3000) = 10000
      expect(formulaLavageSechage.lowestPrice, 10000);
    });

    testWidgets('OrderRecapCard displays default drying tier and updates on selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderRecapCard(
              formula: formulaLavageSechage,
              machine: washer12,
              dryingTier: DryingDurationTier.defaultTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lavage & Séchage'), findsOneWidget);
      expect(find.text('12 kg'), findsOneWidget);
      expect(find.text('Séchage : 45 minutes'), findsOneWidget);
      expect(find.text('10 000 FCFA'), findsOneWidget);
    });

    testWidgets('OrderRecapCard displays custom drying tier (15 min) and reflects 8 000 FCFA', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderRecapCard(
              formula: formulaLavageSechage,
              machine: washer12,
              dryingTier: DryingDurationTier.m15,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Séchage : 15 minutes'), findsOneWidget);
      expect(find.text('8 000 FCFA'), findsOneWidget);
    });

    testWidgets('OrderRecapCard on dryer alone displays tier price', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderRecapCard(
              formula: null,
              machine: dryer,
              dryingTier: DryingDurationTier.m30,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sécheuse 1'), findsOneWidget);
      expect(find.text('Séchage seul'), findsOneWidget);
      expect(find.text('Séchage : 30 minutes'), findsOneWidget);
      expect(find.text('2 000 FCFA'), findsOneWidget);
    });
  });
}
