import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fotdelsi/core/auth/client_session_store.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import '../../domain/entities/wash_cycle.dart';
import '../../domain/repositories/wash_session_repository.dart';

part 'wash_cycles_state.dart';

/// Suivi des cycles : à démarrer, en cours, terminés depuis 24 h.
///
/// Encaisser, lancer la machine, suivre le cycle puis récupérer le linge sont
/// des gestes séparés dans le temps. Tant que ces informations ne vivaient que
/// dans l'écran où l'achat avait eu lieu, le quitter rendait la commande
/// introuvable — alors que l'argent, lui, était bien pris.
///
/// Rien n'est conservé localement : l'état vient du serveur à chaque
/// ouverture. Fermer l'application, en changer, ou prendre la relève d'un
/// collègue n'y change rien.
///
/// Classe abstraite parce que l'agent et le client voient la MÊME chose d'un
/// cycle — machine, prestation, temps restant, temps écoulé — et que seul le
/// périmètre diffère. Deux cubits jumeaux auraient fini par diverger sur la
/// cadence de rafraîchissement ou sur le tri.
abstract class WashCyclesCubit extends Cubit<WashCyclesState> {
  WashCyclesCubit(this.repository) : super(const WashCyclesState());

  final WashSessionRepository repository;

  Timer? _ticker;
  int _ticks = 0;

  /// Rythme de resynchronisation, **calé sur le polling EQLink** (10 s).
  ///
  /// Le temps restant n'est JAMAIS décompté localement : il est réaffiché tel
  /// que la machine l'a annoncé. Un compteur qui s'égrène à la seconde entre
  /// deux relevés espacés de 10 s montre une précision qui n'existe pas, et
  /// finit par afficher autre chose que la réalité. Seul le temps écoulé
  /// avance à la seconde — il se déduit de l'instant de démarrage, il est
  /// exact par construction.
  static const _resyncEvery = 10;

  /// Ce que ce cubit va chercher. C'est le seul point de variation.
  Future<Either<Failure, List<WashCycle>>> fetch();

  Future<bool> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: WashCyclesStatus.loading));

    final result = await fetch();
    return result.fold(
      (failure) {
        // Un rafraîchissement de fond qui échoue alors qu'une liste est déjà
        // affichée ne concerne pas l'utilisateur : ce qu'il voit reste juste,
        // seule sa fraîcheur est en jeu.
        //
        // Le message était posé dans TOUS les cas. Comme l'écran affiche
        // chaque nouvelle erreur en snackbar, la resynchronisation des 10 s
        // faisait surgir « Le serveur met trop de temps à répondre » au milieu
        // d'un lavage — sur un écran dont le contenu était pourtant correct.
        final silencieux = silent && state.cycles != null;

        emit(
          state.copyWith(
            status: silencieux
                ? WashCyclesStatus.success
                : WashCyclesStatus.failure,
            error: silencieux ? null : failure.message,
            clearError: silencieux,
          ),
        );
        return false;
      },
      (cycles) {
        emit(
          state.copyWith(
            status: WashCyclesStatus.success,
            cycles: cycles,
            clearError: true,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> refresh() => load(silent: true);

  /// Démarre le battement d'affichage. À appeler à l'ouverture de l'écran.
  void startTicking() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _ticks++;
      // Rien à animer tant qu'aucune machine ne tourne : inutile de
      // reconstruire l'écran une fois par seconde.
      if (state.running.isNotEmpty) {
        emit(state.copyWith(tick: _ticks));
      }
      if (_ticks % _resyncEvery == 0) load(silent: true);
    });
  }

  /// Lance la machine d'un cycle déjà payé.
  ///
  /// Après un succès on recharge au lieu de retirer la ligne : le cycle ne
  /// disparaît pas, il passe en « en cours » et reste suivi.
  ///
  /// Un échec ne retire rien non plus : le cycle reste dû, et il doit rester
  /// possible de réessayer après avoir vérifié la machine.
  Future<bool> start(WashCycle cycle) async {
    emit(state.copyWith(startingToken: cycle.token, clearStartError: true));

    final result = await repository.startMachine(cycle.token);
    return result.fold(
      (failure) {
        emit(state.copyWith(clearStarting: true, startError: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(clearStarting: true, clearStartError: true));
        // Le serveur renvoie le cycle en RUNNING — mais sans durée : EQLink ne
        // la connaît pas encore à cet instant. On revient donc la chercher.
        _chaseRemainingTime();
        return true;
      },
    );
  }

  /// Délais des rechargements qui suivent un démarrage, en secondes.
  ///
  /// La durée d'un cycle n'existe pas à l'instant du démarrage : EQLink ne la
  /// rend pas dans sa réponse, et le serveur va la chercher dans les secondes
  /// qui suivent. Attendre la resynchronisation ordinaire — toutes les 10 s —
  /// ajoutait sa propre latence à celle du serveur, et le client restait
  /// jusqu'à une demi-minute devant un « — ».
  ///
  /// Rapprochés puis espacés, et on s'arrête dès que la durée est là.
  static const _apresDemarrage = [2, 4, 7, 12];

  /// Recharge plusieurs fois après un démarrage, jusqu'à connaître la durée.
  Future<void> _chaseRemainingTime() async {
    await load(silent: true);

    for (final secondes in _apresDemarrage) {
      if (isClosed) return;
      // Déjà connue : la resynchronisation ordinaire suffit pour la suite.
      if (state.running.any((c) => c.remainingSeconds != null)) return;

      await Future<void>.delayed(Duration(seconds: secondes));
      if (isClosed) return;
      await load(silent: true);
    }
  }

  /// Lance la sécheuse choisie, pour le second temps d'un cycle déjà payé.
  ///
  /// Distinct de [start] : celui-ci relance la LAVEUSE par son jeton, ce qui
  /// n'a aucun sens une fois le lavage fini. Le séchage exige en plus le choix
  /// d'une sécheuse — la machine n'est pas connue d'avance, contrairement au
  /// premier temps qui a été payé pour une machine précise.
  ///
  /// En cas d'échec, rien n'est modifié côté serveur : le client peut en
  /// choisir une autre, ou réessayer la même une fois libérée.
  /// Renvoie `null` en cas de succès, sinon le message d'échec.
  ///
  /// L'échec n'est PAS posé dans l'état, contrairement à [start]. Le geste part
  /// d'une feuille modale, et l'écran affiche ses erreurs en snackbar : celle-ci
  /// se serait donc affichée **derrière** la feuille restée ouverte, invisible
  /// pour qui vient d'appuyer. C'est à l'appelant de la montrer là où le regard
  /// se trouve.
  ///
  /// Même contrat que `ClientSessionCubit.rename`, pour la même raison.
  Future<String?> startDrying(WashCycle cycle, Machine dryer) async {
    emit(state.copyWith(startingToken: cycle.token, clearStartError: true));

    final result = await repository.startDrying(
      washSessionToken: cycle.token,
      dryerMachineId: dryer.id,
    );
    return result.fold(
      (failure) {
        emit(state.copyWith(clearStarting: true, clearStartError: true));
        return failure.message;
      },
      (_) {
        emit(state.copyWith(clearStarting: true, clearError: true));
        // Le serveur renvoie le cycle avec sa sécheuse et son temps restant.
        load(silent: true);
        return null;
      },
    );
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}

/// Écran agent : les ventes encaissées au comptoir, toutes équipes confondues.
///
/// Non limité à l'agent connecté : une vente laissée en plan en fin de service
/// doit rester rattrapable par celui qui prend la relève.
class CounterSaleCyclesCubit extends WashCyclesCubit {
  CounterSaleCyclesCubit(super.repository);

  @override
  Future<Either<Failure, List<WashCycle>>> fetch() =>
      repository.getCounterSaleCycles();
}

/// Écran client : ses propres cycles, retrouvés par son numéro.
///
/// Y compris ceux qu'un agent lui a vendus au comptoir : ce sont ses achats.
///
/// ─── Sans numéro lié, on n'interroge pas le serveur ───
///
/// `GET /me/cycles` exige une session client. Un appareil anonyme — jamais lié,
/// ou dont le personnel vient de se déconnecter — n'en a pas, et le serveur
/// répond 401 « Votre session a expiré. Reliez à nouveau votre numéro. » Ce
/// message décrit une session perdue, alors qu'il n'y en a jamais eu.
///
/// L'accueil chargeait pourtant ces cycles à chaque ouverture, sans condition.
/// Un anonyme y récoltait donc une erreur à chaque visite, et à chaque
/// redémarrage de l'application.
///
/// Anonyme n'est pas une panne : c'est un état normal, dont la réponse juste
/// est « aucun cycle ». L'interface anonyme s'affiche alors d'elle-même.
class MyCyclesCubit extends WashCyclesCubit {
  MyCyclesCubit(super.repository, this._session);

  final ClientSessionStore _session;

  @override
  Future<Either<Failure, List<WashCycle>>> fetch() async {
    if (await _session.token() == null) return const Right([]);
    return repository.getMyCycles();
  }
}
