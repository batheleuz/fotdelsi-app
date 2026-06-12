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
}
