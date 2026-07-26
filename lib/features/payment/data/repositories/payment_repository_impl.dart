import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/error_mapper.dart';
import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_session.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import '../datasources/payment_api_data_source.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl(this._api);

  final PaymentApiDataSource _api;

  @override
  Future<Either<Failure, PaymentSession>> initiatePayment({
    required String machineId,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
  }) async {
    try {
      final model = await _api.initiatePayment(
        machineId: machineId,
        provider: provider,
        customerFullName: customerFullName,
        customerPhone: customerPhone,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> initiateDropOffPayment({
    required String draftId,
    required int amount,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
  }) async {
    try {
      await _api.initiateDropOffPayment(
        draftId: draftId,
        amount: amount,
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
