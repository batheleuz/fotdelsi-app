import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/repositories/client_auth_repository.dart';

part 'client_session_state.dart';

/// État global de l'identité client : le numéro lié (ou `null` si anonyme).
///
/// Singleton observé par l'accueil pour basculer entre l'UI anonyme et l'UI
/// « numéro lié ».
class ClientSessionCubit extends Cubit<ClientSessionState> {
  ClientSessionCubit(this._repository) : super(const ClientSessionState()) {
    bootstrap();
  }

  final ClientAuthRepository _repository;

  Future<void> bootstrap() async {
    emit(ClientSessionState(phone: await _repository.linkedPhone()));
  }

  Future<void> refresh() => bootstrap();

  Future<void> unlink() async {
    await _repository.unlink();
    emit(const ClientSessionState());
  }
}
