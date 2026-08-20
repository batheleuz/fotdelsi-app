import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'package:fotdelsi/core/utils/phone_number.dart';
import '../../domain/entities/client_profile.dart';

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
  Future<LinkStart> startLink(String rawPhone) async {
    // Le numéro part sous sa forme canonique, sans indicatif : c'est celle que
    // le serveur enregistre, et celle sous laquelle il nous répondra.
    final phone = normalizePhone(rawPhone);
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

  Future<void> requestOtp(String rawPhone) async {
    await _dio.post<dynamic>(
      ApiEndpoints.requestOtp,
      data: {'phone': normalizePhone(rawPhone)},
    );
  }

  Future<VerifiedSession> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final normalized = normalizePhone(phone);
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.verifyOtp,
      data: {'phone': normalized, 'code': code},
    );
    final data = (resp.data?['data'] as Map<String, dynamic>?) ?? const {};
    return (
      token: data['token'] as String,
      // Le repli vaut la forme canonique, pas la saisie brute : c'est cette
      // valeur qui sera conservée sur le téléphone et renvoyée plus tard.
      phone: data['phone'] as String? ?? normalized,
    );
  }

  /// Révocation côté backend (token client envoyé en Bearer par l'intercepteur).
  Future<void> logout() async {
    await _dio.post<dynamic>(ApiEndpoints.clientLogout);
  }

  /// `GET /me/profile` — identité du client authentifié.
  Future<ClientProfile> getProfile() async {
    final resp = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.clientProfile,
    );
    return _profile(resp.data);
  }

  /// `PATCH /me/profile` — le client se renomme. `null` efface le nom.
  Future<ClientProfile> updateProfile(String? fullName) async {
    final resp = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.clientProfile,
      data: {'fullName': fullName},
    );
    return _profile(resp.data);
  }

  static ClientProfile _profile(Map<String, dynamic>? body) {
    final data = (body?['data'] as Map<String, dynamic>?) ?? const {};
    return ClientProfile(
      phone: data['phone'] as String? ?? '',
      fullName: data['fullName'] as String?,
    );
  }
}
