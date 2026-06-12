import '../../domain/entities/machine_start_status.dart';
import '../../domain/entities/session_payment_status.dart';

/// Modèle de la réponse de statut d'une wash-session.
///
/// Miroir exact du DTO backend (`GET /wash-session/{token}/status` et événement
/// WebSocket `session.status`) :
/// `{ sessionId, sessionStatus, paymentStatus, machineStatus, remainTimeSeconds,
///    canRetry, failureReason }`.
class WashSessionStatusModel {
  const WashSessionStatusModel({
    required this.sessionId,
    required this.paymentStatus,
    required this.machineStartStatus,
    required this.remainTimeSeconds,
    required this.canRetry,
    required this.isFinished,
    this.failureReason,
  });

  final String sessionId;
  final SessionPaymentStatus paymentStatus;

  /// Dérivé du `sessionStatus` backend (PENDING|RUNNING|FAILED|DONE).
  final MachineStartStatus machineStartStatus;
  final int remainTimeSeconds;

  /// `true` si paiement confirmé ET session relançable (PENDING|FAILED).
  final bool canRetry;

  /// `true` quand le cycle est terminé (`sessionStatus == DONE`).
  final bool isFinished;
  final String? failureReason;

  factory WashSessionStatusModel.fromJson(Map<String, dynamic> json) {
    final sessionStatus = json['sessionStatus'] as String? ?? 'PENDING';
    return WashSessionStatusModel(
      sessionId: json['sessionId'] as String? ?? '',
      paymentStatus:
          SessionPaymentStatus.fromApi(json['paymentStatus'] as String? ?? 'PENDING'),
      machineStartStatus: MachineStartStatus.fromSessionStatus(sessionStatus),
      remainTimeSeconds: (json['remainTimeSeconds'] as num?)?.toInt() ?? 0,
      canRetry: json['canRetry'] as bool? ?? false,
      isFinished: sessionStatus == 'DONE',
      failureReason: json['failureReason'] as String?,
    );
  }
}
