import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'package:fotdelsi/core/network/exceptions.dart';
import '../models/machine_model.dart';

/// Source distante REST des machines (`GET /machines`).
///
/// Couche data : effectue l'appel HTTP et lève une [AppException] typée en cas
/// d'erreur. Aucune logique métier ici, aucune gestion d'`Either` (c'est le
/// rôle du repository).
class MachineApiDataSource {
  const MachineApiDataSource(this._dio);

  final Dio _dio;

  Future<List<MachineModel>> fetchMachines() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.machines);
      final data = response.data as List<dynamic>;
      return data
          .map((e) => MachineModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<MachineModel> fetchMachine(String id) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.machine(id));
      return MachineModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }
}
