part of 'auth_cubit.dart';

/// Statut de session global.
enum AuthStatus { unknown, anonymous, authenticated }

/// Statut du formulaire de connexion (écran login).
enum AuthFormStatus { idle, loading, failure }

final class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.formStatus = AuthFormStatus.idle,
    this.error,
  });

  final AuthStatus status;
  final AuthUser? user;
  final AuthFormStatus formStatus;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  AuthRole? get role => user?.role;
  bool get isSubmitting => formStatus == AuthFormStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    AuthFormStatus? formStatus,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      formStatus: formStatus ?? this.formStatus,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, user, formStatus, error];
}
