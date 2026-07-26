import 'package:equatable/equatable.dart';

/// Échecs métier remontés à la présentation (côté gauche de `Either`).
///
/// Messages déjà prêts à afficher à l'utilisateur. La présentation
/// n'a jamais à manipuler de codes HTTP ni d'exceptions techniques.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erreur serveur, réessayez plus tard.']);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Pas de connexion internet.']);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure(
      [super.message = 'Le serveur met trop de temps à répondre.']);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Accès non autorisé.']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Ressource introuvable.']);
}

final class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure(
      [super.message =
          'Service temporairement indisponible. Réessayez dans un instant.']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure(
      [super.message = 'Une erreur inattendue est survenue.']);
}
