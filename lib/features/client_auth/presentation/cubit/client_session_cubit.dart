import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:fotdelsi/core/auth/client_session_store.dart';
import '../../domain/repositories/client_auth_repository.dart';

part 'client_session_state.dart';

/// État global de l'identité client : le numéro lié (ou `null` si anonyme).
///
/// Singleton observé par l'accueil pour basculer entre l'UI anonyme et l'UI
/// « numéro lié ».
///
/// Suit aussi les purges décidées hors de tout écran — l'intercepteur HTTP
/// efface la session quand le serveur rejette son jeton (révoqué, expiré, ou
/// émis par un autre backend). Sans cette écoute, l'interface continuerait
/// d'afficher un numéro lié alors que plus aucune requête n'aboutit.
class ClientSessionCubit extends Cubit<ClientSessionState> {
  ClientSessionCubit(this._repository, this._store, {this.onUnlinked})
    : super(const ClientSessionState()) {
    bootstrap();
    _sub = _store.changes.listen((_) => bootstrap());
  }

  final ClientAuthRepository _repository;
  final ClientSessionStore _store;

  /// Nettoyage à effectuer quand le client se délie.
  ///
  /// Injecté plutôt qu'appelé directement : l'identité client n'a pas à
  /// connaître les sessions de lavage. Le sens de la dépendance reste celui
  /// du conteneur, pas l'inverse.
  final Future<void> Function()? onUnlinked;

  StreamSubscription<void>? _sub;

  Future<void> bootstrap() async {
    final phone = await _repository.linkedPhone();
    if (phone == null) {
      // Déconnecté : on repart d'un état vierge plutôt que de garder un nom
      // qui n'appartient plus à personne sur cet appareil.
      emit(const ClientSessionState());
      return;
    }

    // Le numéro local suffit à savoir qu'une session existe : on l'émet tout
    // de suite pour ne pas faire clignoter l'interface le temps de l'appel.
    emit(ClientSessionState(phone: phone, fullName: state.fullName));

    // Le nom, lui, vient du serveur : il appartient au client, pas à
    // l'appareil. Un échec n'invalide pas la session — le client reste lié, il
    // apparaît simplement sans nom le temps que la connexion revienne.
    final profile = await _repository.profile();
    profile.fold(
      (_) => null,
      (p) => emit(state.copyWith(phone: p.phone, fullName: p.fullName)),
    );
  }

  Future<void> refresh() => bootstrap();

  /// Enregistre le nom du client.
  ///
  /// Renvoie le message d'erreur du serveur en cas d'échec, `null` si tout
  /// s'est bien passé — c'est l'écran appelant qui décide où l'afficher.
  Future<String?> rename(String? fullName) async {
    emit(state.copyWith(saving: true));

    final result = await _repository.updateName(fullName);
    return result.fold(
      (failure) {
        emit(state.copyWith(saving: false));
        return failure.message;
      },
      (profile) {
        emit(
          ClientSessionState(phone: profile.phone, fullName: profile.fullName),
        );
        return null;
      },
    );
  }

  /// Délie le numéro et **efface le cycle conservé localement**.
  ///
  /// Masquer le bandeau ne suffirait pas : le jeton de session de lavage reste
  /// sur l'appareil. Si un autre client lie son numéro sur le même téléphone —
  /// cas courant sur un appareil partagé — il verrait réapparaître le cycle du
  /// précédent, avec son bouton de démarrage.
  ///
  /// Rien n'est perdu pour autant : le cycle vit côté serveur, et son
  /// propriétaire le retrouve dans « Mes lavages » en liant à nouveau son
  /// numéro.
  Future<void> unlink() async {
    await _repository.unlink();
    await onUnlinked?.call();
    emit(const ClientSessionState());
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
