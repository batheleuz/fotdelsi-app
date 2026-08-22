import 'package:equatable/equatable.dart';

import 'service_formula.dart';

/// Horaires d'ouverture de la laverie, tels que le serveur les applique.
///
/// À ne pas confondre avec les heures de présence de l'agent, portées par
/// [FormulaAvailability] sur chaque formule : fermée, la laverie ne vend rien
/// du tout ; ouverte sans agent, elle vend le lavage et le séchage mais pas le
/// pliage ni le repassage.
///
/// C'est le serveur qui tranche — ces valeurs servent à prévenir le client
/// avant qu'il n'aille jusqu'au paiement, pas à décider.
class BusinessHours extends Equatable {
  const BusinessHours({
    this.enabled = false,
    this.opensAt = '',
    this.closesAt = '',
    this.open = true,
  });

  /// L'horaire est-il appliqué ? `false` = ouvert en permanence.
  final bool enabled;

  /// « HH:mm »
  final String opensAt;

  /// « HH:mm »
  final String closesAt;

  /// La laverie est-elle ouverte à l'instant du chargement ?
  final bool open;

  /// Vrai quand il y a une fermeture à annoncer.
  ///
  /// [enabled] est vérifié en plus de [open] : sans horaire appliqué, le
  /// serveur renvoie `open: true` de toute façon, mais un futur défaut
  /// différent ne doit pas faire surgir un bandeau sans plage à afficher.
  bool get isClosed => enabled && !open;

  /// « 10:00 » → « 10h », « 19:30 » → « 19h30 ».
  static String human(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return value;
    final hour = int.tryParse(parts[0]);
    if (hour == null) return value;
    return parts[1] == '00' ? '${hour}h' : '${hour}h${parts[1]}';
  }

  String get opensAtLabel => human(opensAt);
  String get closesAtLabel => human(closesAt);

  factory BusinessHours.fromJson(Map<String, dynamic> json) => BusinessHours(
    enabled: json['enabled'] as bool? ?? false,
    opensAt: json['opensAt'] as String? ?? '',
    closesAt: json['closesAt'] as String? ?? '',
    // Défaut ouvert : un serveur plus ancien, qui ne renvoie pas ce bloc, ne
    // doit pas afficher une laverie fermée.
    open: json['open'] as bool? ?? true,
  );

  @override
  List<Object?> get props => [enabled, opensAt, closesAt, open];
}

/// Ce que renvoie `GET /service-formulas` : l'offre, et l'état d'ouverture au
/// moment où elle a été lue.
class ServiceCatalog extends Equatable {
  const ServiceCatalog({
    required this.formulas,
    this.businessHours = const BusinessHours(),
  });

  final List<ServiceFormula> formulas;
  final BusinessHours businessHours;

  @override
  List<Object?> get props => [formulas, businessHours];
}
