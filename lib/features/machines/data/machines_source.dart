import '../domain/entities/machine.dart';

/// Source de données des machines.
///
/// Couche data — pour l'instant statique (mock) afin de valider le design.
/// Sera remplacée par un repository branché sur `GET /machines` + WebSocket
/// sans impact sur la présentation, qui ne dépend que de [Machine].
class MachinesSource {
  const MachinesSource();

  List<Machine> getMachines() => const [
    Machine(
      id: '1',
      code: 'WASH_01',
      name: 'Laveuse 01',
      type: MachineType.washer,
      status: MachineStatus.available,
    ),
    Machine(
      id: '2',
      code: 'WASH_02',
      name: 'Laveuse 02',
      type: MachineType.washer,
      status: MachineStatus.inUse,
      remainTime: 745,
    ),
    Machine(
      id: '3',
      code: 'WASH_03',
      name: 'Laveuse 03',
      type: MachineType.washer,
      status: MachineStatus.available,
    ),
    Machine(
      id: '4',
      code: 'DRY_01',
      name: 'Sécheuse 01',
      type: MachineType.dryer,
      status: MachineStatus.offline,
    ),
  ];
}
