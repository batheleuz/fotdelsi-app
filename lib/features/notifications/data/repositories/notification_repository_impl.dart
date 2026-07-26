import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/error_mapper.dart';
import 'package:fotdelsi/core/network/exceptions.dart';
import 'package:fotdelsi/core/network/failures.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_api_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._api);

  final NotificationApiDataSource _api;

  @override
  Future<Either<Failure, void>> registerDevice({
    required String phone,
    required String fcmToken,
    required String platform,
  }) =>
      _guard(() => _api.registerDevice(
            phone: phone,
            fcmToken: fcmToken,
            platform: platform,
          ));

  @override
  Future<Either<Failure, void>> ack({
    required String notificationId,
    String? smsFallbackId,
  }) =>
      _guard(() => _api.ack(
            notificationId: notificationId,
            smsFallbackId: smsFallbackId,
          ));

  Future<Either<Failure, void>> _guard(Future<void> Function() op) async {
    try {
      await op();
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapExceptionToFailure(AppException.fromDio(e)));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
