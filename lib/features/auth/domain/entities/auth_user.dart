import 'package:equatable/equatable.dart';

import 'auth_role.dart';

/// Utilisateur authentifié (agent ou admin).
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final AuthRole? role;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        role: AuthRole.fromApi(json['role'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role?.apiValue,
      };

  bool get isAgent => role == AuthRole.agent;
  bool get isAdmin => role == AuthRole.admin;

  @override
  List<Object?> get props => [id, email, name, role];
}
