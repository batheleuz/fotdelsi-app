import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/core/widgets/cycle_running_card.dart';
import 'package:fotdelsi/features/dropoffs/data/models/drop_off_model.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/laundry_type.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/drop_off_detail_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/drop_off_detail_page.dart';
import 'package:fotdelsi/core/di/service_locator.dart';

class FakeDropOffDetailCubit extends Cubit<DropOffDetailState>
    implements DropOffDetailCubit {
  FakeDropOffDetailCubit(super.initialState);

  String? startedMachineId;

  @override
  Future<void> load(String id, {bool silent = false}) async {}

  @override
  void startRealtime() {}

  @override
  Future<void> markCollected() async {}

  @override
  Future<void> markReady() async {}

  @override
  Future<void> receiveHandoff() async {}

  @override
  Future<bool> startWash(String machineId) async {
    startedMachineId = machineId;
    emit(
      state.copyWith(
        dropOff: DropOffModel.fromJson(
          _dropOffJson(
            status: 'IN_PROGRESS',
            startedAt: DateTime.now().toIso8601String(),
          ),
        ),
      ),
    );
    return true;
  }

  @override
  Future<void> updateLaundry({
    required int pieces,
    String? instructions,
    List<LaundryType>? types,
  }) async {}
}

Map<String, dynamic> _dropOffJson({
  required String status,
  bool withDrying = false,
  String? plannedMachineId,
  String? plannedMachineName,
  String? startedAt,
  String? dryStartedAt,
  String? washCompletedAt,
  String? dryCompletedAt,
}) => {
  'id': 'dropoff-1',
  'code': '4821',
  'creationDay': '2026-09-18',
  'paymentId': 'pay-1',
  'contactPhone': '770000000',
  'customerName': 'Awa Diop',
  'laundry': {'pieces': 5, 'instructions': 'Linge délicat'},
  'origin': 'AGENT',
  'status': status,
  'withDrying': withDrying,
  'plannedMachineId': plannedMachineId,
  'plannedMachineName': plannedMachineName,
  'startedAt': startedAt,
  'dryStartedAt': dryStartedAt,
  'washCompletedAt': washCompletedAt,
  'dryCompletedAt': dryCompletedAt,
  'awaitingPickup': false,
};

void main() {
  tearDown(() {
    if (serviceLocator.isRegistered<DropOffDetailCubit>()) {
      serviceLocator.unregister<DropOffDetailCubit>();
    }
  });

  testWidgets(
    'affiche CycleRunningCard et aucun bottomNavigationBar pendant le lavage',
    (tester) async {
      final dropOff = DropOffModel.fromJson(
        _dropOffJson(
          status: 'IN_PROGRESS',
          startedAt: DateTime.now().toIso8601String(),
        ),
      );

      final fakeCubit = FakeDropOffDetailCubit(
        DropOffDetailState(status: DetailStatus.success, dropOff: dropOff),
      );

      if (serviceLocator.isRegistered<DropOffDetailCubit>()) {
        serviceLocator.unregister<DropOffDetailCubit>();
      }
      serviceLocator.registerFactory<DropOffDetailCubit>(() => fakeCubit);

      await tester.pumpWidget(
        const MaterialApp(home: DropOffDetailPage(dropOffId: 'dropoff-1')),
      );
      await tester.pump();

      // CycleRunningCard doit être affiché avec les conventions unifiées
      expect(find.byType(CycleRunningCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CycleRunningCard),
          matching: find.text('Lavage lancé'),
        ),
        findsOneWidget,
      );
      expect(find.text('Commande de démarrage envoyée'), findsOneWidget);
      expect(find.text('Depuis'), findsOneWidget);

      // Pas de bottomNavigationBar pendant que le cycle tourne
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.bottomNavigationBar, isNull);
    },
  );

  testWidgets('affiche le bouton Lancer le lavage quand le dépôt est reçu', (
    tester,
  ) async {
    final dropOff = DropOffModel.fromJson(_dropOffJson(status: 'RECEIVED'));

    final fakeCubit = FakeDropOffDetailCubit(
      DropOffDetailState(status: DetailStatus.success, dropOff: dropOff),
    );

    if (serviceLocator.isRegistered<DropOffDetailCubit>()) {
      serviceLocator.unregister<DropOffDetailCubit>();
    }
    serviceLocator.registerFactory<DropOffDetailCubit>(() => fakeCubit);

    await tester.pumpWidget(
      const MaterialApp(home: DropOffDetailPage(dropOffId: 'dropoff-1')),
    );
    await tester.pump();

    expect(find.text('Lancer le lavage'), findsOneWidget);
    expect(find.byType(CycleRunningCard), findsNothing);
  });

  testWidgets(
    'confirme la laveuse prévue avant de lancer et montre les consignes',
    (tester) async {
      final dropOff = DropOffModel.fromJson(
        _dropOffJson(
          status: 'RECEIVED',
          plannedMachineId: 'machine-1',
          plannedMachineName: 'Laveuse 1',
        ),
      );
      final fakeCubit = FakeDropOffDetailCubit(
        DropOffDetailState(status: DetailStatus.success, dropOff: dropOff),
      );
      serviceLocator.registerFactory<DropOffDetailCubit>(() => fakeCubit);

      await tester.pumpWidget(
        const MaterialApp(home: DropOffDetailPage(dropOffId: 'dropoff-1')),
      );
      await tester.tap(find.text('Lancer le lavage'));
      await tester.pumpAndSettle();
      expect(find.text('Votre linge est-il dans la machine ?'), findsOneWidget);
      expect(find.textContaining('Une commande de démarrage sera envoyée'), findsOneWidget);
      expect(find.text('Laveuse 1'), findsOneWidget);
      await tester.tap(find.text('Pas encore'));
      await tester.pumpAndSettle();
      expect(fakeCubit.startedMachineId, isNull);

      await tester.tap(find.text('Lancer le lavage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Démarrer la machine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(fakeCubit.startedMachineId, 'machine-1');
      expect(find.text('Commande de démarrage envoyée'), findsWidgets);
      expect(find.text('J\'ai compris'), findsOneWidget);
      await tester.tap(find.text('J\'ai compris'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CycleRunningCard), findsOneWidget);
    },
  );
}
