import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'package:fotdelsi/core/utils/phone_number.dart';

/// Source distante REST des notifications (device token + ack).
class NotificationApiDataSource {
  const NotificationApiDataSource(this._dio);

  final Dio _dio;

  Future<void> registerDevice({
    required String phone,
    required String fcmToken,
    required String platform,
  }) async {
    await _dio.post<dynamic>(
      ApiEndpoints.devices,
      data: {
        'phone': normalizePhone(phone),
        'fcmToken': fcmToken,
        'platform': platform,
      },
    );
  }

  Future<void> ack({
    required String notificationId,
    String? smsFallbackId,
  }) async {
    final body = <String, dynamic>{};
    if (smsFallbackId != null) body['smsFallbackId'] = smsFallbackId;
    await _dio.post<dynamic>(
      ApiEndpoints.ackNotification(notificationId),
      data: body,
    );
  }
}
