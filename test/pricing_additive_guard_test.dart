import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/catalog/domain/entities/business_hours.dart';
import 'package:fotdelsi/features/catalog/domain/entities/drying_duration_tier.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/catalog/domain/repositories/service_formula_repository.dart';
import 'package:fotdelsi/features/counter_sale/presentation/cubit/counter_sale_cubit.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/laundry_type.dart';
import 'package:fotdelsi/features/dropoffs/domain/repositories/drop_off_repository.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/new_dropoff_cubit.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/domain/repositories/machine_repository.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_delivery.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_session.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import 'package:fotdelsi/features/wash_session/domain/repositories/wash_session_repository.dart';

class _FakePayments implements PaymentRepository {
  int initiateCalls = 0;

  @override
  Future<Either<Failure, PaymentSession>> initiatePayment({
    required String machineId,
    String? formulaCode,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
    bool atCounter = false,
    int? dryingDurationMinutes,
    int quantity = 1,
  }) async {
    initiateCalls++;
    return const Right(
      PaymentSession(
        paymentId: 'p1',
        externalRef: 'REF',
        amount: 5000,
        provider: PaymentProvider.wave,
      ),
    );
  }

  @override
  Future<Either<Failure, PaymentSession>> initiateDropOffPayment({
    required String draftId,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
    required PaymentDelivery delivery,
  }) async {
    initiateCalls++;
    return const Right(
      PaymentSession(
        paymentId: 'p1',
        externalRef: 'REF',
        amount: 5000,
        provider: PaymentProvider.wave,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeDropOffs implements DropOffRepository {
  int createDraftCalls = 0;

  @override
  Future<Either<Failure, String>> createDraft({
    required String contactPhone,
    required String customerName,
    required String formulaCode,
    required int sizeKg,
    required int pieces,
    required List<LaundryType> types,
    String? instructions,
    int? dryingDurationMinutes,
    int quantity = 1,
  }) async {
    createDraftCalls++;
    return const Right('draft-1');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeFormulas implements ServiceFormulaRepository {
  @override
  Future<Either<Failure, ServiceCatalog>> getFormulas({
    bool selfServiceOnly = false,
  }) async =>
      const Right(ServiceCatalog(formulas: []));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeMachines implements MachineRepository {
  @override
  Future<Either<Failure, List<Machine>>> getMachines() async =>
      const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSessions implements WashSessionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  const formulaLavageSechage = ServiceFormula(
    code: 'pret_a_porter',
    label: 'Prêt-à-porter',
    items: [],
    includesDrying: true,
    requiresAgent: false,
    selfServiceEnabled: true,
    displayOrder: 1,
    prices: [
      FormulaPrice(sizeKg: 12, price: 200), // Prix test à 200 CFA
      FormulaPrice(sizeKg: 15, price: 5000),
    ],
  );

  const washer12 = Machine(
    id: 'm12',
    code: 'W12',
    name: 'Laveuse 12kg',
    type: MachineType.washer,
    status: MachineStatus.available,
    price: 3000,
    size: 12,
  );

  group('Tarification additive & garde prix <= 0', () {
    test('CounterSale: le séchage s\'additionne au prix de base sans montant négatif', () {
      var state = CounterSaleState(
        formulas: const [formulaLavageSechage],
        formulaCode: 'pret_a_porter',
        machine: washer12,
        dryingTier: DryingDurationTier.m15, // 1 000 F
      );

      // Base: 200 + 1 000 = 1 200 F (auparavant avec ajustement négatif: 200 - 3000 = -2800 F !)
      expect(state.total, 1200);

      // 30 min (2 000 F) -> 200 + 2 000 = 2 200 F
      state = state.copyWith(dryingTier: DryingDurationTier.m30);
      expect(state.total, 2200);

      // 45 min (3 000 F) -> 200 + 3 000 = 3 200 F
      state = state.copyWith(dryingTier: DryingDurationTier.m45);
      expect(state.total, 3200);

      // 60 min (4 000 F) -> 200 + 4 000 = 4 200 F
      state = state.copyWith(dryingTier: DryingDurationTier.m60);
      expect(state.total, 4200);

      // 90 min (5 000 F) -> 200 + 5 000 = 5 200 F
      state = state.copyWith(dryingTier: DryingDurationTier.m90);
      expect(state.total, 5200);

      state = state.copyWith(quantity: 2);
      expect(state.total, 10400);
    });

    test('CounterSale: ne contacte JAMAIS l\'API si total <= 0', () async {
      const formulaGratuite = ServiceFormula(
        code: 'gratuit',
        label: 'Gratuit',
        items: [],
        includesDrying: false,
        requiresAgent: false,
        selfServiceEnabled: true,
        displayOrder: 1,
        prices: [FormulaPrice(sizeKg: 12, price: 0)],
      );

      final payments = _FakePayments();
      final cubit = CounterSaleCubit(
        _FakeFormulas(),
        _FakeMachines(),
        payments,
        _FakeSessions(),
      );

      cubit.selectFormula(formulaGratuite);
      cubit.selectMachine(washer12);
      cubit.setCustomerName('Client Test');
      cubit.setCustomerPhone('771234567');
      cubit.selectProvider(PaymentProvider.wave);

      expect(cubit.state.total, 0);
      expect(cubit.state.canSubmit, isFalse);
      expect(cubit.state.canGoNext, isFalse);

      // Appel explicite de submit()
      await cubit.submit();

      // Vérification absolue : l'API n'a JAMAIS été appelée
      expect(payments.initiateCalls, 0);
      await cubit.close();
    });

    test('NewDropOff: le séchage s\'additionne au prix de base sans montant négatif', () {
      var state = NewDropOffState(
        formulas: const [formulaLavageSechage],
        formulaCode: 'pret_a_porter',
        sizeKg: 12,
        dryingTier: DryingDurationTier.m15, // 1 000 F
      );

      // 200 + 1 000 = 1 200 F
      expect(state.total, 1200);

      state = state.copyWith(dryingTier: DryingDurationTier.m45);
      expect(state.total, 3200);

      state = state.copyWith(quantity: 2);
      expect(state.total, 6400);
    });

    test('NewDropOff: ne contacte JAMAIS l\'API si total <= 0', () async {
      const formulaGratuite = ServiceFormula(
        code: 'gratuit',
        label: 'Gratuit',
        items: [],
        includesDrying: false,
        requiresAgent: false,
        selfServiceEnabled: true,
        displayOrder: 1,
        prices: [FormulaPrice(sizeKg: 12, price: 0)],
      );

      final dropOffs = _FakeDropOffs();
      final payments = _FakePayments();
      final cubit = NewDropOffCubit(
        dropOffs,
        payments,
        _FakeFormulas(),
      );

      cubit.setPhone('771234567');
      cubit.setName('Client Test');
      cubit.selectFormula(formulaGratuite);
      cubit.selectSize(12);
      cubit.selectProvider(PaymentProvider.wave);

      expect(cubit.state.total, 0);
      expect(cubit.state.canSubmit, isFalse);

      // Appel explicite de submit()
      await cubit.submit();

      // Vérification absolue : createDraft et initiate n'ont JAMAIS été appelés
      expect(dropOffs.createDraftCalls, 0);
      expect(payments.initiateCalls, 0);
      await cubit.close();
    });
  });
}
