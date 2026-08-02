import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';

/// Résultat d'une vérification OTP réussie.
typedef VerifiedSession = ({String token, String phone});

/// Résultat du démarrage de liaison : soit un OTP a été envoyé (`otpRequired`),
/// soit la session a été émise directement (`token` non nul).
typedef LinkStart = ({bool otpRequired, String? token, String phone});

/// Source distante REST de l'identité client (OTP SMS ou liaison directe).
class ClientAuthApiDataSource {
  const ClientAuthApiDataSource(this._dio);

  final Dio _dio;

  /// `POST /me/link-phone/start` — selon la config serveur : envoie l'OTP, ou
  /// lie directement (renvoie le token).
  Future<LinkStart> startLink(String phone) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.linkPhoneStart,
      data: {'phone': phone},
    );
    final data = (resp.data?['data'] as Map<String, dynamic>?) ?? const {};
    return (
      otpRequired: data['otpRequired'] as bool? ?? true,
      token: data['token'] as String?,
      phone: data['phone'] as String? ?? phone,
    );
  }

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
