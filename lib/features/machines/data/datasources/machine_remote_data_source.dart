import '../../domain/entities/machine.dart';

/// Source de données distante des machines.
///
/// Couche data — simule le flux WebSocket : émet l'état initial puis pousse
/// une mise à jour chaque seconde (décompte des cycles). À remplacer par la
/// vraie connexion socket.io / REST sans toucher au repository ni au domaine.
class MachineRemoteDataSource {
  const MachineRemoteDataSource();

  static const List<Machine> _seed = [
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

  Stream<List<Machine>> watchMachines() async* {
    var machines = _seed;
    yield machines;
    yield* Stream<List<Machine>>.periodic(
      const Duration(seconds: 1),
      (_) {
        machines = machines.map(_tick).toList();
        return machines;
      },
    );
  }

  static Machine _tick(Machine m) {
    if (!m.isInUse || m.remainTime <= 0) return m;
    final next = m.remainTime - 1;
    return next <= 0
        ? m.copyWith(status: MachineStatus.available, remainTime: 0)
        : m.copyWith(remainTime: next);
  }
}
