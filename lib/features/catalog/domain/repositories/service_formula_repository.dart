import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/failures.dart';
import '../entities/business_hours.dart';

abstract class ServiceFormulaRepository {
  /// `GET /service-formulas` — catalogue des prestations et leurs tarifs.
  ///
  /// [selfServiceOnly] restreint aux formules vendables en libre-service ;
  /// le comptoir agent les propose toutes.
  ///
  /// Renvoie aussi les horaires d'ouverture : ils arrivent dans la même
  /// réponse, et l'app en a besoin pour annoncer une fermeture au lieu de
  /// laisser le client la découvrir au paiement.
  Future<Either<Failure, ServiceCatalog>> getFormulas({
    bool selfServiceOnly = false,
  });
}
