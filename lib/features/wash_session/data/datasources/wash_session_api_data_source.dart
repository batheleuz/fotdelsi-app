import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'package:fotdelsi/core/network/api_response.dart';
import 'package:fotdelsi/core/network/exceptions.dart';
import '../models/wash_session_status_model.dart';
import '../../domain/entities/wash_cycle.dart';

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

  /// `GET /wash-sessions/counter-sales` — ventes au comptoir (agent).
  Future<List<WashCycle>> getCounterSaleCycles() =>
      _cycles(ApiEndpoints.counterSaleCycles);

  /// `GET /me/cycles` — cycles du client authentifié.
  Future<List<WashCycle>> getMyCycles() => _cycles(ApiEndpoints.myCycles);

  /// Les deux listes partagent la même forme de réponse : un seul décodage,
  /// pour qu'un changement de contrat ne soit à répercuter qu'ici.
  Future<List<WashCycle>> _cycles(String endpoint) async {
    final response = await _dio.get<Map<String, dynamic>>(endpoint);
    final data = (response.data?['data'] as Map<String, dynamic>?) ?? const {};
    return ((data['cycles'] as List?) ?? const [])
        .map((e) => _cycle(e as Map<String, dynamic>))
        .toList();
  }

  static WashCycle _cycle(Map<String, dynamic> json) {
    return WashCycle(
      token: json['token'] as String,
      machineId: json['machineId'] as String,
      machineName: json['machineName'] as String?,
      dryerMachineName: json['dryerMachineName'] as String?,
      sizeKg: (json['sizeKg'] as num?)?.toInt(),
      formulaLabel: json['formulaLabel'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      paidAt:
          DateTime.tryParse(json['paidAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      state: CycleState.fromApi(
        json['sessionStatus'] as String?,
        canStartDrying: json['canStartDrying'] as bool? ?? false,
      ),
      startedAt: DateTime.tryParse(
        json['startedAt'] as String? ?? '',
      )?.toLocal(),
      endedAt: DateTime.tryParse(json['endedAt'] as String? ?? '')?.toLocal(),
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt(),
      soldByAgentName: json['soldByAgentName'] as String?,
      withDrying: json['withDrying'] as bool? ?? false,
      isDrying: json['isDrying'] as bool? ?? false,
      washCompletedAt: DateTime.tryParse(
        json['washCompletedAt'] as String? ?? '',
      )?.toLocal(),
      handoffCode: json['handoffCode'] as String?,
    );
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

  Future<void> startDrying({
    required String token,
    required String dryerMachineId,
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.startDrying,
        data: {'token': token, 'dryerMachineId': dryerMachineId},
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }
}
