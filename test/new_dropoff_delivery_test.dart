import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/catalog/domain/repositories/service_formula_repository.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/laundry_type.dart';
import 'package:fotdelsi/features/dropoffs/domain/repositories/drop_off_repository.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/new_dropoff_cubit.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_delivery.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_session.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';

/// Retient le canal demandé, et rend une session porteuse d'un lien.
class _CapturingPayments implements PaymentRepository {
  final List<PaymentDelivery> demandes = [];

  @override
  Future<Either<Failure, PaymentSession>> initiateDropOffPayment({
    required String draftId,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
    required PaymentDelivery delivery,
  }) async {
    demandes.add(delivery);
    return const Right(
      PaymentSession(
        paymentId: 'p1',
        externalRef: 'REF-1',
        amount: 9000,
        provider: PaymentProvider.wave,
        redirectUrl: 'https://wave.test/pay',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _StubDropOffs implements DropOffRepository {
  @override
  Future<Either<Failure, String>> createDraft({
    required String contactPhone,
    required String customerName,
    required String formulaCode,
    required int sizeKg,
    required int pieces,
    required List<LaundryType> types,
    String? instructions,
  }) async => const Right('brouillon-1');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Le cubit charge le catalogue dès sa construction : ces tests portent sur le
/// canal de paiement, pas sur les formules.
class _StubFormulas implements ServiceFormulaRepository {
  @override
  Future<Either<Failure, List<ServiceFormula>>> getFormulas({
    bool selfServiceOnly = false,
  }) async => const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

NewDropOffCubit _cubit(_CapturingPayments payments) => NewDropOffCubit(
  _StubDropOffs(),
  payments,
  _StubFormulas(),
);

void main() {
  test('transmet « le client est là » au serveur', () async {
    // C'est ce champ qui empêche le serveur d'envoyer une notification que le
    // client lirait en repartant, alors qu'il paie devant l'agent.
    final payments = _CapturingPayments();
    final cubit = _cubit(payments);

    cubit.chooseDelivery(PaymentDelivery.onSite);

    expect(cubit.state.delivery, PaymentDelivery.onSite);
  });

  test('pousse la demande par défaut', () async {
    // Aucun choix exprimé : la notification reste le comportement attendu,
    // c'est de loin le cas le plus fréquent.
    final cubit = _cubit(_CapturingPayments());

    expect(cubit.state.delivery, PaymentDelivery.notify);
  });

  test('ne montre un QR que si le client est là ET qu\'un lien existe', () {
    // Un QR vide ferait perdre du temps à l'agent devant son client.
    const sansLien = PaymentSession(
      paymentId: 'p1',
      externalRef: 'REF-1',
      amount: 9000,
      provider: PaymentProvider.wave,
    );

    const surPlaceSansLien = NewDropOffState(
      delivery: PaymentDelivery.onSite,
      session: sansLien,
    );
    expect(surPlaceSansLien.showsQr, isFalse);

    const avecLien = PaymentSession(
      paymentId: 'p1',
      externalRef: 'REF-1',
      amount: 9000,
      provider: PaymentProvider.wave,
      redirectUrl: 'https://wave.test/pay',
    );

    const surPlaceAvecLien = NewDropOffState(
      delivery: PaymentDelivery.onSite,
      session: avecLien,
    );
    expect(surPlaceAvecLien.showsQr, isTrue);

    // Notification : même avec un lien, il n'y a rien à montrer.
    const aDistance = NewDropOffState(session: avecLien);
    expect(aDistance.showsQr, isFalse);
  });
}
