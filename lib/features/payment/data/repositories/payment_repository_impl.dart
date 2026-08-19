import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/error_mapper.dart';
import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_session.dart';
import 'package:fotdelsi/features/payment/domain/entities/pending_payment.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import '../datasources/payment_api_data_source.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl(this._api);

  final PaymentApiDataSource _api;

  @override
  Future<Either<Failure, PaymentSession>> initiatePayment({
    required String machineId,
    required String formulaCode,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
    bool atCounter = false,
  }) async {
    try {
      final model = await _api.initiatePayment(
        machineId: machineId,
        formulaCode: formulaCode,
        provider: provider,
        customerFullName: customerFullName,
        customerPhone: customerPhone,
        atCounter: atCounter,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<PendingPayment>>> pendingPayments() async {
    try {
      return Right(await _api.pendingPayments());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> initiateDropOffPayment({
    required String draftId,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
  }) async {
    try {
      await _api.initiateDropOffPayment(
        draftId: draftId,
        provider: provider,
        customerFullName: customerFullName,
        customerPhone: customerPhone,
      );
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
