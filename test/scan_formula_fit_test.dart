import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/payment/presentation/pages/scan_page.dart';

/// La règle telle que l'applique `ScanPage._fits` et `pick_formula_sheet`.
///
/// Recopiée ici volontairement : elle décide ce qu'un client peut acheter sur
/// la machine devant lui, et c'est le genre de règle qui se relâche sans qu'on
/// s'en aperçoive.
bool fits(ServiceFormula formula, Machine machine) {
  final wanted = formula.needsWasher ? MachineType.washer : MachineType.dryer;
  return machine.type == wanted &&
      machine.size != null &&
      formula.priceFor(machine.size!) != null;
}

Machine _machine(MachineType type, int? size) => Machine(
  id: 'm-1',
  code: 'WASH_01',
  name: 'Laveuse 1',
  type: type,
  status: MachineStatus.available,
  size: size,
  price: 4000,
);

ServiceFormula _formula({
  required List<ServiceItemKind> items,
  List<int> sizes = const [12],
}) => ServiceFormula(
  code: 'F',
  label: 'Formule',
  items: [
    for (final kind in items)
      ServiceItem(kind: kind, label: '$kind', requiresAgent: false),
  ],
  includesDrying: items.contains(ServiceItemKind.drying),
  requiresAgent: false,
  selfServiceEnabled: true,
  displayOrder: 1,
  prices: [for (final s in sizes) FormulaPrice(sizeKg: s, price: 4000)],
);

void main() {
  group('Ce qu\'une machine scannée sait rendre', () {
    test('accepte un lavage sur une laveuse de la bonne capacité', () {
      final formula = _formula(items: [ServiceItemKind.washing]);

      expect(fits(formula, _machine(MachineType.washer, 12)), isTrue);
    });

    test('refuse une prestation de lavage sur une sécheuse', () {
      // Le motif exact pour lequel le parcours « scan puis prestation » avait
      // été retiré : il promettait un pliage sur une sécheuse.
      final formula = _formula(items: [ServiceItemKind.washing]);

      expect(fits(formula, _machine(MachineType.dryer, 12)), isFalse);
    });

    test('refuse une capacité que la formule ne tarife pas', () {
      // Facturer un montant inventé serait pire que refuser : le client paie
      // un prix qui ne correspond à rien.
      final formula = _formula(items: [ServiceItemKind.washing], sizes: [12]);

      expect(fits(formula, _machine(MachineType.washer, 20)), isFalse);
    });

    test('refuse une machine qui n\'annonce aucune capacité', () {
      final formula = _formula(items: [ServiceItemKind.washing]);

      expect(fits(formula, _machine(MachineType.washer, null)), isFalse);
    });

    test('ScanPage.fits et fitError se comportent de manière cohérente', () {
      final washFormula = _formula(items: [ServiceItemKind.washing], sizes: [12]);
      final washer12 = _machine(MachineType.washer, 12);
      final dryer12 = _machine(MachineType.dryer, 12);
      final washer20 = _machine(MachineType.washer, 20);

      expect(ScanPage.fits(washFormula, washer12), isTrue);
      expect(ScanPage.fitError(washFormula, washer12), isNull);

      expect(ScanPage.fits(washFormula, dryer12), isFalse);
      expect(ScanPage.fitError(washFormula, dryer12), contains('sécheuse'));

      expect(ScanPage.fits(washFormula, washer20), isFalse);
      expect(ScanPage.fitError(washFormula, washer20), contains('20 kg'));
    });
  });
}
