import '../../domain/entities/auth_user.dart';

/// DTO de la réponse `POST /auth/login` (champ `data` de l'enveloppe).
///
/// Forme backend : `{ tokens: { accessToken, refreshToken, ... }, user: {...} }`.
class AuthSessionModel {
  const AuthSessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  factory AuthSessionModel.fromData(Map<String, dynamic> data) {
    final tokens = data['tokens'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    return AuthSessionModel(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
      user: AuthUser.fromJson(user),
    );
  }
}
