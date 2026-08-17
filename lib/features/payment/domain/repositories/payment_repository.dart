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
  /// Initie un paiement libre-service. Aucun montant : le serveur le calcule
  /// depuis la grille à partir de (formule, capacité de la machine).
  Future<Either<Failure, PaymentSession>> initiatePayment({
    required String machineId,
    required String formulaCode,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,

    /// Vente au comptoir par un agent, pour un client sans application.
    /// Le serveur exigera alors un jeton d'agent valide.
    bool atCounter,
  });

  /// Initie un paiement de dépôt (`purpose: DROP_OFF`). Le montant n'est pas
  /// transmis : le serveur le relit sur le brouillon, où il a été calculé
  /// depuis la grille tarifaire. Le prompt est envoyé au téléphone du client.
  Future<Either<Failure, void>> initiateDropOffPayment({
    required String draftId,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
  });
}
