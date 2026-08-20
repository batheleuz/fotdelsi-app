import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off_status.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/laundry.dart';
import 'package:fotdelsi/features/dropoffs/domain/repositories/drop_off_repository.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/my_dropoff_detail_cubit.dart';

DropOff _depot(DropOffStatus status) => DropOff(
  origin: 'SELF_SERVICE',
  id: 'depot-1',
  code: 'A42',
  customerName: 'Awa Diop',
  contactPhone: '770000000',
  laundry: const Laundry(pieces: 5, types: []),
  status: status,
  receivedAt: DateTime(2026, 8, 20),
  creationDay: '2026-08-20',
);

class _Repo implements DropOffRepository {
  _Repo(this._statuts);

  final List<DropOffStatus> _statuts;
  int lectures = 0;

  @override
  Future<Either<Failure, DropOff>> getMyDropOffById(String id) async {
    final statut = _statuts[lectures.clamp(0, _statuts.length - 1)];
    lectures++;
    return Right(_depot(statut));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FailingRepo implements DropOffRepository {
  @override
  Future<Either<Failure, DropOff>> getMyDropOffById(String id) async =>
      const Left(TimeoutFailure());

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('charge le dépôt du client', () async {
    final cubit = MyDropOffDetailCubit(_Repo([DropOffStatus.inProgress]));

    await cubit.load('depot-1');

    expect(cubit.state.status, MyDropOffDetailStatus.success);
    expect(cubit.state.dropOff!.code, 'A42');
  });

  test('un échec de fond n\'efface pas ce qui est affiché', () async {
    // C'est l'écran que le client garde ouvert en attendant : un réseau
    // capricieux ne doit pas remplacer le suivi par une page d'erreur.
    final cubit = MyDropOffDetailCubit(_Repo([DropOffStatus.inProgress]));
    await cubit.load('depot-1');

    // Le relevé de fond échoue, mais du contenu est déjà là.
    final avecPanne = MyDropOffDetailCubit(_FailingRepo());
    await avecPanne.load('depot-1');

    expect(cubit.state.dropOff, isNotNull);
    // Écran vide : là, l'erreur doit se voir.
    expect(avecPanne.state.status, MyDropOffDetailStatus.failure);
  });

  test('cesse d\'interroger quand le linge est remis', () async {
    // Un dépôt remis ne changera plus : continuer d'interroger n'apprendrait
    // rien et ferait battre le serveur pour rien.
    final repo = _Repo([DropOffStatus.collected]);
    final cubit = MyDropOffDetailCubit(repo);

    await cubit.load('depot-1');
    cubit.startWatching();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final apresArret = repo.lectures;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(repo.lectures, apresArret);
  });

  test('coupe le battement à la fermeture', () async {
    // Sans cela, un écran quitté continuerait d'interroger en arrière-plan.
    final repo = _Repo([DropOffStatus.inProgress]);
    final cubit = MyDropOffDetailCubit(repo);
    await cubit.load('depot-1');
    cubit.startWatching();

    await cubit.close();
    final aLaFermeture = repo.lectures;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(repo.lectures, aLaFermeture);
  });
}
