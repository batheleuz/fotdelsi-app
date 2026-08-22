import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/error_mapper.dart';
import 'package:fotdelsi/core/network/failures.dart';
import '../../domain/entities/business_hours.dart';
import '../../domain/repositories/service_formula_repository.dart';
import '../datasources/catalog_api_data_source.dart';

class ServiceFormulaRepositoryImpl implements ServiceFormulaRepository {
  const ServiceFormulaRepositoryImpl(this._api);

  final CatalogApiDataSource _api;

  @override
  Future<Either<Failure, ServiceCatalog>> getFormulas({
    bool selfServiceOnly = false,
  }) async {
    try {
      final result = await _api.fetchFormulas(selfServiceOnly: selfServiceOnly);
      final formulas = result.formulas.map((m) => m.toEntity()).toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return Right(
        ServiceCatalog(formulas: formulas, businessHours: result.hours),
      );
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
