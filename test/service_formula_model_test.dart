import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/features/catalog/data/models/service_formula_model.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';

/// Échantillon capturé sur la réponse réelle de `GET /service-formulas`.
/// Sert de contrat : si le backend change la forme du JSON, ce test casse.
const _realApiJson = '''
{
  "code": "LAVAGE_SECHAGE_PLIAGE",
  "label": "Lavage + Séchage + Pliage",
  "items": [
    { "code": "WASHING", "label": "Lavage",  "requiresAgent": false },
    { "code": "DRYING",  "label": "Séchage", "requiresAgent": false },
    { "code": "FOLDING", "label": "Pliage",  "requiresAgent": true }
  ],
  "includesDrying": true,
  "requiresAgent": true,
  "selfServiceEnabled": true,
  "displayOrder": 3,
  "prices": [
    { "sizeKg": 12, "price": 9000 },
    { "sizeKg": 15, "price": 10000 },
    { "sizeKg": 20, "price": 12000 }
  ]
}
''';

/// Réponse d'un backend qui applique un horaire de présence agent.
const _unavailableJson = '''
{
  "code": "PRET_A_RANGER",
  "label": "Prêt à ranger",
  "items": [
    { "code": "WASHING", "label": "Lavage",  "requiresAgent": false },
    { "code": "FOLDING", "label": "Pliage",  "requiresAgent": true }
  ],
  "includesDrying": true,
  "requiresAgent": true,
  "selfServiceEnabled": true,
  "displayOrder": 3,
  "prices": [{ "sizeKg": 12, "price": 9000 }],
  "availability": {
    "selfService": false,
    "dropOff": true,
    "message": "Pliage et repassage de 9h à 21h — dernière commande en libre-service à 19h30."
  }
}
''';

void main() {
  group('ServiceFormulaModel', () {
    late ServiceFormula formula;

    setUp(() {
      final json = jsonDecode(_realApiJson) as Map<String, dynamic>;
      formula = ServiceFormulaModel.fromJson(json).toEntity();
    });

    test('parse la réponse réelle du backend', () {
      expect(formula.code, 'LAVAGE_SECHAGE_PLIAGE');
      expect(formula.label, 'Lavage + Séchage + Pliage');
      expect(formula.includesDrying, isTrue);
      expect(formula.requiresAgent, isTrue);
      expect(formula.displayOrder, 3);
    });

    test('restitue la grille tarifaire de l\'affiche', () {
      expect(formula.priceFor(12), 9000);
      expect(formula.priceFor(15), 10000);
      expect(formula.priceFor(20), 12000);
      expect(formula.sizes, [12, 15, 20]);
      expect(formula.lowestPrice, 9000);
    });

    test('retourne null pour une capacité non tarifée', () {
      // L'écran ne doit jamais afficher un prix inventé.
      expect(formula.priceFor(8), isNull);
    });

    test('identifie les prestations réalisées par un agent', () {
      final agentItems = formula.items.where((i) => i.requiresAgent).toList();
      expect(agentItems.map((i) => i.kind), [ServiceItemKind.folding]);
    });

    test('ignore une prestation inconnue sans perdre le reste', () {
      // Le serveur peut introduire une prestation avant la mise à jour des
      // téléphones : le catalogue doit rester exploitable.
      final json = jsonDecode(_realApiJson) as Map<String, dynamic>;
      (json['items'] as List<dynamic>).add({
        'code': 'PARFUMAGE',
        'label': 'Parfumage',
        'requiresAgent': true,
      });

      final parsed = ServiceFormulaModel.fromJson(json).toEntity();

      expect(parsed.items, hasLength(3));
      expect(parsed.priceFor(15), 10000);
    });
  });

  group('ServiceFormulaModel — disponibilité horaire', () {
    test('lit les deux drapeaux et le message', () {
      final json = jsonDecode(_unavailableJson) as Map<String, dynamic>;
      final formula = ServiceFormulaModel.fromJson(json).toEntity();

      // Distinction volontaire : le linge d'un dépôt est déjà au comptoir,
      // celui d'un libre-service doit encore passer en machine.
      expect(formula.availability.selfService, isFalse);
      expect(formula.availability.dropOff, isTrue);
      expect(formula.availability.message, contains('19h30'));
    });

    test('suppose disponible si le backend ne renvoie rien', () {
      // Compatibilité descendante : une app à jour face à un backend qui ne
      // connaît pas encore le champ ne doit pas masquer tout le catalogue.
      // Le serveur refusera de toute façon ce qui ne doit pas être vendu.
      final json = jsonDecode(_realApiJson) as Map<String, dynamic>;
      final formula = ServiceFormulaModel.fromJson(json).toEntity();

      expect(formula.availability.selfService, isTrue);
      expect(formula.availability.dropOff, isTrue);
      expect(formula.availability.message, isNull);
    });
  });
}
