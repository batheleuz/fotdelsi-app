import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import 'package:fotdelsi/features/catalog/domain/entities/business_hours.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/catalog/domain/repositories/service_formula_repository.dart';
import 'package:fotdelsi/features/counter_sale/presentation/cubit/counter_sale_cubit.dart';
import 'package:fotdelsi/features/counter_sale/presentation/pages/counter_sale_page.dart';
import 'package:fotdelsi/features/counter_sale/presentation/widgets/steps/sale_service_step.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/domain/repositories/machine_repository.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_session.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import 'package:fotdelsi/features/wash_session/domain/repositories/wash_session_repository.dart';

ServiceFormula _manual(List<ServiceItemKind> items) => ServiceFormula(
  code: 'FINITIONS',
  label: 'Repassage',
  items: [
    for (final kind in items)
      ServiceItem(kind: kind, label: kind.name, requiresAgent: true),
  ],
  includesDrying: false,
  requiresAgent: true,
  selfServiceEnabled: true,
  displayOrder: 1,
  prices: const [
    FormulaPrice(sizeKg: 12, price: 2000),
    FormulaPrice(sizeKg: 15, price: 2500),
    FormulaPrice(sizeKg: 20, price: 3000),
  ],
);

const _washer = Machine(
  id: 'washer',
  code: 'W1',
  name: 'Laveuse',
  type: MachineType.washer,
  status: MachineStatus.available,
  price: 4000,
  size: 12,
);
const _dryer = Machine(
  id: 'dryer',
  code: 'D1',
  name: 'Sécheuse',
  type: MachineType.dryer,
  status: MachineStatus.available,
  price: 3000,
  size: 20,
);
const _washing = ServiceFormula(
  code: 'LAVAGE',
  label: 'Lavage',
  items: [
    ServiceItem(
      kind: ServiceItemKind.washing,
      label: 'Lavage',
      requiresAgent: false,
    ),
  ],
  includesDrying: false,
  requiresAgent: false,
  selfServiceEnabled: true,
  displayOrder: 0,
  prices: [FormulaPrice(sizeKg: 12, price: 4000)],
);

class _Catalog implements ServiceFormulaRepository {
  _Catalog(this.formula);
  final ServiceFormula formula;
  @override
  Future<Either<Failure, ServiceCatalog>> getFormulas({
    bool selfServiceOnly = false,
  }) async => Right(
    ServiceCatalog(
      formulas: [_washing, formula],
      businessHours: const BusinessHours(),
    ),
  );
}

class _Machines implements MachineRepository {
  @override
  Future<Either<Failure, List<Machine>>> getMachines() async =>
      const Right([_washer, _dryer]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Payments implements PaymentRepository {
  String? machineId;
  int? sizeKg;
  int? quantity;
  bool? atCounter;
  int? dryingDuration;
  bool confirmed = false;
  final List<String> statusRequests = [];
  @override
  Future<Either<Failure, PaymentSession>> initiatePayment({
    String? machineId,
    int? sizeKg,
    String? formulaCode,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
    bool atCounter = false,
    int? dryingDurationMinutes,
    int quantity = 1,
    bool requiresSunDrying = false,
  }) async {
    this.machineId = machineId;
    this.sizeKg = sizeKg;
    this.quantity = quantity;
    this.atCounter = atCounter;
    dryingDuration = dryingDurationMinutes;
    return const Right(
      PaymentSession(
        provider: PaymentProvider.wave,
        paymentId: 'manual-payment',
        externalRef: 'MANUAL',
        amount: 5000,
        redirectUrl: 'https://pay.example/fixture',
      ),
    );
  }

  @override
  Future<Either<Failure, bool>> isPaymentConfirmed(String paymentId) async {
    statusRequests.add(paymentId);
    return Right(confirmed);
  }

  @override
  Future<Either<Failure, bool>> reconcilePayment(String paymentId) async =>
      Right(confirmed);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Aucun appel à une session machine n'est autorisé pour le repassage.
class _NoSessions implements WashSessionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<CounterSaleCubit> _cubit(
  ServiceFormula formula,
  _Payments payments,
) async {
  final cubit = CounterSaleCubit(
    _Catalog(formula),
    _Machines(),
    payments,
    _NoSessions(),
  );
  await cubit.stream.firstWhere((s) => s.loadStatus == SaleLoadStatus.success);
  return cubit;
}

void main() {
  for (final items in [
    [ServiceItemKind.ironing],
    [ServiceItemKind.folding],
    [ServiceItemKind.ironing, ServiceItemKind.folding],
  ]) {
    test('$items vend les tailles sans sécheuse ni jeton machine', () async {
      final payments = _Payments();
      final formula = _manual(items);
      final cubit = await _cubit(formula, payments);
      addTearDown(cubit.close);
      cubit.selectFormula(formula);
      expect(cubit.eligibleMachines, isEmpty);
      expect(formula.lotSizes, [12, 15, 20]);
      expect(cubit.state.canGoNext, isFalse);
      cubit.selectMachine(_dryer);
      expect(cubit.state.machine, isNull);
      cubit.selectSize(17);
      expect(cubit.state.canGoNext, isFalse);
      cubit.selectSize(15);
      cubit.selectQuantity(2);
      expect(cubit.state.total, 5000);
      expect(cubit.state.canGoNext, isTrue);
      expect(cubit.state.canSelectDryingTier, isFalse);
      cubit.setCustomerName('Awa Diop');
      cubit.setCustomerPhone('770000000');
      cubit.selectProvider(PaymentProvider.wave);
      await cubit.submit();
      await Future<void>.delayed(Duration.zero);
      expect(payments.machineId, isNull);
      expect(payments.sizeKg, 15);
      expect(payments.quantity, 2);
      expect(payments.atCounter, isTrue);
      expect(payments.dryingDuration, isNull);
      expect(payments.statusRequests, ['manual-payment']);
      expect(cubit.state.saleStatus, SaleStatus.awaitingPayment);
      payments.confirmed = true;
      expect(await cubit.verifyPayment(), isTrue);
      expect(cubit.state.saleStatus, SaleStatus.paid);
      expect(cubit.state.step, 3);
      expect(await cubit.startMachine(_dryer), isNotNull);
      expect(cubit.state.saleStatus, SaleStatus.paid);
    });
  }

  test(
    'changer entre lavage et repassage réinitialise le choix incompatible',
    () async {
      final formula = _manual([ServiceItemKind.ironing]);
      final cubit = await _cubit(formula, _Payments());
      addTearDown(cubit.close);
      cubit.selectFormula(_washing);
      cubit.selectMachine(_washer);
      expect(cubit.state.total, 4000);
      cubit.selectFormula(formula);
      expect(cubit.state.machine, isNull);
      expect(cubit.state.total, isNull);
      cubit.selectSize(20);
      expect(cubit.state.total, 3000);
      cubit.selectFormula(_washing);
      expect(cubit.state.sizeKg, isNull);
      expect(cubit.state.canGoNext, isFalse);
      expect(cubit.eligibleMachines, [_washer]);
      cubit.selectMachine(_washer);
      expect(cubit.state.total, 4000);
    },
  );

  testWidgets(
    'l’agent choisit trois tailles puis termine sans bouton de démarrage',
    (tester) async {
      final payments = _Payments();
      final formula = _manual([ServiceItemKind.ironing]);
      serviceLocator.registerFactory<CounterSaleCubit>(
        () => CounterSaleCubit(
          _Catalog(formula),
          _Machines(),
          payments,
          _NoSessions(),
        ),
      );
      addTearDown(() => serviceLocator.unregister<CounterSaleCubit>());
      await tester.pumpWidget(const MaterialApp(home: CounterSalePage()));
      await tester.pumpAndSettle();
      final cubit = tester
          .element(find.byType(SaleServiceStep))
          .read<CounterSaleCubit>();
      cubit.selectFormula(formula);
      await tester.pumpAndSettle();
      expect(find.text('12 kg'), findsOneWidget);
      expect(find.text('15 kg'), findsOneWidget);
      expect(find.text('20 kg'), findsOneWidget);
      expect(find.text('Machine'), findsNothing);
      expect(find.text('Nombre de lots'), findsOneWidget);
      await tester.tap(find.text('15 kg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Repassage · 15 kg'), findsOneWidget);
      cubit.setCustomerName('Awa Diop');
      cubit.setCustomerPhone('770000000');
      cubit.selectProvider(PaymentProvider.wave);
      await cubit.submit();
      await tester.pump();
      payments.confirmed = true;
      // Le suivi automatique utilise l'identifiant du paiement, sans session.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(cubit.state.saleStatus, SaleStatus.paid);
      expect(find.text('Prise en charge'), findsOneWidget);
      expect(find.text('Terminer'), findsOneWidget);
      expect(find.text('Démarrer la machine'), findsNothing);
      expect(find.text('Démarrer plus tard'), findsNothing);
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).enabled,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
