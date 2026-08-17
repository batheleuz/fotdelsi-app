import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'package:fotdelsi/core/utils/phone_number.dart';
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
    required String formulaCode,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
    bool atCounter = false,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.paymentsInitiate,
        data: {
          'machineId': machineId,
          'formulaCode': formulaCode,
          'provider': provider.apiValue,
          'customerFullName': customerFullName,
          'customerPhone': normalizePhone(customerPhone),
          'purpose': "SELF_SERVICE",
          // Déclare une vente au comptoir. Ne transmet aucune identité : le
          // serveur exige alors un jeton d'agent valide et refuse sinon.
          // C'est ce qui empêche une vente de devenir anonyme quand le jeton
          // a expiré — l'app le renouvelle et rejoue l'appel.
          if (atCounter) 'atCounter': true,
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

  /// Initie un paiement de dépôt (`purpose: DROP_OFF`). Le prompt SOFTPAY est
  /// poussé vers le téléphone du client — l'agent n'a besoin que du succès.
  Future<void> initiateDropOffPayment({
    required String draftId,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.paymentsInitiate,
        data: {
          'purpose': 'DROP_OFF',
          'draftId': draftId,
          'provider': provider.apiValue,
          'customerFullName': customerFullName,
          'customerPhone': normalizePhone(customerPhone),
        },
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }
}
