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
  final String paymentId;
  final String creationDay;

  final DateTime receivedAt;
  final DateTime? startedAt;
  final DateTime? readyAt;
  final DateTime? collectedAt;
  final String? terminalReason;

  @override
  List<Object?> get props => [id, status, machineId, readyAt, collectedAt];
}
