import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/auth/client_session_store.dart';
import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/network/error_mapper.dart';
import 'package:fotdelsi/core/network/exceptions.dart';
import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/payment/presentation/bloc/payment_state.dart';
import 'package:fotdelsi/features/wash_session/domain/entities/wash_cycle.dart';
import 'package:fotdelsi/features/wash_session/domain/repositories/wash_session_repository.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_cycles_cubit.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/unconsumed_purchase_sheet.dart';

/// Le refus « vous avez déjà un lavage payé » n'est pas un message de plus :
/// l'écran doit y RÉPONDRE, en proposant de démarrer la machine déjà payée.
/// Il faut donc que le motif du refus traverse toutes les couches, du serveur
/// jusqu'à l'état de l'écran.

/// Réponse d'erreur telle que l'enveloppe backend la rend.
DioException _refus({required String code, int status = 409}) => DioException(
  requestOptions: RequestOptions(path: '/payments/initiate'),
  type: DioExceptionType.badResponse,
  response: Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: '/payments/initiate'),
    statusCode: status,
    data: {
      'error': {
        'code': code,
        'message':
            'Vous avez déjà un lavage payé sur Lavage 12kg. '
            'Démarrez-le avant d\'en acheter un autre.',
      },
    },
  ),
);

class _NoRepository implements WashSessionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _LinkedSession extends ClientSessionStore {
  _LinkedSession() : super(const FlutterSecureStorage());

  @override
  Future<String?> token() async => 'jeton-client';
}

/// Cubit qui note les démarrages au lieu de les exécuter.
class _FakeMyCycles extends MyCyclesCubit {
  _FakeMyCycles(this._cycles) : super(_NoRepository(), _LinkedSession());

  final List<WashCycle> _cycles;
  final List<String> started = [];

  @override
  Future<Either<Failure, List<WashCycle>>> fetch() async => Right(_cycles);

  @override
  Future<bool> start(WashCycle cycle) async {
    started.add(cycle.token);
    return true;
  }
}

/// Lavage payé, jamais lancé — celui qui bloque un second achat.
WashCycle _paidNeverStarted() => WashCycle(
  token: 'jeton-1',
  machineId: 'machine-1',
  amount: 7000,
  paidAt: DateTime.now(),
  state: CycleState.toStart,
  machineName: 'Laveuse 01',
);

/// Ouvre la feuille depuis un bouton, comme le fait l'écran de paiement.
Future<List<bool>> _openSheet(WidgetTester tester) async {
  final results = <bool>[];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              results.add(
                await showUnconsumedPurchaseSheet(
                  context,
                  message:
                      'Vous avez déjà un lavage payé sur Laveuse 01. '
                      'Démarrez-le avant d\'en acheter un autre.',
                ),
              );
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  group('la feuille propose de démarrer la machine déjà payée', () {
    late _FakeMyCycles cycles;

    setUp(() {
      cycles = _FakeMyCycles([_paidNeverStarted()]);
      serviceLocator.registerFactory<MyCyclesCubit>(() => cycles);
    });

    tearDown(() => serviceLocator.reset());

    testWidgets('nomme la machine sur son bouton', (tester) async {
      // Le client doit reconnaître SA machine : « Démarrer ma machine » le
      // laisserait se demander laquelle des quatre.
      await _openSheet(tester);

      expect(find.text('Vous avez déjà un lavage payé'), findsOneWidget);
      expect(find.text('Démarrer Laveuse 01'), findsOneWidget);
    });

    testWidgets('reprend le refus du serveur, qui nomme la machine', (
      tester,
    ) async {
      // Recopier le texte ici en ferait deux versions à tenir, et c'est le
      // serveur qui sait laquelle des machines a été payée.
      await _openSheet(tester);

      expect(find.textContaining('Laveuse 01'), findsWidgets);
    });

    testWidgets('démarre après confirmation, et le dit à l\'appelant', (
      tester,
    ) async {
      final results = await _openSheet(tester);

      await tester.tap(find.text('Démarrer Laveuse 01'));
      await tester.pumpAndSettle();

      // Même confirmation que partout ailleurs : le geste consomme le cycle
      // payé, et un appui involontaire le dépenserait sur un tambour vide.
      await tester.tap(find.text('Démarrer la machine'));
      await tester.pumpAndSettle();

      expect(cycles.started, ['jeton-1']);
      // Et la consigne suit : la commande est partie, le tambour attend qu'on
      // appuie sur l'écran de la machine.
      expect(find.text('Commande de démarrage envoyée'), findsOneWidget);
      expect(results, [true]);
    });

    testWidgets('ne démarre rien si la confirmation est refusée', (
      tester,
    ) async {
      await _openSheet(tester);

      await tester.tap(find.text('Démarrer Laveuse 01'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pas encore'));
      await tester.pumpAndSettle();

      expect(cycles.started, isEmpty);
    });

    testWidgets('« Plus tard » referme sans rien lancer', (tester) async {
      final results = await _openSheet(tester);

      // `.last` : la feuille et sa confirmation portent le même libellé de
      // renoncement, seule celle du dessus est ouverte ici.
      await tester.tap(find.text('Plus tard').last);
      await tester.pumpAndSettle();

      expect(cycles.started, isEmpty);
      expect(results, [false]);
    });
  });

  group('quand le cycle payé reste introuvable', () {
    setUp(() {
      // Achat fait depuis un autre appareil, numéro non lié ici : la liste
      // revient vide.
      serviceLocator.registerFactory<MyCyclesCubit>(() => _FakeMyCycles([]));
    });

    tearDown(() => serviceLocator.reset());

    testWidgets('n\'invente pas de bouton', (tester) async {
      // Le message a déjà dit quoi faire, et l'accueil porte le geste. Un
      // bouton mort ferait croire à une panne.
      await _openSheet(tester);

      expect(find.text('Démarrez-le depuis l\'accueil'), findsOneWidget);
      final bouton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(bouton.onPressed, isNull);
    });
  });

  group('le motif du refus traverse les couches', () {
    test('l\'exception porte le code du serveur', () {
      final exception = AppException.fromDio(
        _refus(code: 'UNCONSUMED_PURCHASE'),
      );

      expect(exception, isA<ServerException>());
      expect(exception.code, 'UNCONSUMED_PURCHASE');
      // Le message reste celui du serveur : c'est lui qui nomme la machine.
      expect(exception.message, contains('Lavage 12kg'));
    });

    test('le Failure le conserve', () {
      final failure = mapExceptionToFailure(_refus(code: 'UNCONSUMED_PURCHASE'));

      expect(failure, isA<ServerFailure>());
      expect(failure.code, 'UNCONSUMED_PURCHASE');
    });

    test('une réponse sans code ne casse rien', () {
      // Toutes les erreurs n'en portent pas, et la grande majorité des écrans
      // n'en a que faire.
      final sansCode = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 400,
          data: {
            'error': {'message': 'Les informations fournies sont invalides.'},
          },
        ),
      );

      final failure = mapExceptionToFailure(sansCode);

      expect(failure.code, isNull);
      expect(failure.message, contains('invalides'));
    });
  });

  group('l\'écran de paiement reconnaît ce refus', () {
    test('sur un échec portant le bon code', () {
      const state = PaymentState(
        status: PaymentStatus.failure,
        errorCode: 'UNCONSUMED_PURCHASE',
        errorMessage: 'Vous avez déjà un lavage payé sur Lavage 12kg.',
      );

      expect(state.isUnconsumedPurchase, isTrue);
    });

    test('pas sur un autre refus', () {
      // Machine hors service, laverie fermée : la feuille n'aurait rien à
      // proposer, et le message suffit.
      const state = PaymentState(
        status: PaymentStatus.failure,
        errorCode: 'VALIDATION_ERROR',
        errorMessage: 'La laverie est fermée.',
      );

      expect(state.isUnconsumedPurchase, isFalse);
    });

    test('pas sur un paiement qui aboutit', () {
      // Un code qui traînerait d'une tentative précédente ne doit pas faire
      // surgir la feuille par-dessus un paiement réussi.
      const state = PaymentState(
        status: PaymentStatus.success,
        errorCode: 'UNCONSUMED_PURCHASE',
      );

      expect(state.isUnconsumedPurchase, isFalse);
    });

    test('le refus ne survit pas à la tentative suivante', () {
      const refuse = PaymentState(
        status: PaymentStatus.failure,
        errorCode: 'UNCONSUMED_PURCHASE',
        errorMessage: 'Vous avez déjà un lavage payé.',
      );

      final reessaie = refuse.copyWith(status: PaymentStatus.processing);

      expect(reessaie.errorCode, isNull);
      expect(reessaie.errorMessage, isNull);
    });
  });
}
