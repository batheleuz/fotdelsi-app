import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/wash_session/domain/entities/wash_cycle.dart';
import 'package:fotdelsi/features/wash_session/domain/repositories/wash_session_repository.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_cycles_cubit.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/active_sessions_sheet.dart';

class _NoRepository implements WashSessionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _StubCycles extends WashCyclesCubit {
  _StubCycles() : super(_NoRepository());

  @override
  Future<Either<Failure, List<WashCycle>>> fetch() async =>
      const Right(<WashCycle>[]);
}

WashCycle _running({required String token, required String machine}) =>
    WashCycle(
      token: token,
      machineId: 'machine-$token',
      amount: 4800,
      paidAt: DateTime.now(),
      state: CycleState.running,
      startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      remainingSeconds: 1200,
      machineName: machine,
    );

WashCycle _toStart({required String token, required String machine}) =>
    WashCycle(
      token: token,
      machineId: 'machine-$token',
      amount: 4800,
      paidAt: DateTime.now(),
      state: CycleState.toStart,
      machineName: machine,
    );

Future<void> _open(WidgetTester tester, List<WashCycle> cycles) async {
  final cubit = _StubCycles();
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  showActiveSessionsSheet(context, cycles: cycles, cubit: cubit),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('liste CHAQUE cycle payé, aucun n\'est masqué', (tester) async {
    // C'est la raison d'être de la feuille : un client qui paie deux fois
    // obtient deux cycles bien réels, et l'accueil n'en montrait qu'un. Le
    // second existait, était payé, et n'apparaissait nulle part.
    await _open(tester, [
      _running(token: 'a', machine: 'Laveuse 01'),
      _running(token: 'b', machine: 'Laveuse 02'),
      _toStart(token: 'c', machine: 'Laveuse 03'),
    ]);

    expect(find.text('Laveuse 01'), findsOneWidget);
    expect(find.text('Laveuse 02'), findsOneWidget);
    expect(find.text('Laveuse 03'), findsOneWidget);
    expect(find.text('Vos 3 lavages'), findsOneWidget);
  });

  testWidgets('ne propose un démarrage que là où il en faut un', (
    tester,
  ) async {
    // Une machine qui tourne n'a pas de bouton : l'y mettre inviterait à
    // relancer un cycle déjà en cours.
    await _open(tester, [
      _running(token: 'a', machine: 'Laveuse 01'),
      _toStart(token: 'b', machine: 'Laveuse 02'),
    ]);

    expect(find.text('Démarrer'), findsOneWidget);
    // « Commande envoyée » et non « Lavage en cours » : personne ne peut plus
    // affirmer qu'une machine tourne — EQLink ne le rend pas — et le client
    // n'a peut-être pas encore appuyé sur l'écran de la machine.
    expect(find.text('Commande envoyée'), findsOneWidget);
  });

  testWidgets('propose de terminer un cycle dont le linge attend', (
    tester,
  ) async {
    // Le seul geste qui clôt un cycle depuis qu'aucune machine ne sait dire
    // qu'elle a fini. Il ne lance rien : le libellé ne doit pas laisser croire
    // le contraire.
    await _open(tester, [
      WashCycle(
        token: 'e',
        machineId: 'machine-e',
        amount: 4500,
        paidAt: DateTime.now(),
        state: CycleState.awaitingPickup,
        startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        machineName: 'Laveuse 05',
      ),
    ]);

    expect(find.text('Linge à récupérer'), findsOneWidget);
    expect(find.text('Terminer'), findsOneWidget);
    expect(find.text('Démarrer'), findsNothing);
  });

  testWidgets('distingue le séchage à lancer d\'un cycle qui tourne', (
    tester,
  ) async {
    // La session reste « en cours » côté serveur pendant tout le temps mort
    // entre lavage et séchage. Les confondre laisserait le client attendre
    // devant une machine arrêtée.
    await _open(tester, [
      WashCycle(
        token: 'd',
        machineId: 'machine-d',
        amount: 6000,
        paidAt: DateTime.now(),
        state: CycleState.dryingToStart,
        startedAt: DateTime.now().subtract(const Duration(minutes: 40)),
        washCompletedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        withDrying: true,
        machineName: 'Laveuse 04',
      ),
    ]);

    expect(find.text('Lavage terminé — séchage à lancer'), findsOneWidget);
    expect(find.text('Sécher'), findsOneWidget);
  });
}
