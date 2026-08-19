import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/auth/client_session_store.dart';
import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/payment/domain/entities/pending_payment.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import 'package:fotdelsi/features/payment/presentation/cubit/pending_payments_cubit.dart';

class _Session extends ClientSessionStore {
  _Session(this._token) : super(const FlutterSecureStorage());

  final String? _token;

  @override
  Future<String?> token() async => _token;
}

class _Repo implements PaymentRepository {
  _Repo({this.payments = const [], this.echoue = false});

  final List<PendingPayment> payments;
  final bool echoue;
  int appels = 0;

  @override
  Future<Either<Failure, List<PendingPayment>>> pendingPayments() async {
    appels++;
    return echoue ? const Left(TimeoutFailure()) : Right(payments);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

PendingPayment _paiement({
  String id = 'p1',
  Duration reste = const Duration(minutes: 20),
  String? url = 'https://pay.wave.com/c/abc',
}) => PendingPayment(
  paymentId: id,
  amount: 6000,
  expiresAt: DateTime.now().add(reste),
  machineStillHeld: true,
  checkoutUrl: url,
);

void main() {
  test('n\'interroge pas le serveur sans numéro lié', () async {
    // `GET /me/payments/pending` exige une session client : sans elle, l'appel
    // ne rapporterait qu'un 401.
    final repo = _Repo();
    final cubit = ClientPendingPaymentsCubit(repo, _Session(null));

    await cubit.load();

    expect(repo.appels, 0);
    expect(cubit.state.mostRecent, isNull);
  });

  test('propose le paiement laissé en plan', () async {
    // Le cas vécu : le solde manquait, le client recharge et revient.
    final cubit = ClientPendingPaymentsCubit(
      _Repo(payments: [_paiement()]),
      _Session('jeton'),
    );

    await cubit.load();

    expect(cubit.state.mostRecent!.paymentId, 'p1');
  });

  test('écarte un lien expiré', () async {
    // Le rouvrir mènerait à une page morte, ce qui est pire que ne rien
    // proposer.
    final cubit = ClientPendingPaymentsCubit(
      _Repo(payments: [_paiement(reste: const Duration(minutes: -1))]),
      _Session('jeton'),
    );

    await cubit.load();

    expect(cubit.state.mostRecent, isNull);
  });

  test('écarte un paiement sans lien conservé', () async {
    // Les paiements antérieurs à leur conservation n'en ont pas.
    final cubit = ClientPendingPaymentsCubit(
      _Repo(payments: [_paiement(url: null)]),
      _Session('jeton'),
    );

    await cubit.load();

    expect(cubit.state.mostRecent, isNull);
  });

  test('reste silencieux quand le chargement échoue', () async {
    // Ce bandeau est un rattrapage, pas le contenu principal de l'accueil : un
    // réseau capricieux n'a pas à y faire surgir une erreur.
    final cubit = ClientPendingPaymentsCubit(
      _Repo(echoue: true),
      _Session('jeton'),
    );

    await cubit.load();

    expect(cubit.state.mostRecent, isNull);
    expect(cubit.state.payments, isEmpty);
  });

  test('retire la ligne une fois le client parti payer', () async {
    // Sans prétendre que c'est réglé : le résultat n'est connu que du serveur.
    final cubit = ClientPendingPaymentsCubit(
      _Repo(payments: [_paiement()]),
      _Session('jeton'),
    );
    await cubit.load();

    cubit.dismiss('p1');

    expect(cubit.state.mostRecent, isNull);
  });
}
