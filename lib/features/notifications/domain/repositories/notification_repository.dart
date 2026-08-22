import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/failures.dart';

/// Contrat domaine des notifications push (enregistrement device + ack).
abstract interface class NotificationRepository {
  /// `POST /me/devices` — enregistre le token FCM (client lié requis).
  Future<Either<Failure, void>> registerDevice({
    required String phone,
    required String fcmToken,
    required String platform,
  });

  /// `POST /agent/devices` — enregistre le token FCM d'un agent connecté.
  ///
  /// Pas de numéro : l'agent est identifié par son jeton. C'est le même
  /// appareil et le même token FCM que côté client — seule change la ligne
  /// sous laquelle le serveur le range.
  Future<Either<Failure, void>> registerAgentDevice({
    required String fcmToken,
    required String platform,
  });

  /// `POST /notifications/:id/ack` — acquitte la notification (annule le SMS
  /// de repli côté backend via [smsFallbackId]).
  Future<Either<Failure, void>> ack({
    required String notificationId,
    String? smsFallbackId,
  });
}
