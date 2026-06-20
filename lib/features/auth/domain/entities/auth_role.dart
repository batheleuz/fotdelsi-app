/// Rôle d'un utilisateur authentifié (personnel FOTDELSY).
///
/// Miroir de l'enum backend (`ADMIN | AGENT`). Le client anonyme n'a pas de
/// rôle — il n'est tout simplement pas authentifié.
enum AuthRole {
  admin,
  agent;

  static AuthRole? fromApi(String value) => switch (value) {
        'ADMIN' => AuthRole.admin,
        'AGENT' => AuthRole.agent,
        _ => null,
      };

  String get apiValue => switch (this) {
        AuthRole.admin => 'ADMIN',
        AuthRole.agent => 'AGENT',
      };
}
