import 'package:equatable/equatable.dart';

import '../../presentation/utils/relative_time.dart';
import 'drop_off_status.dart';
import 'laundry.dart';

/// Dépôt de linge géré par un agent.
class DropOff extends Equatable {
  const DropOff({
    this.origin = 'AGENT',
    required this.id,
    required this.code,
    required this.customerName,
    required this.contactPhone,
    required this.laundry,
    required this.status,
    this.receivedAt,
    this.machineId,
    this.plannedMachineId,
    this.plannedMachineName,
    this.washSessionId,
    this.withDrying = false,
    this.dryingDurationMinutes,
    this.dryerMachineId,
    this.dryStartedAt,
    this.washCompletedAt,
    this.dryCompletedAt,
    this.paymentId = '',
    this.creationDay = '',
    this.startedAt,
    this.readyAt,
    this.collectedAt,
    this.terminalReason,
    this.clientCycleFinished,
    this.clientCycleFinishedAt,
    this.awaitingPickup = false,
  });

  final String id;
  final String code;
  final String customerName;
  final String contactPhone;
  final Laundry laundry;
  final DropOffStatus status;

  /// `SELF_SERVICE` : le client a lavé lui-même et apporte son linge pour la
  /// finition payée. Détermine ce qu'il reste à faire — et surtout ce qu'il ne
  /// faut PAS refaire (relancer un lavage).
  final String origin;

  final String? machineId;
  final String? plannedMachineId;
  final String? plannedMachineName;
  final String? washSessionId;

  /// Séchage inclus (choisi et payé au dépôt).
  final bool withDrying;

  /// Durée de séchage choisie en minutes (15, 30, 45, 60), null si pas de séchage.
  final int? dryingDurationMinutes;

  /// Sécheuse assignée — null tant que le séchage n'est pas lancé.
  final String? dryerMachineId;

  /// Début de la phase de séchage — null tant que non lancé.
  final DateTime? dryStartedAt;

  /// Fin du cycle de lavage (auto, polling) — null tant que le lavage tourne.
  final DateTime? washCompletedAt;

  /// Fin du cycle de séchage (auto, polling) — null tant que le séchage tourne.
  final DateTime? dryCompletedAt;

  final String paymentId;
  final String creationDay;

  final DateTime? receivedAt;
  final DateTime? startedAt;
  final DateTime? readyAt;
  final DateTime? collectedAt;
  final String? terminalReason;
  final bool? clientCycleFinished;

  /// Date exacte à laquelle le cycle du client (lavage + éventuel séchage) a
  /// été détecté comme terminé — renseigné par le backend depuis la session de
  /// lavage (`endedAt ?? dryCompletedAt ?? washCompletedAt`).
  final DateTime? clientCycleFinishedAt;
  final bool awaitingPickup;

  /// Vrai si le linge a été effectivement réceptionné au comptoir.
  bool get isReceived => receivedAt != null;

  /// Libellé d'affichage du dépôt, ex. « déposé à l'instant », ou null s'il n'est pas encore reçu.
  String? get receivedLabel {
    final at = receivedAt;
    if (at == null) return null;
    return 'déposé ${relativeTimeFr(at)}';
  }

  bool get _inProgress => status == DropOffStatus.inProgress;

  /// Linge lavé en libre-service : les cycles machine sont déjà faits.
  bool get isSelfService => origin == 'SELF_SERVICE';

  /// En attente que le client apporte son linge au comptoir.
  bool get isAwaitingHandoff => status == DropOffStatus.awaitingHandoff;

  /// L'agent peut prendre en charge le linge qu'on vient de lui apporter.
  bool get canReceiveHandoff => isAwaitingHandoff && isSelfService;

  /// Autorisé quand le cycle du client est terminé (`clientCycleFinished == true`).
  bool get canReceiveFromClient =>
      isAwaitingHandoff && (clientCycleFinished == true);

  /// Un cycle (lavage ou séchage) tourne encore : aucune action agent possible,
  /// on attend la fin détectée automatiquement (polling) ou présumée.
  bool get isCycleRunning => _inProgress && !canStartDrying && !canMarkReady;

  /// Lavage terminé + séchage payé mais pas encore lancé → « Lancer le séchage ».
  bool get canStartDrying =>
      _inProgress &&
      !isSelfService &&
      withDrying &&
      washCompletedAt != null &&
      dryStartedAt == null;

  /// Le cycle requis est terminé → « Marquer prêt » :
  ///  - sans séchage : dès que le lavage est fini ;
  ///  - avec séchage : dès que le séchage est fini (constaté ou présumé) ;
  ///  - libre-service : dès la prise en charge — le travail est manuel, il n'y
  ///    a aucun cycle machine à attendre (`washCompletedAt` reste nul, le
  ///    lavage ayant été tracé sur la session du client).
  bool get canMarkReady =>
      _inProgress &&
      (isSelfService ||
          (withDrying
              ? (dryCompletedAt != null ||
                    (dryStartedAt != null && awaitingPickup))
              : (washCompletedAt != null)));

  // Toutes les valeurs affichables entrent dans l'égalité : sinon une
  // modification d'un champ absent (nom du client, linge, instructions…) rend
  // le nouveau DropOff « égal » à l'ancien → Bloc supprime l'emit → l'UI reste
  // figée alors que les données rechargées sont pourtant à jour.
  @override
  List<Object?> get props => [
    id,
    origin,
    code,
    customerName,
    contactPhone,
    laundry,
    status,
    machineId,
    plannedMachineId,
    plannedMachineName,
    washSessionId,
    withDrying,
    dryingDurationMinutes,
    dryerMachineId,
    dryStartedAt,
    washCompletedAt,
    dryCompletedAt,
    paymentId,
    creationDay,
    receivedAt,
    startedAt,
    readyAt,
    collectedAt,
    terminalReason,
    clientCycleFinished,
    clientCycleFinishedAt,
    awaitingPickup,
  ];
}
