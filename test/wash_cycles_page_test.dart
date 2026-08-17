import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/wash_session/domain/entities/wash_cycle.dart';
import 'package:fotdelsi/features/wash_session/domain/repositories/wash_session_repository.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_cycles_cubit.dart';
import 'package:fotdelsi/features/wash_session/presentation/pages/wash_cycles_page.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/wash_running_sheet.dart';

/// Aucun appel réseau n'a lieu dans ces tests : le cubit est doublé au-dessus.
class _NoRepository implements WashSessionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Cubit de test qui note les démarrages au lieu de les exécuter.
///
/// Sous-classe concrète, comme le sont `CounterSaleCyclesCubit` et
/// `MyCyclesCubit` : c'est justement ce qui rend l'erreur possible en vrai,
/// puisque le provider les expose sous leur type de base.
/// Variante typée `MyCyclesCubit` : la feuille de suivi lit ce type précis,
/// comme le fait le provider de l'accueil.
/// Cubit qui échoue à chaque chargement, pour observer ce qui remonte.
class _FailingCycles extends WashCyclesCubit {
  _FailingCycles() : super(_NoRepository());

  @override
  Future<Either<Failure, List<WashCycle>>> fetch() async =>
      const Left(TimeoutFailure());
}

class _FakeMyCycles extends MyCyclesCubit {
  _FakeMyCycles(this._cycles) : super(_NoRepository());

  final List<WashCycle> _cycles;

  @override
  Future<Either<Failure, List<WashCycle>>> fetch() async => Right(_cycles);
}

class _FakeCyclesCubit extends WashCyclesCubit {
  _FakeCyclesCubit(this._cycles) : super(_NoRepository());

  final List<WashCycle> _cycles;

  /// Jetons passés à `start`, dans l'ordre.
  final List<String> started = [];

  @override
  Future<Either<Failure, List<WashCycle>>> fetch() async => Right(_cycles);

  @override
  Future<bool> start(WashCycle cycle) async {
    started.add(cycle.token);
    return true;
  }

  /// Motif de refus a renvoyer, ou `null` pour laisser passer.
  String? refusDeSechage;

  @override
  Future<String?> startDrying(WashCycle cycle, Machine dryer) async {
    return refusDeSechage;
  }
}

WashCycle cycleDryingToStart() => WashCycle(
  token: 'jeton-3',
  machineId: 'machine-3',
  amount: 6000,
  paidAt: DateTime.now(),
  state: CycleState.dryingToStart,
  startedAt: DateTime.now().subtract(const Duration(minutes: 40)),
  washCompletedAt: DateTime.now().subtract(const Duration(minutes: 2)),
  withDrying: true,
  machineName: 'Laveuse 03',
);

WashCycle cycleRunning() => WashCycle(
  token: 'jeton-2',
  machineId: 'machine-2',
  amount: 4800,
  paidAt: DateTime.now(),
  state: CycleState.running,
  startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
  remainingSeconds: 1200,
  machineName: 'Laveuse 02',
);

WashCycle cycleToStart() => WashCycle(
  token: 'jeton-1',
  machineId: 'machine-1',
  amount: 4800,
  paidAt: DateTime.now(),
  state: CycleState.toStart,
  machineName: 'Laveuse 01',
);

void main() {
  testWidgets('le bouton Démarrer lance bien le cycle', (tester) async {
    final cubit = _FakeCyclesCubit([cycleToStart()]);

    await tester.pumpWidget(
      MaterialApp(
        home: WashCyclesPage(
          createCubit: () => cubit,
          explanation: 'Test',
          layout: CyclesLayout.worklist,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Démarrer la machine'));
    await tester.pump();

    // Le bug : la page demandait `CounterSaleCyclesCubit` alors que le provider
    // est déclaré sur `WashCyclesCubit`. L'exception partait dans le callback,
    // où Flutter l'avale — le bouton semblait simplement mort, sans message ni
    // trace, aussi bien côté agent que côté client.
    expect(cubit.started, ['jeton-1']);
  });

  testWidgets('un second démarrage est refusé pendant le premier', (
    tester,
  ) async {
    final cubit = _FakeCyclesCubit([cycleToStart()]);

    await tester.pumpWidget(
      MaterialApp(
        home: WashCyclesPage(
          createCubit: () => cubit,
          explanation: 'Test',
          layout: CyclesLayout.worklist,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Un démarrage en cours désactive tous les boutons : deux machines lancées
    // par erreur coûtent bien plus qu'une attente.
    cubit.emit(cubit.state.copyWith(startingToken: 'jeton-1'));
    // Deux `pump` : `emit` notifie ses auditeurs par une microtâche, le premier
    // frame part donc avant que `BlocConsumer` n'ait vu le nouvel état. Et pas
    // de `pumpAndSettle` ici — l'indicateur de progression tourne sans fin, il
    // ne se stabilise jamais.
    await tester.pump();
    await tester.pump();

    // On vérifie le comportement, pas `onPressed` : c'est ce que vit l'agent
    // qui appuie, et ça résiste à un changement de widget de bouton.
    expect(find.text('Démarrage…'), findsOneWidget);
    await tester.tap(find.text('Démarrage…'));
    await tester.pump();

    expect(cubit.started, isEmpty);
  });

  group('ordre des sections', () {
    /// Position verticale du titre de section, pour lire l'ordre réel à
    /// l'écran plutôt que celui du code.
    Future<double> yOf(WidgetTester tester, String label) async =>
        tester.getTopLeft(find.text(label)).dy;

    Future<void> pumpWith(WidgetTester tester, CyclesLayout layout) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WashCyclesPage(
            createCubit: () =>
                _FakeCyclesCubit([cycleToStart(), cycleRunning()]),
            explanation: 'Test',
            layout: layout,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('agent : ce qui réclame un geste passe en tête', (
      tester,
    ) async {
      // De l'argent encaissé sans machine lancée doit sauter aux yeux avant
      // ce qui tourne déjà et n'attend rien de personne.
      await pumpWith(tester, CyclesLayout.worklist);

      expect(
        await yOf(tester, 'À démarrer'),
        lessThan(await yOf(tester, 'En cours')),
      );
    });

    testWidgets('client : ce qui tourne passe en tête', (tester) async {
      // C'est la question qu'il se pose en ouvrant « Mes lavages » : où en est
      // mon linge ? Le reste vient ensuite.
      await pumpWith(tester, CyclesLayout.history);

      expect(
        await yOf(tester, 'En cours'),
        lessThan(await yOf(tester, 'À démarrer')),
      );
    });

    testWidgets('le client ne voit pas de fenêtre de 24 h sur les terminés', (
      tester,
    ) async {
      // Son historique n'est pas borné côté serveur : annoncer « 24 h » sur
      // l'écran serait un mensonge d'étiquette.
      expect(CyclesLayout.history.finishedLabel, 'Terminés');
      expect(CyclesLayout.worklist.finishedLabel, 'Terminés (24 h)');
    });
  });

  group('cycle en deux temps', () {
    testWidgets('annonce le lavage fini et le séchage restant', (tester) async {
      // Le manque signalé : après le lavage, l'écran continuait d'égrener le
      // temps écoulé sans rien annoncer. Le client attendait devant une
      // machine arrêtée, sans savoir qu'un geste lui revenait.
      await tester.pumpWidget(
        MaterialApp(
          home: WashCyclesPage(
            createCubit: () => _FakeCyclesCubit([cycleDryingToStart()]),
            explanation: 'Test',
            layout: CyclesLayout.history,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lavage terminé'), findsOneWidget);
      expect(find.text('Lancer le séchage'), findsOneWidget);
    });

    testWidgets('ne propose pas de relancer la laveuse', (tester) async {
      // `start` relancerait la LAVEUSE par son jeton : le mauvais geste, et
      // celui qui gaspillerait le cycle payé.
      final cubit = _FakeCyclesCubit([cycleDryingToStart()]);

      await tester.pumpWidget(
        MaterialApp(
          home: WashCyclesPage(
            createCubit: () => cubit,
            explanation: 'Test',
            layout: CyclesLayout.history,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Démarrer la machine'), findsNothing);
      expect(cubit.started, isEmpty);
    });

    test('un séchage à lancer réclame un geste', () {
      // C'est ce qui le place dans la section « À démarrer » plutôt que parmi
      // ce qui tourne tout seul.
      expect(CycleState.dryingToStart.needsAction, isTrue);
      expect(CycleState.running.needsAction, isFalse);
    });

    test('le statut seul ne suffit pas à reconnaître le temps mort', () {
      // La session reste `RUNNING` entre les deux temps : sans le drapeau du
      // serveur, on la confondrait avec une machine qui tourne.
      expect(CycleState.fromApi('RUNNING'), CycleState.running);
      expect(
        CycleState.fromApi('RUNNING', canStartDrying: true),
        CycleState.dryingToStart,
      );
    });
  });

  group('feuille de suivi', () {
    WashCycle running({required int remaining, required int elapsedMinutes}) =>
        WashCycle(
          token: 'jeton-suivi',
          machineId: 'machine-1',
          amount: 4800,
          paidAt: DateTime.now(),
          state: CycleState.running,
          startedAt: DateTime.now().subtract(Duration(minutes: elapsedMinutes)),
          remainingSeconds: remaining,
          machineName: 'Laveuse 01',
          formulaLabel: 'Lavage simple',
        );

    /// Lavage fini, sécheuse pas encore lancée : le temps mort du milieu.
    WashCycle aSecher() => WashCycle(
      token: 'jeton-suivi',
      machineId: 'machine-1',
      amount: 4800,
      paidAt: DateTime.now(),
      state: CycleState.dryingToStart,
      startedAt: DateTime.now().subtract(const Duration(minutes: 35)),
      machineName: 'Laveuse 01',
      formulaLabel: 'Lavage + séchage',
      withDrying: true,
      washCompletedAt: DateTime.now(),
    );

    /// Second temps en cours : `running`, comme le lavage — d'où `isDrying`.
    WashCycle enSechage() => WashCycle(
      token: 'jeton-suivi',
      machineId: 'machine-1',
      amount: 4800,
      paidAt: DateTime.now(),
      state: CycleState.running,
      startedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      remainingSeconds: 600,
      machineName: 'Laveuse 01',
      dryerMachineName: 'Sécheuse 01',
      formulaLabel: 'Lavage + séchage',
      withDrying: true,
      isDrying: true,
      washCompletedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    /// Ouvre la feuille au-dessus d'un hôte fournissant le cubit.
    Future<void> openSheet(WidgetTester tester, MyCyclesCubit cubit) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<MyCyclesCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => WashRunningSheet.show(
                    context,
                    cubit.state.cycles!.first,
                    cycles: cubit,
                  ),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    String totalShown(WidgetTester tester) {
      final labels = find.text('Durée totale');
      expect(labels, findsOneWidget);
      final column = tester.widget<Column>(
        find.ancestor(of: labels, matching: find.byType(Column)).first,
      );
      return (column.children.first as Text).data!;
    }

    testWidgets('déduit la durée totale au lieu de l\'inventer', (
      tester,
    ) async {
      // La feuille affichait « 35 min » en dur, quel que soit le cycle payé.
      final cubit = _FakeMyCycles([
        running(remaining: 1200, elapsedMinutes: 10),
      ]);
      await cubit.load();

      await openSheet(tester, cubit);

      expect(totalShown(tester), isNot('—'));
      expect(totalShown(tester), isNot('35 min'));
    });

    testWidgets('suit les relevés au lieu de rester figée', (tester) async {
      // Le reproche exact : « ça ne bouge pas ». La feuille lisait une session
      // stockée localement, sans battement propre.
      final cubit = _FakeMyCycles([
        running(remaining: 1800, elapsedMinutes: 5),
      ]);
      await cubit.load();

      await openSheet(tester, cubit);
      final avant = totalShown(tester);

      cubit.emit(
        cubit.state.copyWith(
          cycles: [running(remaining: 600, elapsedMinutes: 5)],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(totalShown(tester), isNot(avant));
    });

    testWidgets('reste ouverte quand le lavage finit et qu\'il reste le séchage', (
      tester,
    ) async {
      // Le reproche exact : la feuille se refermait à la fin du lavage. C'est
      // pourtant l'instant où elle sert le plus — le linge est lavé, la
      // sécheuse reste à lancer, et rien ne l'annonçait.
      final cubit = _FakeMyCycles([aSecher()]);
      await cubit.load();

      await openSheet(tester, cubit);

      expect(find.text('Lavage terminé'), findsOneWidget);
      expect(find.text('Il reste le séchage'), findsOneWidget);
      expect(find.text('Démarrer le séchage'), findsOneWidget);
    });

    testWidgets('passe du lavage au temps mort sans se refermer', (
      tester,
    ) async {
      // La transition est le vrai cas : la feuille est déjà ouverte quand le
      // lavage s'arrête.
      final cubit = _FakeMyCycles([
        running(remaining: 60, elapsedMinutes: 30),
      ]);
      await cubit.load();

      await openSheet(tester, cubit);
      expect(find.text('Démarrer le séchage'), findsNothing);

      cubit.emit(cubit.state.copyWith(cycles: [aSecher()]));
      await tester.pump();
      await tester.pump();

      expect(find.text('Démarrer le séchage'), findsOneWidget);
    });

    testWidgets('annonce le séchage en cours, pas « lavage en cours »', (
      tester,
    ) async {
      // Le second temps est `running` exactement comme le premier : sans le
      // drapeau du serveur, la feuille nommerait la laveuse, déjà arrêtée.
      final cubit = _FakeMyCycles([enSechage()]);
      await cubit.load();

      await openSheet(tester, cubit);

      expect(find.text('Séchage en cours'), findsOneWidget);
      expect(find.text('Sécheuse 01'), findsOneWidget);
    });
  });

  group('rafraîchissement de fond', () {
    test('ne remonte pas d\'erreur quand du contenu est déjà affiché', () async {
      // Le reproche : « Le serveur met trop de temps à répondre » surgissait en
      // snackbar pendant un lavage. La resynchronisation des 10 s posait son
      // échec comme une erreur d'écran, alors que la liste affichée restait
      // juste — seule sa fraîcheur était en jeu.
      final cubit = _FailingCycles();

      // Un premier contenu, posé comme le ferait un chargement réussi.
      cubit.emit(
        cubit.state.copyWith(
          status: WashCyclesStatus.success,
          cycles: [cycleRunning()],
        ),
      );

      await cubit.refresh();

      expect(cubit.state.error, isNull);
      expect(cubit.state.status, WashCyclesStatus.success);
      expect(cubit.state.cycles, isNotEmpty);
    });

    test('remonte l\'erreur quand il n\'y a rien à montrer', () async {
      // Écran vide : là, l'utilisateur doit savoir pourquoi.
      final cubit = _FailingCycles();

      await cubit.load();

      expect(cubit.state.error, isNotNull);
      expect(cubit.state.status, WashCyclesStatus.failure);
    });
  });

  group('refus de séchage', () {
    test('le motif revient à l\'appelant, sans passer par l\'état', () async {
      // La feuille de choix est modale : une erreur posée dans l'état
      // s'afficherait en snackbar DERRIÈRE elle, donc invisible pour qui vient
      // d'appuyer. Le motif est renvoyé, à charge de l'appelant de l'afficher
      // là où le regard se trouve.
      final cubit = _FakeCyclesCubit([cycleDryingToStart()])
        ..refusDeSechage =
            'La machine DRY_01 est occupee : un cycle est en cours.';

      final message = await cubit.startDrying(
        cycleDryingToStart(),
        const Machine(
          id: 'machine-9',
          code: 'DRY_01',
          name: 'Sécheuse 01',
          type: MachineType.dryer,
          status: MachineStatus.inUse,
          price: 0,
        ),
      );

      expect(message, contains('occupee'));
      expect(cubit.state.error, isNull);
    });
  });

  group('cycle suivi par la feuille', () {
    WashCycle termine() => WashCycle(
      token: 'jeton-fini',
      machineId: 'machine-3',
      amount: 4800,
      paidAt: DateTime.now(),
      state: CycleState.finished,
      startedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      endedAt: DateTime.now(),
    );

    test('le temps mort reste suivable', () async {
      // Le reproche : refermer la feuille après le lavage faisait disparaître
      // le bouton qui permettait de la rouvrir. Entre les deux temps, plus
      // aucune machine ne tourne — un critère sur « en cours » laissait donc le
      // client sans aucun moyen de revenir à son cycle.
      final cubit = _FakeCyclesCubit([cycleDryingToStart()]);
      await cubit.load();

      expect(cubit.state.running, isEmpty);
      expect(cubit.state.followable, isNotNull);
    });

    test('le temps mort passe devant ce qui tourne', () async {
      // Un compte à rebours se regarde ; un séchage à lancer se fait.
      final cubit = _FakeCyclesCubit([cycleRunning(), cycleDryingToStart()]);
      await cubit.load();

      expect(cubit.state.followable!.state, CycleState.dryingToStart);
    });

    test('rien à suivre quand tout est terminé', () async {
      // Le bouton doit alors s'effacer : il n'ouvrirait sur rien.
      final cubit = _FakeCyclesCubit([termine()]);
      await cubit.load();

      expect(cubit.state.followable, isNull);
    });
  });

  group('bandeau d\'accueil : horizon des terminés', () {
    WashCycle termineIlYA(Duration age) => WashCycle(
      token: 'jeton-fini-$age',
      machineId: 'machine-3',
      amount: 4800,
      paidAt: DateTime.now().subtract(age),
      state: CycleState.finished,
      startedAt: DateTime.now().subtract(age + const Duration(minutes: 40)),
      endedAt: DateTime.now().subtract(age),
    );

    test('un lavage terminé il y a deux jours n\'est plus annoncé', () async {
      // Le reproche exact : le bandeau affichait « Lavage terminé » depuis deux
      // jours. La fenêtre de 24 h était appliquée par le SERVEUR et a disparu
      // le jour où « Mes lavages » a dû montrer tout l'historique.
      final cubit = _FakeCyclesCubit([termineIlYA(const Duration(days: 2))]);
      await cubit.load();

      expect(cubit.state.mostUrgent, isNull);
    });

    test('un lavage terminé il y a une heure reste annoncé', () async {
      // La fenêtre sert à ça : le client vient de finir, il doit retrouver son
      // cycle sur l'accueil.
      final cubit = _FakeCyclesCubit([termineIlYA(const Duration(hours: 1))]);
      await cubit.load();

      expect(cubit.state.mostUrgent, isNotNull);
    });

    test('l\'historique complet reste dans « Mes lavages »', () async {
      // Les deux surfaces n'ont pas le même objet : la liste est un historique,
      // le bandeau dit ce qui se passe maintenant. Borner la liste effacerait
      // un cycle payé.
      final cubit = _FakeCyclesCubit([termineIlYA(const Duration(days: 30))]);
      await cubit.load();

      expect(cubit.state.finished, hasLength(1));
      expect(cubit.state.mostUrgent, isNull);
    });

    test('un cycle qui tourne prime sur un terminé récent', () async {
      // L'ordre d'urgence ne change pas : la fenêtre ne s'applique qu'au repli.
      final cubit = _FakeCyclesCubit([
        termineIlYA(const Duration(hours: 1)),
        cycleRunning(),
      ]);
      await cubit.load();

      expect(cubit.state.mostUrgent!.state, CycleState.running);
    });
  });

  group('périmètre du bandeau', () {
    WashCycle termineIlYA(Duration age) => WashCycle(
      token: 'jeton-vieux-$age',
      machineId: 'machine-9',
      amount: 4800,
      paidAt: DateTime.now().subtract(age),
      state: CycleState.finished,
      startedAt: DateTime.now().subtract(age + const Duration(minutes: 40)),
      endedAt: DateTime.now().subtract(age),
    );

    test('le compteur ignore l\'historique ancien', () async {
      // Le bandeau annonçait « + N autres lavages » sur TOUT l'historique : un
      // client fidèle y lisait « + 12 autres » alors qu'une seule machine
      // tournait.
      final cubit = _FakeCyclesCubit([
        cycleRunning(),
        termineIlYA(const Duration(days: 8)),
        termineIlYA(const Duration(days: 30)),
      ]);
      await cubit.load();

      // Seul le cycle en cours entre dans le périmètre : rien « d'autre ».
      expect(cubit.state.onHome, hasLength(1));
    });

    test('le compteur retient ce qui appelle un geste', () async {
      // Taire les autres cycles vivants cacherait au client qu'il a payé
      // plusieurs machines.
      final cubit = _FakeCyclesCubit([
        cycleRunning(),
        cycleToStart(),
        cycleDryingToStart(),
      ]);
      await cubit.load();

      expect(cubit.state.onHome, hasLength(3));
    });

    test('un terminé récent compte, un ancien non', () async {
      final recent = _FakeCyclesCubit([termineIlYA(const Duration(hours: 2))]);
      await recent.load();
      expect(recent.state.onHome, hasLength(1));

      final ancien = _FakeCyclesCubit([termineIlYA(const Duration(days: 3))]);
      await ancien.load();
      expect(ancien.state.onHome, isEmpty);
    });
  });

  group('remise en attente', () {
    WashCycle avecRemise({required Duration age, String? code}) => WashCycle(
      token: 'jeton-remise',
      machineId: 'machine-7',
      amount: 9000,
      paidAt: DateTime.now().subtract(age),
      state: CycleState.finished,
      startedAt: DateTime.now().subtract(age + const Duration(minutes: 40)),
      endedAt: DateTime.now().subtract(age),
      formulaLabel: 'Prêt à ranger',
      handoffCode: code,
    );

    test('le code vient du cycle, pas de la session locale', () async {
      // La session locale ne couvre que l'achat fait sur CE téléphone : une
      // vente encaissée au comptoir avec finition n'affichait donc aucune
      // consigne.
      final cubit = _FakeCyclesCubit([
        avecRemise(age: const Duration(hours: 2), code: 'A42'),
      ]);
      await cubit.load();

      expect(cubit.state.awaitingHandoff!.handoffCode, 'A42');
    });

    test('la consigne survit à la fenêtre de 24 h', () async {
      // La prestation est payée et reste due tant que l'agent ne l'a pas prise
      // en charge. C'est le serveur qui retire le code, jamais l'affichage qui
      // l'oublie — un job d'alerte signale les remises jamais apportées.
      final cubit = _FakeCyclesCubit([
        avecRemise(age: const Duration(days: 3), code: 'A42'),
      ]);
      await cubit.load();

      expect(cubit.state.justFinished, isNull);
      expect(cubit.state.awaitingHandoff, isNotNull);
      // Et elle compte dans le périmètre de l'accueil, sinon le bandeau
      // l'afficherait en annonçant « + -1 autre lavage ».
      expect(cubit.state.onHome, hasLength(1));
    });

    test('rien à remettre quand le serveur ne donne aucun code', () async {
      // Un lavage sec ne produit pas de remise.
      final cubit = _FakeCyclesCubit([avecRemise(age: const Duration(hours: 2))]);
      await cubit.load();

      expect(cubit.state.awaitingHandoff, isNull);
    });

    test('le cycle de remise n\'est pas compté deux fois', () async {
      // Terminé récemment ET en attente de remise : c'est le même cycle.
      final cubit = _FakeCyclesCubit([
        avecRemise(age: const Duration(hours: 2), code: 'A42'),
      ]);
      await cubit.load();

      expect(cubit.state.onHome, hasLength(1));
    });
  });
}
