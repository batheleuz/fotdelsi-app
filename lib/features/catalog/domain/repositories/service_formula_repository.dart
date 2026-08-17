import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/failures.dart';
import '../entities/service_formula.dart';

abstract class ServiceFormulaRepository {
  /// `GET /service-formulas` — catalogue des prestations et leurs tarifs.
  ///
  /// [selfServiceOnly] restreint aux formules vendables en libre-service ;
  /// le comptoir agent les propose toutes.
  Future<Either<Failure, List<ServiceFormula>>> getFormulas({
    bool selfServiceOnly = false,
  });
}
