import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/service_status_api_data_source.dart';
import '../../domain/service_status.dart';

part 'service_status_state.dart';

/// Cubit global : interroge `GET /status` au démarrage, à la reprise de l'app
/// et périodiquement, pour alimenter la bannière d'indisponibilité.
///
/// Les échecs de `/status` sont silencieux : ils ne doivent jamais afficher
/// d'erreur (on garde le dernier état connu).
class ServiceStatusCubit extends Cubit<ServiceStatusState> {
  ServiceStatusCubit(this._dataSource) : super(const ServiceStatusState());

  final ServiceStatusApiDataSource _dataSource;
  Timer? _timer;

  Future<void> refresh() async {
    try {
      final status = await _dataSource.fetch();
      emit(state.copyWith(warnings: status.warnings));
    } catch (_) {}
  }

  /// Démarre le rafraîchissement immédiat + périodique (une seule fois).
  void start() {
    unawaited(refresh());
    _timer ??= Timer.periodic(const Duration(seconds: 60), (_) => refresh());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
