import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'package:fotdelsi/core/network/api_response.dart';
import 'package:fotdelsi/core/network/exceptions.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import '../models/payment_session_model.dart';

/// Source distante REST des paiements.
class PaymentApiDataSource {
  const PaymentApiDataSource(this._dio);

  final Dio _dio;

  Future<PaymentSessionModel> initiatePayment({
    required String machineId,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.paymentsInitiate,
        data: {
          'machineId': machineId,
          'provider': provider.apiValue,
          'customerFullName': customerFullName,
          'customerPhone': customerPhone,
          'purpose': "SELF_SERVICE"
        },
      );

      final json = response.data as Map<String, dynamic>;
      final apiResponse = ApiResponse<dynamic>.fromJson(json);
      
      return PaymentSessionModel.fromJson(
        apiResponse.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }
}
