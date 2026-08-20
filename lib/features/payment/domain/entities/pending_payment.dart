import 'package:equatable/equatable.dart';

/// Un paiement que le client peut encore honorer.
///
/// Répond au cas vécu : le solde manquait au moment de payer. Le client
/// recharge son compte, revient — et n'avait aucun moyen de reprendre. Relancer
/// un paiement échouait de surcroît sur la réservation posée par sa PROPRE
/// tentative, avec un « machine indisponible » qui accusait à tort quelqu'un
/// d'autre.
class PendingPayment extends Equatable {
  const PendingPayment({
    required this.paymentId,
    required this.amount,
    required this.expiresAt,
    required this.machineStillHeld,
    this.machineName,
    this.formulaLabel,
    this.checkoutUrl,
    this.fallbackUrl,
  });

  final String paymentId;
  final int amount;

  /// Instant au-delà duquel le lien n'est plus honorable.
  final DateTime expiresAt;

  /// La machine est-elle encore tenue pour ce client ?
  ///
  /// La réservation dure moins longtemps que le lien : passé ce délai le
  /// paiement reste possible, mais la machine peut avoir été prise. Le client
  /// doit le savoir AVANT de payer, pas après.
  final bool machineStillHeld;

  final String? machineName;
  final String? formulaLabel;

  /// Lien à rouvrir. `null` pour un paiement antérieur à leur conservation —
  /// il n'y a alors rien à proposer.
  final String? checkoutUrl;

  /// Repli d'Orange Money quand Maxit n'est pas installé.
  final String? fallbackUrl;

  bool get isResumable =>
      checkoutUrl != null && DateTime.now().isBefore(expiresAt);

  /// Temps restant pour honorer le lien, jamais négatif.
  Duration get remaining {
    final reste = expiresAt.difference(DateTime.now());
    return reste.isNegative ? Duration.zero : reste;
  }

  @override
  List<Object?> get props => [
    paymentId,
    amount,
    expiresAt,
    machineStillHeld,
    machineName,
    formulaLabel,
    checkoutUrl,
  ];
}
