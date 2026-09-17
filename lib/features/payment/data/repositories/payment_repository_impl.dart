import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/error_mapper.dart';
import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_delivery.dart';
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
    String? formulaCode,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
    bool atCounter = false,
    int? dryingDurationMinutes,
  }) async {
    try {
      final model = await _api.initiatePayment(
        machineId: machineId,
        formulaCode: formulaCode,
        provider: provider,
        customerFullName: customerFullName,
        customerPhone: customerPhone,
        atCounter: atCounter,
        dryingDurationMinutes: dryingDurationMinutes,
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
  Future<Either<Failure, PaymentSession>> initiateDropOffPayment({
    required String draftId,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
    required PaymentDelivery delivery,
  }) async {
    try {
      final model = await _api.initiateDropOffPayment(
        draftId: draftId,
        provider: provider,
        customerFullName: customerFullName,
        customerPhone: customerPhone,
        delivery: delivery,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, bool>> isPaymentConfirmed(String paymentId) async {
    try {
      return Right(await _api.isPaymentConfirmed(paymentId));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
