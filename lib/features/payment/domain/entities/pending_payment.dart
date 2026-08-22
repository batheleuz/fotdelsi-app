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
    this.machineHeldUntil,
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

  /// Jusqu'à quand la machine est tenue. `null` si elle ne l'est plus.
  ///
  /// À ne pas confondre avec [expiresAt], et c'est précisément la confusion
  /// qu'il faut éviter à l'écran : la réservation dure cinq minutes, le lien
  /// une trentaine. Le bandeau affichait la seconde échéance à côté du mot
  /// « réservée », ce qui se lit comme une machine tenue une demi-heure.
  final DateTime? machineHeldUntil;

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

  /// Temps restant de RÉSERVATION. `null` si la machine n'est plus tenue —
  /// auquel cas il n'y a pas de compte à rebours, il y a un avertissement.
  ///
  /// `machineStillHeld` est un instantané du serveur : l'écran vit plus
  /// longtemps que lui. Rendre zéro à l'échéance figerait le bandeau sur
  /// « moins d'une minute » alors que la machine est déjà repartie ; on rend
  /// `null`, et l'affichage bascule tout seul sur l'avertissement.
  Duration? get holdRemaining {
    final until = machineHeldUntil;
    if (until == null || !machineStillHeld) return null;
    final reste = until.difference(DateTime.now());
    return reste.isNegative ? null : reste;
  }

  @override
  List<Object?> get props => [
    paymentId,
    amount,
    expiresAt,
    machineStillHeld,
    machineHeldUntil,
    machineName,
    formulaLabel,
    checkoutUrl,
  ];
}
