part of 'pending_payments_cubit.dart';

final class ClientPendingPaymentsState extends Equatable {
  const ClientPendingPaymentsState({this.payments, this.verifyingPaymentId});

  /// `null` tant qu'aucun chargement n'a abouti — à distinguer d'une liste
  /// vide, qui signifie « rien à reprendre ».
  final List<PendingPayment>? payments;
  final String? verifyingPaymentId;

  /// Le paiement à reproposer : le plus récent, celui que le client vient de
  /// tenter. Le serveur les rend déjà dans cet ordre.
  PendingPayment? get mostRecent {
    final liste = payments ?? const <PendingPayment>[];
    return liste.isEmpty ? null : liste.first;
  }

  ClientPendingPaymentsState copyWith({
    List<PendingPayment>? payments,
    String? verifyingPaymentId,
    bool clearVerifying = false,
  }) => ClientPendingPaymentsState(
    payments: payments ?? this.payments,
    verifyingPaymentId: clearVerifying
        ? null
        : verifyingPaymentId ?? this.verifyingPaymentId,
  );

  @override
  List<Object?> get props => [payments, verifyingPaymentId];
}
