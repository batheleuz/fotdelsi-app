import '../../domain/entities/service_formula.dart';

/// DTO de `GET /service-formulas` → entité.
class ServiceFormulaModel {
  const ServiceFormulaModel({
    required this.code,
    required this.label,
    required this.items,
    required this.includesDrying,
    required this.requiresAgent,
    required this.selfServiceEnabled,
    required this.displayOrder,
    required this.prices,
    required this.availability,
  });

  final String code;
  final String label;
  final List<ServiceItem> items;
  final bool includesDrying;
  final bool requiresAgent;
  final bool selfServiceEnabled;
  final int displayOrder;
  final List<FormulaPrice> prices;
  final FormulaAvailability availability;

  factory ServiceFormulaModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? const []);
    final rawPrices = (json['prices'] as List<dynamic>? ?? const []);

    return ServiceFormulaModel(
      code: json['code'] as String,
      label: json['label'] as String,
      items: rawItems
          .map((e) => _item(e as Map<String, dynamic>))
          .whereType<ServiceItem>()
          .toList(),
      includesDrying: json['includesDrying'] as bool? ?? false,
      requiresAgent: json['requiresAgent'] as bool? ?? false,
      selfServiceEnabled: json['selfServiceEnabled'] as bool? ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      prices: rawPrices
          .map(
            (e) => FormulaPrice(
              sizeKg: ((e as Map<String, dynamic>)['sizeKg'] as num).toInt(),
              price: (e['price'] as num).toInt(),
            ),
          )
          .toList(),
      availability: _availability(json['availability']),
    );
  }

  ServiceFormula toEntity() => ServiceFormula(
    code: code,
    label: label,
    items: items,
    includesDrying: includesDrying,
    requiresAgent: requiresAgent,
    selfServiceEnabled: selfServiceEnabled,
    displayOrder: displayOrder,
    prices: prices,
    availability: availability,
  );

  /// Absent d'une version antérieure du backend : on suppose disponible.
  /// Le serveur refusera de toute façon ce qui ne doit pas être vendu — ce
  /// champ n'est là que pour l'affichage.
  static FormulaAvailability _availability(Object? raw) {
    if (raw is! Map<String, dynamic>) return const FormulaAvailability();
    return FormulaAvailability(
      selfService: raw['selfService'] as bool? ?? true,
      dropOff: raw['dropOff'] as bool? ?? true,
      message: raw['message'] as String?,
    );
  }

  /// Une prestation inconnue de cette version de l'app est ignorée plutôt que
  /// de faire échouer tout le catalogue : le serveur peut en introduire une
  /// nouvelle avant que les téléphones soient mis à jour.
  static ServiceItem? _item(Map<String, dynamic> json) {
    final kind = switch (json['code'] as String?) {
      'WASHING' => ServiceItemKind.washing,
      'DRYING' => ServiceItemKind.drying,
      'FOLDING' => ServiceItemKind.folding,
      'IRONING' => ServiceItemKind.ironing,
      _ => null,
    };
    if (kind == null) return null;

    return ServiceItem(
      kind: kind,
      label: json['label'] as String? ?? '',
      requiresAgent: json['requiresAgent'] as bool? ?? false,
    );
  }
}
