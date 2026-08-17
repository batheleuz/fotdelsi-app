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
    required this.withDrying,
    required this.canStartDrying,
    required this.isDrying,
    this.handoffCode,
    this.failureReason,
  });

  final String sessionId;
  final SessionPaymentStatus paymentStatus;

  /// Dérivé du `sessionStatus` backend (PENDING|RUNNING|FAILED|DONE).
  final MachineStartStatus machineStartStatus;

  /// `null` tant que la machine n'a pas annoncé de durée : EQLink ne la
  /// donne pas au démarrage. Distinct de zéro, qui signifierait « fini ».
  final int? remainTimeSeconds;

  /// `true` si paiement confirmé ET session relançable (PENDING|FAILED).
  final bool canRetry;

  /// `true` quand le cycle est terminé (`sessionStatus == DONE`).
  final bool isFinished;

  /// La prestation payée comporte un séchage : le cycle a deux temps.
  final bool withDrying;

  /// Lavage fini, sécheuse pas encore lancée → l'app propose « Démarrer le séchage ».
  final bool canStartDrying;

  /// Séchage en cours — `remainTimeSeconds` suit alors la sécheuse.
  final bool isDrying;

  /// Code à présenter au comptoir quand une finition manuelle reste due.
  /// Repasse à `null` dès que l'agent a pris le linge en charge.
  final String? handoffCode;

  final String? failureReason;

  factory WashSessionStatusModel.fromJson(Map<String, dynamic> json) {
    final sessionStatus = json['sessionStatus'] as String? ?? 'PENDING';
    return WashSessionStatusModel(
      sessionId: json['sessionId'] as String? ?? '',
      paymentStatus: SessionPaymentStatus.fromApi(
        json['paymentStatus'] as String? ?? 'PENDING',
      ),
      machineStartStatus: MachineStartStatus.fromSessionStatus(sessionStatus),
      remainTimeSeconds: (json['remainTimeSeconds'] as num?)?.toInt(),
      canRetry: json['canRetry'] as bool? ?? false,
      isFinished: sessionStatus == 'DONE',
      withDrying: json['withDrying'] as bool? ?? false,
      canStartDrying: json['canStartDrying'] as bool? ?? false,
      isDrying: json['isDrying'] as bool? ?? false,
      handoffCode: json['handoffCode'] as String?,
      failureReason: json['failureReason'] as String?,
    );
  }
}
