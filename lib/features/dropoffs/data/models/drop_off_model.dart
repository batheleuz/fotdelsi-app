import '../../domain/entities/drop_off.dart';
import '../../domain/entities/drop_off_status.dart';
import '../../domain/entities/laundry.dart';
import '../../domain/entities/laundry_type.dart';

/// Désérialisation d'un `DropOffDTO` backend en entité [DropOff].
abstract final class DropOffModel {
  const DropOffModel._();

  static DropOff fromJson(Map<String, dynamic> json) {
    final laundryJson = (json['laundry'] as Map<String, dynamic>?) ?? const {};
    return DropOff(
      id: json['id'] as String,
      code: json['code'] as String,
      customerName: json['customerName'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      laundry: _laundry(laundryJson),
      status: DropOffStatus.fromApi(json['status'] as String? ?? 'RECEIVED'),
      machineId: json['machineId'] as String?,
      washSessionId: json['washSessionId'] as String?,
      withDrying: json['withDrying'] as bool? ?? false,
      dryerMachineId: json['dryerMachineId'] as String?,
      dryStartedAt: _date(json['dryStartedAt']),
      washCompletedAt: _date(json['washCompletedAt']),
      dryCompletedAt: _date(json['dryCompletedAt']),
      paymentId: json['paymentId'] as String? ?? '',
      creationDay: json['creationDay'] as String? ?? '',
      receivedAt: _date(json['receivedAt']) ?? DateTime.now(),
      startedAt: _date(json['startedAt']),
      readyAt: _date(json['readyAt']),
      collectedAt: _date(json['collectedAt']),
      terminalReason: json['terminalReason'] as String?,
    );
  }

  static Laundry _laundry(Map<String, dynamic> json) {
    final rawTypes = (json['types'] as List?) ?? const [];
    return Laundry(
      pieces: (json['pieces'] as num?)?.toInt() ?? 1,
      types: rawTypes
          .map((t) => LaundryType.fromApi(t as String))
          .whereType<LaundryType>()
          .toList(),
      instructions: json['instructions'] as String? ?? '',
    );
  }

  /// Les dates backend sont en UTC ISO 8601 ; on convertit en heure locale.
  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toLocal();
}
