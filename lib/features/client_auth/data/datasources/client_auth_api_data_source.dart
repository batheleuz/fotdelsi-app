import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';

/// Résultat d'une vérification OTP réussie.
typedef VerifiedSession = ({String token, String phone});

/// Source distante REST de l'identité client (OTP SMS).
class ClientAuthApiDataSource {
  const ClientAuthApiDataSource(this._dio);

  final Dio _dio;

  Future<void> requestOtp(String phone) async {
    await _dio.post<dynamic>(ApiEndpoints.requestOtp, data: {'phone': phone});
  }

  Future<VerifiedSession> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.verifyOtp,
      data: {'phone': phone, 'code': code},
    );
    final data = (resp.data?['data'] as Map<String, dynamic>?) ?? const {};
    return (
      token: data['token'] as String,
      phone: data['phone'] as String? ?? phone,
    );
  }

  /// Révocation côté backend (token client envoyé en Bearer par l'intercepteur).
  Future<void> logout() async {
    await _dio.post<dynamic>(ApiEndpoints.clientLogout);
  }
}
