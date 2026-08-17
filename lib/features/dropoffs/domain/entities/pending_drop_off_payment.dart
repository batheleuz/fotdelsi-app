import 'package:equatable/equatable.dart';

/// Où en est l'encaissement d'un dépôt, du point de vue de l'agent.
///
/// Quatre états et non un seul « en attente », parce qu'ils appellent quatre
/// gestes différents. La distinction expiré / échoué compte : un lien expiré
/// n'a jamais été refusé, le client n'a simplement pas payé à temps — ce n'est
/// pas la même chose à lui annoncer.
enum PendingPaymentState {
  /// La demande est partie, le client n'a pas encore payé.
  awaitingPayment,

  /// Le lien de paiement est mort sans avoir servi : il faut refaire la vente.
  paymentExpired,

  /// Paiement refusé, ou anomalie.
  paymentFailed,

  /// Dépôt saisi, encaissement jamais lancé.
  notInitiated;

  static PendingPaymentState fromApi(String? value) => switch (value) {
    'PAYMENT_EXPIRED' => PendingPaymentState.paymentExpired,
    'PAYMENT_FAILED' => PendingPaymentState.paymentFailed,
    'NOT_INITIATED' => PendingPaymentState.notInitiated,
    // Défaut volontaire sur l'attente : un état inconnu venu d'un backend plus
    // récent doit laisser la ligne visible, jamais la faire disparaître.
    _ => PendingPaymentState.awaitingPayment,
  };

  /// Vrai quand l'agent a quelque chose à faire, plutôt qu'à attendre.
  bool get needsAction => this != PendingPaymentState.awaitingPayment;
}

/// Un dépôt saisi mais pas encore payé.
///
/// Entre la saisie et le paiement, un dépôt n'existait nulle part : la file
/// d'attente ne liste que des dépôts déjà payés. L'agent envoyait la demande
/// de paiement, servait le client suivant, et perdait la commande de vue.
class PendingDropOffPayment extends Equatable {
  const PendingDropOffPayment({
    required this.draftId,
    required this.customerName,
    required this.contactPhone,
    required this.amount,
    required this.createdAt,
    required this.state,
    this.formulaCode,
    this.sizeKg,
    this.requestedAt,
    this.expiresAt,
  });

  final String draftId;
  final String customerName;

  /// Forme canonique : 9 chiffres, sans indicatif. Le préfixe est ajouté à
  /// l'affichage.
  final String contactPhone;
  final int amount;

  /// Saisie du dépôt — c'est depuis ce moment que le client attend.
  final DateTime createdAt;
  final PendingPaymentState state;
  final String? formulaCode;
  final int? sizeKg;

  /// Envoi de la demande de paiement. `null` si elle n'a jamais été lancée.
  final DateTime? requestedAt;

  /// Fin de validité du lien de paiement. `null` si rien n'a été lancé.
  final DateTime? expiresAt;

  /// Combien de temps le lien reste valable, ou `null` s'il est mort ou absent.
  Duration? get validFor {
    final deadline = expiresAt;
    if (deadline == null) return null;
    final left = deadline.difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  /// Depuis combien de temps ce dépôt attend.
  Duration get waiting => DateTime.now().difference(createdAt);

  @override
  List<Object?> get props => [
    draftId,
    customerName,
    contactPhone,
    amount,
    createdAt,
    state,
    formulaCode,
    sizeKg,
    requestedAt,
    expiresAt,
  ];
}
