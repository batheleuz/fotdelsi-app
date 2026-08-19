import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:fotdelsi/core/auth/client_session_store.dart';
import '../../domain/entities/pending_payment.dart';
import '../../domain/repositories/payment_repository.dart';

part 'pending_payments_state.dart';

/// Paiements que le client peut encore honorer.
///
/// Le cas visé est précis : le solde manquait au moment de payer. Le client
/// recharge son compte, revient — et n'avait aucun moyen de reprendre. Relancer
/// un paiement échouait de surcroît sur la réservation posée par sa PROPRE
/// tentative, avec un « machine indisponible » qui accusait à tort quelqu'un
/// d'autre.
///
/// Silencieux en cas d'échec : cette liste est un rattrapage, pas le contenu
/// principal de l'accueil. Un réseau capricieux n'a pas à y faire surgir une
/// erreur par-dessus ce que le client était venu faire.
class ClientPendingPaymentsCubit extends Cubit<ClientPendingPaymentsState> {
  ClientPendingPaymentsCubit(this._repository, this._session)
    : super(const ClientPendingPaymentsState());

  final PaymentRepository _repository;
  final ClientSessionStore _session;

  Future<void> load() async {
    // `GET /me/payments/pending` exige une session client. Sans numéro lié,
    // l'appeler ne rapporterait qu'un 401 — voir `MyCyclesCubit`.
    if (await _session.token() == null) {
      emit(const ClientPendingPaymentsState(payments: []));
      return;
    }

    final result = await _repository.pendingPayments();
    result.fold(
      (_) => emit(state.copyWith(payments: const [])),
      (payments) => emit(
        // Ne garde que ce qui est réellement reprenable : un lien expiré, ou
        // un paiement d'avant leur conservation, mènerait à une page morte.
        state.copyWith(payments: payments.where((p) => p.isResumable).toList()),
      ),
    );
  }

  /// Retire un paiement de la liste, une fois le client parti le régler.
  ///
  /// Le résultat n'est connu que du serveur : on n'invente pas un succès. La
  /// ligne disparaît simplement de l'écran, et le prochain chargement dira la
  /// vérité — confirmé, ou toujours en attente.
  void dismiss(String paymentId) {
    final restants = (state.payments ?? const <PendingPayment>[])
        .where((p) => p.paymentId != paymentId)
        .toList();
    emit(state.copyWith(payments: restants));
  }
}
