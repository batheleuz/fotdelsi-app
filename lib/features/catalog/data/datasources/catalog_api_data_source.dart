import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'package:fotdelsi/core/network/api_response.dart';
import 'package:fotdelsi/core/network/exceptions.dart';
import '../../domain/entities/business_hours.dart';
import '../models/service_formula_model.dart';

/// Source distante du catalogue (`GET /service-formulas`). Endpoint public.
class CatalogApiDataSource {
  const CatalogApiDataSource(this._dio);

  final Dio _dio;

  /// Renvoie l'offre ET l'état d'ouverture lu au même instant : les deux
  /// arrivent dans la même réponse, les séparer ferait deux appels pour une
  /// seule question.
  Future<({List<ServiceFormulaModel> formulas, BusinessHours hours})>
  fetchFormulas({bool selfServiceOnly = false}) async {
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
      final hours = responseData.data['businessHours'] as Map<String, dynamic>?;
      return (
        formulas:
            formulas
                .map(
                  (e) => ServiceFormulaModel.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
        // Absent d'un serveur plus ancien : laverie réputée ouverte, plutôt
        // qu'un bandeau de fermeture sans horaire à afficher.
        hours: hours == null
            ? const BusinessHours()
            : BusinessHours.fromJson(hours),
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }
}
