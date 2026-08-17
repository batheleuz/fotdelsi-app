import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/error_mapper.dart';
import 'package:fotdelsi/core/network/failures.dart';
import '../../domain/entities/service_formula.dart';
import '../../domain/repositories/service_formula_repository.dart';
import '../datasources/catalog_api_data_source.dart';

class ServiceFormulaRepositoryImpl implements ServiceFormulaRepository {
  const ServiceFormulaRepositoryImpl(this._api);

  final CatalogApiDataSource _api;

  @override
  Future<Either<Failure, List<ServiceFormula>>> getFormulas({
    bool selfServiceOnly = false,
  }) async {
    try {
      final models = await _api.fetchFormulas(selfServiceOnly: selfServiceOnly);
      final formulas = models.map((m) => m.toEntity()).toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return Right(formulas);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
