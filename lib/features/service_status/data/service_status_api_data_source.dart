import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import '../domain/service_status.dart';

/// Source distante de la disponibilité des services (`GET /status`, public).
class ServiceStatusApiDataSource {
  const ServiceStatusApiDataSource(this._dio);

  final Dio _dio;

  Future<ServiceStatus> fetch() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.status);
    final data = (res.data?['data'] as Map<String, dynamic>?) ?? const {};
    return ServiceStatus.fromJson(data);
  }
}
