import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/features/catalog/domain/entities/business_hours.dart';
import 'package:fotdelsi/features/catalog/domain/entities/drying_duration_tier.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/catalog/domain/repositories/service_formula_repository.dart';
import 'package:fotdelsi/features/counter_sale/presentation/cubit/counter_sale_cubit.dart';
import 'package:fotdelsi/features/counter_sale/presentation/pages/counter_sale_page.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/domain/repositories/machine_repository.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import 'package:fotdelsi/features/wash_session/domain/repositories/wash_session_repository.dart';

class _FakeFormulaRepo implements ServiceFormulaRepository {
  final List<ServiceFormula> formulas;
  _FakeFormulaRepo(this.formulas);

  @override
  Future<Either<Failure, ServiceCatalog>> getFormulas({bool selfServiceOnly = false}) async {
    return Right(ServiceCatalog(formulas: formulas, businessHours: const BusinessHours()));
  }
}

class _FakeMachineRepo implements MachineRepository {
  final List<Machine> machines;
  _FakeMachineRepo(this.machines);

  @override
  Future<Either<Failure, List<Machine>>> getMachines() async {
    return Right(machines);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentRepo implements PaymentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWashRepo implements WashSessionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const formulaLavage = ServiceFormula(
    code: 'LAVAGE',
    label: 'Lavage',
    items: [ServiceItem(kind: ServiceItemKind.washing, label: 'Lavage', requiresAgent: false)],
    includesDrying: false,
    requiresAgent: false,
    selfServiceEnabled: true,
    displayOrder: 1,
    prices: [FormulaPrice(sizeKg: 12, price: 4000)],
  );

  const formulaLavageSechage = ServiceFormula(
    code: 'LAVAGE_SECHAGE',
    label: 'Lavage & Séchage',
    items: [
      ServiceItem(kind: ServiceItemKind.washing, label: 'Lavage', requiresAgent: false),
      ServiceItem(kind: ServiceItemKind.drying, label: 'Séchage', requiresAgent: false),
    ],
    includesDrying: true,
    requiresAgent: false,
    selfServiceEnabled: true,
    displayOrder: 2,
    prices: [FormulaPrice(sizeKg: 12, price: 7000)],
  );

  const washer12 = Machine(
    id: 'w1',
    code: 'W1',
    name: 'Laveuse 1',
    type: MachineType.washer,
    status: MachineStatus.available,
    price: 4000,
    size: 12,
  );

  const dryer = Machine(
    id: 'd1',
    code: 'D1',
    name: 'Sécheuse 1',
    type: MachineType.dryer,
    status: MachineStatus.available,
    price: 3000,
  );

  setUp(() {
    if (serviceLocator.isRegistered<CounterSaleCubit>()) {
      serviceLocator.unregister<CounterSaleCubit>();
    }
    serviceLocator.registerFactory<CounterSaleCubit>(() => CounterSaleCubit(
          _FakeFormulaRepo([formulaLavage, formulaLavageSechage]),
          _FakeMachineRepo([washer12, dryer]),
          _FakePaymentRepo(),
          _FakeWashRepo(),
        ));
  });

  testWidgets('CounterSalePage displays drying duration tiers when formula includes drying', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CounterSalePage()));
    await tester.pumpAndSettle();

    expect(find.text('Lavage & Séchage'), findsWidgets);

    // Tap Lavage & Séchage
    await tester.tap(find.text('Lavage & Séchage').first);
    await tester.pumpAndSettle();

    // Check if Durée de séchage is visible
    expect(find.text('Durée de séchage'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('15 minutes'), 200);
    await tester.tap(find.text('15 minutes'));
    await tester.pumpAndSettle();

    // Select a machine (washer12)
    await tester.scrollUntilVisible(find.text('12 kg'), -200);
    await tester.tap(find.text('12 kg'));
    await tester.pumpAndSettle();

    // Check total banner in Step 0
    await tester.scrollUntilVisible(find.text(formatFcfa(8000)), 200);
    expect(find.text(formatFcfa(8000)), findsOneWidget);

    // Tap Continuer to go to Step 1 (Client & Recap)
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    // In step 1, check the total and recap! Base = 7000 for 12kg + 15 min drying (1000) = 8000!
    expect(find.text(formatFcfa(8000)), findsOneWidget);
    expect(find.textContaining('Séchage 15 minutes'), findsOneWidget);
  });
}
