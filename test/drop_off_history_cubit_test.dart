import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off_history_page.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off_status.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/laundry.dart';
import 'package:fotdelsi/features/dropoffs/domain/repositories/drop_off_repository.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/drop_off_history_cubit.dart';

DropOff _dropOff(String id) => DropOff(
  id: id,
  code: 'A$id',
  customerName: 'Awa Diop',
  contactPhone: '771234567',
  laundry: const Laundry(pieces: 3, types: []),
  status: DropOffStatus.collected,
  receivedAt: DateTime(2026, 8, 18),
  creationDay: '2026-08-18',
);

/// Dépôt en mémoire : on observe les fenêtres demandées et ce qui remonte.
class _FakeRepo implements DropOffRepository {
  _FakeRepo({this.total = 0, this.echoue = false});

  final int total;
  bool echoue;

  final List<({int? limit, int? offset})> appels = [];

  @override
  Future<Either<Failure, DropOffHistoryPage>> getHistory({
    int? limit,
    int? offset,
  }) async {
    appels.add((limit: limit, offset: offset));
    if (echoue) return const Left(TimeoutFailure());

    final debut = offset ?? 0;
    final fin = (debut + (limit ?? 30)).clamp(0, total);
    return Right(
      DropOffHistoryPage(
        dropOffs: [
          for (var i = debut; i < fin; i++) _dropOff('$i'),
        ],
        hasMore: fin < total,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('charge la première page depuis le début', () async {
    final repo = _FakeRepo(total: 100);
    final cubit = DropOffHistoryCubit(repo);

    await cubit.load();

    expect(repo.appels.single.offset, 0);
    expect(cubit.state.status, DropOffHistoryStatus.success);
    expect(cubit.state.hasMore, isTrue);
  });

  test('ajoute la page suivante à la suite, sans remplacer', () async {
    // Le reproche que ferait n'importe quel agent : remonter tout l'historique
    // en perdant ce qu'il vient de lire.
    final repo = _FakeRepo(total: 100);
    final cubit = DropOffHistoryCubit(repo);
    await cubit.load();
    final premiere = cubit.state.dropOffs!.length;

    await cubit.loadMore();

    expect(repo.appels.last.offset, premiere);
    expect(cubit.state.dropOffs!.length, greaterThan(premiere));
  });

  test('ne redemande rien quand la fin est atteinte', () async {
    // `hasMore` vient du serveur : sans ce garde, le défilement rappellerait
    // l'API à chaque image une fois arrivé en bas.
    final repo = _FakeRepo(total: 5);
    final cubit = DropOffHistoryCubit(repo);
    await cubit.load();

    await cubit.loadMore();

    expect(cubit.state.hasMore, isFalse);
    expect(repo.appels, hasLength(1));
  });

  test('un échec de page suivante ne vide pas ce qui est lu', () async {
    // Les pages précédentes restent justes ; seule la suite manque.
    final repo = _FakeRepo(total: 100);
    final cubit = DropOffHistoryCubit(repo);
    await cubit.load();
    final deja = cubit.state.dropOffs!.length;

    repo.echoue = true;
    await cubit.loadMore();

    expect(cubit.state.dropOffs, hasLength(deja));
    expect(cubit.state.status, DropOffHistoryStatus.success);
    expect(cubit.state.error, isNotNull);
  });

  test('un échec de PREMIER chargement se dit, lui', () async {
    // Écran vide : là, l'agent doit savoir pourquoi.
    final cubit = DropOffHistoryCubit(_FakeRepo(echoue: true));

    await cubit.load();

    expect(cubit.state.status, DropOffHistoryStatus.failure);
    expect(cubit.state.error, isNotNull);
  });
}
