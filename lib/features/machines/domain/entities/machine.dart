/// Type physique de machine.
enum MachineType { washer, dryer }

/// État d'une machine, dérivé de la réponse EQLink (isonline + available).
enum MachineStatus { available, inUse, offline }

/// Entité métier : une machine de la laverie.
///
/// Couche domaine — aucune dépendance à Flutter.
class Machine {
  const Machine({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.status,
    this.remainTime = 0,
  });

  final String id;
  final String code;
  final String name;
  final MachineType type;
  final MachineStatus status;

  /// Secondes restantes du cycle en cours (0 si non [MachineStatus.inUse]).
  final int remainTime;

  bool get isInUse => status == MachineStatus.inUse;

  Machine copyWith({MachineStatus? status, int? remainTime}) => Machine(
    id: id,
    code: code,
    name: name,
    type: type,
    status: status ?? this.status,
    remainTime: remainTime ?? this.remainTime,
  );
}
