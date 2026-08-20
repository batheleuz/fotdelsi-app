import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/auth/client_session_store.dart';

import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/machines/presentation/widgets/home_fabs.dart';
import 'package:fotdelsi/features/wash_session/domain/entities/wash_cycle.dart';
import 'package:fotdelsi/features/wash_session/domain/repositories/wash_session_repository.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_cycles_cubit.dart';

/// Aucun appel réseau : le cubit est doublé au-dessus du dépôt.
class _NoRepository implements WashSessionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Typé `MyCyclesCubit` : c'est ce type précis que l'accueil fournit, et que
/// les boutons lisent.
/// Session cliente presente : ces tests decrivent un client dont le numero est
/// lie. `token()` est surcharge pour ne jamais toucher au stockage securise,
/// qui exige un canal de plateforme.
class _LinkedSession extends ClientSessionStore {
  _LinkedSession() : super(const FlutterSecureStorage());

  @override
  Future<String?> token() async => 'jeton-client';
}

class _FakeMyCycles extends MyCyclesCubit {
  _FakeMyCycles(this._cycles) : super(_NoRepository(), _LinkedSession());

  final List<WashCycle> _cycles;

  @override
  Future<Either<Failure, List<WashCycle>>> fetch() async => Right(_cycles);
}

WashCycle _cycle(CycleState state) => WashCycle(
  token: 'jeton-1',
  machineId: 'machine-1',
  amount: 4800,
  paidAt: DateTime.now(),
  state: state,
  startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
  endedAt: state == CycleState.finished ? DateTime.now() : null,
  remainingSeconds: state == CycleState.running ? 600 : null,
  machineName: 'Lavage 12kg',
  formulaLabel: 'Lavage + séchage',
  withDrying: true,
  washCompletedAt: state == CycleState.dryingToStart ? DateTime.now() : null,
);

/// Monte les boutons seuls.
///
/// C'est tout l'intérêt de les avoir extraits de `home_page.dart` : la page
/// entière exige quatre cubits enregistrés dans le conteneur, alors qu'ils ne
/// dépendent que des cycles.
Future<void> poser(WidgetTester tester, List<WashCycle> cycles) async {
  final cubit = _FakeMyCycles(cycles);
  await cubit.load();

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<MyCyclesCubit>.value(
        value: cubit,
        child: const Scaffold(floatingActionButton: HomeFabs()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('le bouton survit au temps mort entre lavage et séchage', (
    tester,
  ) async {
    // Le reproche exact : refermer la feuille après le lavage faisait
    // disparaître le bouton qui permettait de la rouvrir. Entre les deux temps,
    // plus aucune machine ne tourne.
    await poser(tester, [_cycle(CycleState.dryingToStart)]);

    // Cible par le libellé : le bouton de scan est un second FAB, toujours
    // présent, et `byType` seul ne les distingue pas.
    expect(
      find.widgetWithText(FloatingActionButton, 'Séchage à lancer'),
      findsOneWidget,
    );
  });

  testWidgets('annonce le geste attendu, et non « En cours »', (tester) async {
    // Garder « En cours » pendant le temps mort laisserait croire que le cycle
    // avance, alors qu'il attend le client.
    await poser(tester, [_cycle(CycleState.dryingToStart)]);

    expect(find.text('En cours'), findsNothing);
    expect(find.byIcon(Icons.dry_cleaning_rounded), findsOneWidget);
  });

  testWidgets('dit « En cours » quand une machine tourne vraiment', (
    tester,
  ) async {
    await poser(tester, [_cycle(CycleState.running)]);

    expect(find.text('En cours'), findsOneWidget);
    expect(find.text('Séchage à lancer'), findsNothing);
  });

  testWidgets('s\'efface quand il n\'y a plus rien à suivre', (tester) async {
    // Il ouvrirait sur une feuille vide.
    await poser(tester, [_cycle(CycleState.finished)]);

    expect(find.text('En cours'), findsNothing);
    expect(find.text('Séchage à lancer'), findsNothing);
    // Le bouton de scan, lui, reste toujours là.
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
  });

  testWidgets('rouvre bien la feuille de suivi', (tester) async {
    // Le trajet complet du reproche : le client a refermé la feuille, il doit
    // pouvoir y revenir et retrouver son geste.
    await poser(tester, [_cycle(CycleState.dryingToStart)]);

    await tester.tap(
      find.widgetWithText(FloatingActionButton, 'Séchage à lancer'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Lavage terminé'), findsOneWidget);
    expect(find.text('Démarrer le séchage'), findsOneWidget);
  });
}
