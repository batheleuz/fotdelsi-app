import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'package:fotdelsi/core/network/api_response.dart';
import 'package:fotdelsi/core/network/exceptions.dart';
import '../models/service_formula_model.dart';

/// Source distante du catalogue (`GET /service-formulas`). Endpoint public.
class CatalogApiDataSource {
  const CatalogApiDataSource(this._dio);

  final Dio _dio;

  Future<List<ServiceFormulaModel>> fetchFormulas({
    bool selfServiceOnly = false,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.serviceFormulas,
        queryParameters: selfServiceOnly ? {'selfServiceOnly': 'true'} : null,
      );
      final jsonResponse = response.data as Map<String, dynamic>;
      final responseData = ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
      );
      final formulas =
          (responseData.data['formulas'] as List<dynamic>?) ?? const [];
      return formulas
          .map((e) => ServiceFormulaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }
}
