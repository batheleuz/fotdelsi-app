import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'package:fotdelsi/core/network/api_response.dart';
import 'package:fotdelsi/core/network/exceptions.dart';
import '../models/wash_session_status_model.dart';

/// Source distante REST des wash-sessions.
///
/// Couche data : effectue l'appel HTTP et lève une [AppException] typée en cas
/// d'erreur. La gestion d'`Either`/`Failure` est laissée au repository.
class WashSessionApiDataSource {
  const WashSessionApiDataSource(this._dio);

  final Dio _dio;

  /// `GET /wash-session/{token}/status` — statut combiné session+paiement+machine.
  Future<WashSessionStatusModel> getStatus(String token) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.sessionStatus(token),
      );
      final json = response.data as Map<String, dynamic>;
      final apiResponse = ApiResponse<dynamic>.fromJson(json);
      return WashSessionStatusModel.fromJson(
        apiResponse.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  /// `POST /wash-session/start` — démarrage manuel (retry) via EQLink.
  /// Le token transite dans le **body**.
  Future<void> startMachine(String token) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.startMachine,
        data: {'token': token},
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }
}
