import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/service_formula.dart';
import '../../domain/repositories/service_formula_repository.dart';

enum CatalogStatus { initial, loading, success, failure }

final class ServiceCatalogState extends Equatable {
  const ServiceCatalogState({
    this.status = CatalogStatus.initial,
    this.formulas = const [],
    this.error,
  });

  final CatalogStatus status;
  final List<ServiceFormula> formulas;
  final String? error;

  ServiceCatalogState copyWith({
    CatalogStatus? status,
    List<ServiceFormula>? formulas,
    String? error,
  }) {
    return ServiceCatalogState(
      status: status ?? this.status,
      formulas: formulas ?? this.formulas,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, formulas, error];
}

/// Catalogue des prestations vendables en libre-service.
///
/// Filtré sur `selfServiceOnly` côté serveur : une formule réservée au
/// comptoir ne doit pas apparaître dans un parcours d'achat depuis l'app, où
/// elle serait de toute façon refusée à l'initiation du paiement.
class ServiceCatalogCubit extends Cubit<ServiceCatalogState> {
  ServiceCatalogCubit(this._repository) : super(const ServiceCatalogState());

  final ServiceFormulaRepository _repository;

  Future<void> load() async {
    if (state.status == CatalogStatus.loading) return;
    emit(state.copyWith(status: CatalogStatus.loading));

    final result = await _repository.getFormulas(selfServiceOnly: true);

    result.fold(
      (failure) => emit(
        state.copyWith(status: CatalogStatus.failure, error: failure.message),
      ),
      (formulas) => emit(
        state.copyWith(status: CatalogStatus.success, formulas: formulas),
      ),
    );
  }
}
