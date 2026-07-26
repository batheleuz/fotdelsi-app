import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/failures.dart';
import '../entities/payment_provider.dart';
import '../entities/payment_session.dart';

/// Contrat domaine pour les opérations de paiement.
abstract interface class PaymentRepository {
  /// Initie un paiement SOFTPAY.
  ///
  /// - [machineId] : identifiant UUID de la machine
  /// - [provider] : moyen de paiement choisi (Wave / Orange Money)
  /// - [customerFullName] : nom complet du client
  /// - [customerPhone] : numéro mobile money (9 chiffres)
  Future<Either<Failure, PaymentSession>> initiatePayment({
    required String machineId,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
  });

  /// Initie un paiement de dépôt (`purpose: DROP_OFF`) — montant choisi par
  /// l'agent. Le prompt de paiement est envoyé au téléphone du client.
  Future<Either<Failure, void>> initiateDropOffPayment({
    required String draftId,
    required int amount,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
  });
}
