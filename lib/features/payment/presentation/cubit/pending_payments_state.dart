part of 'pending_payments_cubit.dart';

final class ClientPendingPaymentsState extends Equatable {
  const ClientPendingPaymentsState({this.payments});

  /// `null` tant qu'aucun chargement n'a abouti — à distinguer d'une liste
  /// vide, qui signifie « rien à reprendre ».
  final List<PendingPayment>? payments;

  /// Le paiement à reproposer : le plus récent, celui que le client vient de
  /// tenter. Le serveur les rend déjà dans cet ordre.
  PendingPayment? get mostRecent {
    final liste = payments ?? const <PendingPayment>[];
    return liste.isEmpty ? null : liste.first;
  }

  ClientPendingPaymentsState copyWith({List<PendingPayment>? payments}) =>
      ClientPendingPaymentsState(payments: payments ?? this.payments);

  @override
  List<Object?> get props => [payments];
}
