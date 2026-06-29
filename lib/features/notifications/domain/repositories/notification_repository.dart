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

  /// `POST /notifications/:id/ack` — acquitte la notification (annule le SMS
  /// de repli côté backend via [smsFallbackId]).
  Future<Either<Failure, void>> ack({
    required String notificationId,
    String? smsFallbackId,
  });
}
