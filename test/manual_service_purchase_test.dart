import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/core/router/app_router.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/catalog/presentation/pages/pick_service_size_page.dart';
import 'package:fotdelsi/features/payment/domain/entities/customer_profile.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_session.dart';
import 'package:fotdelsi/features/payment/domain/repositories/customer_profile_repository.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import 'package:fotdelsi/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:fotdelsi/features/payment/presentation/bloc/payment_event.dart';
import 'package:fotdelsi/features/payment/presentation/bloc/payment_state.dart';
import 'package:fotdelsi/features/payment/presentation/widgets/order_recap_card.dart';
import 'package:fotdelsi/features/wash_session/domain/repositories/wash_session_repository.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_session_cubit.dart';

ServiceFormula _formula(List<ServiceItemKind> items) => ServiceFormula(
  code: 'FORMULE_PERSONNALISEE',
  label: 'Finitions',
  items: [
    for (final kind in items)
      ServiceItem(kind: kind, label: kind.name, requiresAgent: true),
  ],
  includesDrying: items.contains(ServiceItemKind.drying),
  requiresAgent: true,
  selfServiceEnabled: true,
  displayOrder: 0,
  prices: const [
    FormulaPrice(sizeKg: 12, price: 2000),
    FormulaPrice(sizeKg: 15, price: 2500),
    FormulaPrice(sizeKg: 20, price: 3000),
  ],
);

class _Payments implements PaymentRepository {
  String? machine;
  int? size;
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
    machine = machineId;
    size = sizeKg;
    return const Right(
      PaymentSession(
        provider: PaymentProvider.wave,
        paymentId: 'p1',
        externalRef: 'REF',
        amount: 2500,
        redirectUrl: 'https://pay.example/invoice',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile implements CustomerProfileRepository {
  @override
  CustomerProfile load() =>
      const CustomerProfile(fullName: 'Awa Diop', phone: '770000000');
  @override
  Future<void> save(CustomerProfile profile) async {}
}

class _Cycles implements WashSessionRepository {
  @override
  load() => null;
  // Toute tentative de créer ou suivre une session machine doit faire échouer
  // ce test : le repassage n'en possède aucune.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final items in [
    [ServiceItemKind.ironing],
    [ServiceItemKind.folding],
    [ServiceItemKind.ironing, ServiceItemKind.folding],
  ]) {
    testWidgets(
      '$items propose les tailles et transmet le choix sans machine',
      (tester) async {
        final formula = _formula(items);
        expect(formula.needsMachine, isFalse);
        ManualPaymentArgs? selected;
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => PickServiceSizePage(formula: formula),
            ),
            GoRoute(
              path: AppRoutes.payment,
              builder: (_, state) {
                selected = state.extra! as ManualPaymentArgs;
                return const Scaffold(body: Text('Paiement du lot'));
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        expect(find.text('12 kg'), findsOneWidget);
        expect(find.text('15 kg'), findsOneWidget);
        expect(find.text('20 kg'), findsOneWidget);
        expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
        await tester.tap(find.text('15 kg'));
        await tester.pumpAndSettle();
        expect(selected, isNull);
        await tester.tap(find.text('Continuer'));
        await tester.pumpAndSettle();
        expect(selected?.sizeKg, 15);
        expect(selected?.formula.code, formula.code);
      },
    );
  }

  testWidgets(
    'le récapitulatif du repassage ne promet aucun cycle ni séchage',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderRecapCard(
              formula: _formula([ServiceItemKind.ironing]),
              sizeKg: 15,
            ),
          ),
        ),
      );
      expect(find.text('15 kg'), findsOneWidget);
      expect(find.text('Nombre de lots'), findsOneWidget);
      expect(find.text('Nombre de cycles'), findsNothing);
      expect(find.textContaining('fin de cycle'), findsNothing);
      expect(find.textContaining('Séchage :'), findsNothing);
      expect(find.textContaining('Remettez votre linge'), findsOneWidget);
    },
  );

  test(
    'un paiement manuel conserve ses liens mais ne crée aucune session de démarrage',
    () async {
      final payments = _Payments();
      final cycles = WashSessionCubit(_Cycles());
      final bloc = PaymentBloc(payments, _Profile(), cycles);
      addTearDown(bloc.close);
      addTearDown(cycles.close);
      bloc.add(const PaymentProviderSelected(PaymentProvider.wave));
      await bloc.stream.firstWhere((state) => state.provider != null);
      bloc.add(
        const PaymentSubmitted(
          formulaCode: 'FORMULE_PERSONNALISEE',
          sizeKg: 15,
        ),
      );
      final result = await bloc.stream.firstWhere(
        (state) =>
            state.status == PaymentStatus.success ||
            state.status == PaymentStatus.failure,
      );
      expect(result.status, PaymentStatus.success);
      expect(payments.machine, isNull);
      expect(payments.size, 15);
      expect(result.session?.redirectUrl, 'https://pay.example/invoice');
      expect(cycles.state.pendingSession, isNull);
    },
  );
}
