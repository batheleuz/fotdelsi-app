import 'package:equatable/equatable.dart';

import 'drop_off_status.dart';
import 'laundry.dart';

/// Dépôt de linge géré par un agent.
class DropOff extends Equatable {
  const DropOff({
    required this.id,
    required this.code,
    required this.customerName,
    required this.contactPhone,
    required this.laundry,
    required this.status,
    required this.receivedAt,
    this.machineId,
    this.washSessionId,
    this.withDrying = false,
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
  });

  final String id;
  final String code;
  final String customerName;
  final String contactPhone;
  final Laundry laundry;
  final DropOffStatus status;

  final String? machineId;
  final String? washSessionId;

  /// Séchage inclus (choisi et payé au dépôt).
  final bool withDrying;

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

  final DateTime receivedAt;
  final DateTime? startedAt;
  final DateTime? readyAt;
  final DateTime? collectedAt;
  final String? terminalReason;

  bool get _inProgress => status == DropOffStatus.inProgress;

  /// Un cycle (lavage ou séchage) tourne encore : aucune action agent possible,
  /// on attend la fin détectée automatiquement (polling).
  bool get isCycleRunning =>
      _inProgress && !canStartDrying && !canMarkReady;

  /// Lavage terminé + séchage payé mais pas encore lancé → « Lancer le séchage ».
  bool get canStartDrying =>
      _inProgress &&
      withDrying &&
      washCompletedAt != null &&
      dryStartedAt == null;

  /// Le cycle requis est terminé → « Marquer prêt » :
  ///  - sans séchage : dès que le lavage est fini ;
  ///  - avec séchage : dès que le séchage est fini.
  bool get canMarkReady =>
      _inProgress &&
      (withDrying ? dryCompletedAt != null : washCompletedAt != null);

  // Toutes les valeurs affichables entrent dans l'égalité : sinon une
  // modification d'un champ absent (nom du client, linge, instructions…) rend
  // le nouveau DropOff « égal » à l'ancien → Bloc supprime l'emit → l'UI reste
  // figée alors que les données rechargées sont pourtant à jour.
  @override
  List<Object?> get props => [
        id,
        code,
        customerName,
        contactPhone,
        laundry,
        status,
        machineId,
        washSessionId,
        withDrying,
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
      ];
}
