import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/core/auth/client_session_store.dart';
import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/payment/domain/entities/pending_payment.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import 'package:fotdelsi/features/payment/presentation/cubit/pending_payments_cubit.dart';

/// Stockage en mémoire : les tests ne touchent pas le Keychain.
class _InMemoryStorage extends FlutterSecureStorage {
  _InMemoryStorage();

  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

class _StubPayments implements PaymentRepository {
  _StubPayments(this.pending);

  final List<PendingPayment> pending;
  int calls = 0;

  @override
  Future<Either<Failure, List<PendingPayment>>> pendingPayments() async {
    calls += 1;
    return Right(pending);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

PendingPayment _resumable() => PendingPayment(
  paymentId: 'pay-1',
  amount: 4000,
  checkoutUrl: 'https://pay.test/1',
  expiresAt: DateTime.now().add(const Duration(minutes: 20)),
);

void main() {
  group('Bandeau « Paiement en attente » — numéro lié ou non', () {
    test('ne propose rien tant qu\'aucun numéro n\'est lié', () async {
      // Poste agent, ou client qui n'a jamais lié son numéro : `/me/...`
      // exige une session, l'appeler ne rendrait qu'un 401.
      final payments = _StubPayments([_resumable()]);
      final cubit = ClientPendingPaymentsCubit(
        payments,
        ClientSessionStore(_InMemoryStorage()),
      );

      await cubit.load();

      expect(cubit.state.mostRecent, isNull);
      expect(payments.calls, 0);
      await cubit.close();
    });

    test('propose le paiement quand un numéro est lié', () async {
      final storage = _InMemoryStorage();
      final session = ClientSessionStore(storage);
      await session.save(token: 'jeton', phone: '770000000');

      final cubit = ClientPendingPaymentsCubit(_StubPayments([_resumable()]), session);

      await cubit.load();

      expect(cubit.state.mostRecent?.paymentId, 'pay-1');
      await cubit.close();
    });

    test('retire le bandeau dès que la session disparaît', () async {
      // Le cas qui laissait le bandeau à l'écran : la garde de `load` ne
      // protège que l'instant du chargement. Une déliaison — ou une purge
      // décidée par l'intercepteur sur un 401 — survient APRÈS, et proposait
      // alors de reprendre le paiement d'un numéro qui n'est plus lié ici.
      final session = ClientSessionStore(_InMemoryStorage());
      await session.save(token: 'jeton', phone: '770000000');

      final cubit = ClientPendingPaymentsCubit(_StubPayments([_resumable()]), session);
      await cubit.load();
      expect(cubit.state.mostRecent, isNotNull);

      await session.clear();
      // Laisse le flux propager la notification.
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.mostRecent, isNull);
      await cubit.close();
    });
  });
}
