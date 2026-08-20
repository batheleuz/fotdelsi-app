import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/failures.dart';
import '../entities/payment_delivery.dart';
import '../entities/payment_provider.dart';
import '../entities/payment_session.dart';
import '../entities/pending_payment.dart';

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
  /// Paiements que le client peut encore honorer.
  ///
  /// Sert à lui reproposer un paiement laissé en plan — solde insuffisant,
  /// application fermée — tant que le lien reste valable.
  Future<Either<Failure, List<PendingPayment>>> pendingPayments();

  /// Demande le paiement d'un dépôt.
  ///
  /// Rend la session, et non plus `void` : elle porte le lien de paiement, que
  /// l'agent encode en QR quand le client est devant lui. La jeter interdisait
  /// tout canal autre que la notification.
  Future<Either<Failure, PaymentSession>> initiateDropOffPayment({
    required String draftId,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
    required PaymentDelivery delivery,
  });
}
