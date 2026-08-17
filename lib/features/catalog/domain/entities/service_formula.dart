import 'package:equatable/equatable.dart';

/// Prestation unitaire composant une formule.
enum ServiceItemKind { washing, drying, folding, ironing }

/// Une brique de la formule, telle que décrite par le catalogue serveur.
class ServiceItem extends Equatable {
  const ServiceItem({
    required this.kind,
    required this.label,
    required this.requiresAgent,
  });

  final ServiceItemKind kind;

  /// Libellé prêt à afficher, fourni par le serveur (pas de traduction locale).
  final String label;

  /// La prestation est réalisée à la main : le linge devra être remis au
  /// comptoir en fin de cycle.
  final bool requiresAgent;

  @override
  List<Object?> get props => [kind, label, requiresAgent];
}

/// Un tarif de la grille : le prix pour une capacité de machine donnée.
class FormulaPrice extends Equatable {
  const FormulaPrice({required this.sizeKg, required this.price});

  final int sizeKg;
  final int price;

  @override
  List<Object?> get props => [sizeKg, price];
}

/// Vendabilité de la formule à l'instant où le catalogue a été chargé.
///
/// Deux drapeaux et non un : le linge n'est pas au même endroit selon le
/// parcours. En libre-service il doit d'abord passer en machine, l'agent doit
/// donc être encore là à la sortie du cycle ; au comptoir il est remis tout de
/// suite. Une formule peut ainsi rester vendable en dépôt alors qu'elle ne
/// l'est plus en libre-service.
///
/// C'est le serveur qui tranche — ces drapeaux servent à ne pas laisser le
/// client aller jusqu'au paiement pour se voir refuser, pas à décider.
class FormulaAvailability extends Equatable {
  const FormulaAvailability({
    this.selfService = true,
    this.dropOff = true,
    this.message,
  });

  /// Achetable en libre-service (app client, vente d'un cycle au comptoir).
  final bool selfService;

  /// Achetable en dépôt — le linge est confié immédiatement.
  final bool dropOff;

  /// Explication à afficher quand l'un des deux est refusé. Porte l'horaire.
  final String? message;

  @override
  List<Object?> get props => [selfService, dropOff, message];
}

/// Formule commerciale du catalogue (« Lavage + Séchage », …).
///
/// Les prix viennent exclusivement du serveur : l'app ne calcule jamais un
/// montant, elle affiche celui de la grille et transmet le couple
/// (formule, capacité). Le serveur retarifie de son côté.
class ServiceFormula extends Equatable {
  const ServiceFormula({
    required this.code,
    required this.label,
    required this.items,
    required this.includesDrying,
    required this.requiresAgent,
    required this.selfServiceEnabled,
    required this.displayOrder,
    required this.prices,
    this.availability = const FormulaAvailability(),
  });

  /// Clé stable transmise au serveur (ex. `LAVAGE_SECHAGE`).
  final String code;
  final String label;
  final List<ServiceItem> items;

  /// Le cycle comporte un second temps : une sécheuse sera à lancer.
  final bool includesDrying;

  /// Le linge devra passer par un agent (pliage / repassage).
  final bool requiresAgent;

  final bool selfServiceEnabled;
  final int displayOrder;
  final List<FormulaPrice> prices;

  /// Disponibilité horaire au moment du chargement du catalogue.
  final FormulaAvailability availability;

  /// Capacités tarifées, croissantes.
  List<int> get sizes => prices.map((p) => p.sizeKg).toList();

  bool includesItem(ServiceItemKind kind) =>
      items.any((item) => item.kind == kind);

  /// Détail des prestations, affiché sous le nom commercial.
  ///
  /// Les noms retenus disent le résultat (« Prêt à porter ») plutôt que le
  /// contenu : c'est cette ligne qui rétablit la précision, sans allonger le
  /// titre. Les libellés viennent du serveur, jamais d'une traduction locale.
  String get composition => items.map((item) => item.label).join(' · ');

  /// Le premier cycle machine attend-il une laveuse ? Détermine quelles
  /// machines proposer pour cette prestation.
  bool get needsWasher => includesItem(ServiceItemKind.washing);

  /// Prix pour cette capacité, ou `null` si la formule n'y est pas proposée.
  int? priceFor(int sizeKg) {
    for (final p in prices) {
      if (p.sizeKg == sizeKg) return p.price;
    }
    return null;
  }

  /// Prix d'entrée de gamme — sert à annoncer « à partir de … ».
  int? get lowestPrice => prices.isEmpty
      ? null
      : prices.map((p) => p.price).reduce((a, b) => a < b ? a : b);

  @override
  List<Object?> get props => [
    code,
    label,
    items,
    includesDrying,
    requiresAgent,
    selfServiceEnabled,
    displayOrder,
    prices,
    availability,
  ];
}
