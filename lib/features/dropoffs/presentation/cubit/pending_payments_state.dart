part of 'pending_payments_cubit.dart';

enum PendingPaymentsStatus { initial, loading, success, failure }

final class PendingPaymentsState extends Equatable {
  const PendingPaymentsState({
    this.status = PendingPaymentsStatus.initial,
    this.pending,
    this.error,
  });

  final PendingPaymentsStatus status;

  /// `null` tant qu'aucun chargement n'a abouti — à distinguer d'une liste
  /// vide, qui signifie « tout est encaissé ».
  final List<PendingDropOffPayment>? pending;
  final String? error;

  int get count => pending?.length ?? 0;

  /// Ceux qui réclament un geste : relancer un paiement échoué, ou terminer
  /// une vente jamais encaissée. Sert le compteur d'alerte, alors que [count]
  /// sert le libellé.
  int get needingAction =>
      pending?.where((p) => p.state.needsAction).length ?? 0;

  PendingPaymentsState copyWith({
    PendingPaymentsStatus? status,
    List<PendingDropOffPayment>? pending,
    String? error,
    bool clearError = false,
  }) {
    return PendingPaymentsState(
      status: status ?? this.status,
      pending: pending ?? this.pending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, pending, error];
}
