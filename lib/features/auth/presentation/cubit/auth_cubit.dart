import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_role.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

/// Cubit global de session — pilote le routage par rôle.
///
/// `status` détermine l'écran d'accueil : un agent authentifié est dirigé vers
/// l'interface agent, l'anonyme garde le flux client classique.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  /// Appelé une fois au démarrage (avant `runApp`) pour connaître le profil.
  Future<void> bootstrap() async {
    final user = await _repository.restoreSession();
    print("USER => $user");
    emit(
      state.copyWith(
        status: user == null ? AuthStatus.anonymous : AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> login(String email, String password) async {
    emit(state.copyWith(formStatus: AuthFormStatus.loading, clearError: true));

    final result = await _repository.login(email: email, password: password);

    result.fold(
      (failure) => emit(
        state.copyWith(
          formStatus: AuthFormStatus.failure,
          error: failure.message,
        ),
      ),
      (user) => emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          formStatus: AuthFormStatus.idle,
        ),
      ),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthState(status: AuthStatus.anonymous));
  }
}
