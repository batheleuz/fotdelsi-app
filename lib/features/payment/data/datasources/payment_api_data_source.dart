import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'package:fotdelsi/core/utils/phone_number.dart';
import 'package:fotdelsi/core/network/api_response.dart';
import 'package:fotdelsi/core/network/exceptions.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_delivery.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import '../../domain/entities/pending_payment.dart';
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

  /// `GET /me/payments/pending` — paiements que le client peut encore honorer.
  Future<List<PendingPayment>> pendingPayments() async {
    final resp = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.myPendingPayments,
    );
    final data = (resp.data?['data'] as Map<String, dynamic>?) ?? const {};
    return ((data['payments'] as List?) ?? const [])
        .map((e) => _pending(e as Map<String, dynamic>))
        .toList();
  }

  static PendingPayment _pending(Map<String, dynamic> json) => PendingPayment(
    paymentId: json['paymentId'] as String,
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    expiresAt:
        DateTime.tryParse(json['expiresAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    machineStillHeld: json['machineStillHeld'] as bool? ?? false,
    machineName: json['machineName'] as String?,
    formulaLabel: json['formulaLabel'] as String?,
    checkoutUrl: json['checkoutUrl'] as String?,
    fallbackUrl: json['fallbackUrl'] as String?,
  );

  /// Initie un paiement de dépôt (`purpose: DROP_OFF`).
  ///
  /// [delivery] dit si le serveur doit pousser la demande au client, ou se
  /// taire parce que l'agent va lui montrer le QR. Le lien revient dans les
  /// deux cas.
  Future<PaymentSessionModel> initiateDropOffPayment({
    required String draftId,
    required PaymentProvider provider,
    required String customerFullName,
    required String customerPhone,
    required PaymentDelivery delivery,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.paymentsInitiate,
        data: {
          'purpose': 'DROP_OFF',
          'draftId': draftId,
          'provider': provider.apiValue,
          'customerFullName': customerFullName,
          'customerPhone': normalizePhone(customerPhone),
          'paymentDelivery': delivery.apiValue,
        },
      );

      // La session revient désormais à l'appelant : elle porte le lien de
      // paiement, que l'agent encode en QR quand le client est devant lui.
      // Elle était jetée, ce qui interdisait tout autre canal que la
      // notification.
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
