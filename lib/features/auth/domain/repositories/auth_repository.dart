import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/failures.dart';
import '../entities/auth_user.dart';

/// Contrat domaine de l'authentification du personnel (agent / admin).
abstract interface class AuthRepository {
  /// `POST /auth/login` — authentifie et persiste la session localement.
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  });

  /// Restaure la session depuis le stockage sécurisé au démarrage.
  /// Retourne `null` si aucune session n'est stockée (utilisateur anonyme).
  Future<AuthUser?> restoreSession();

  /// Déconnecte : révoque côté backend (best-effort) et purge le stockage.
  Future<void> logout();
}
