import 'package:equatable/equatable.dart';

/// Un paiement que le client peut encore honorer.
///
/// Répond au cas vécu : le solde manquait au moment de payer. Le client
/// recharge son compte, revient et reprend le même lien de paiement.
class PendingPayment extends Equatable {
  const PendingPayment({
    required this.paymentId,
    required this.amount,
    required this.expiresAt,
    this.formulaLabel,
    this.checkoutUrl,
    this.fallbackUrl,
  });

  final String paymentId;
  final int amount;

  /// Instant au-delà duquel le lien n'est plus honorable.
  final DateTime expiresAt;

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
    formulaLabel,
    checkoutUrl,
  ];
}
