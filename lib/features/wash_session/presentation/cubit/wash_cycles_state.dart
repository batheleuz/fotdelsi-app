part of 'wash_cycles_cubit.dart';

enum WashCyclesStatus { initial, loading, success, failure }

final class WashCyclesState extends Equatable {
  const WashCyclesState({
    this.status = WashCyclesStatus.initial,
    this.cycles,
    this.startingToken,
    this.error,
    this.tick = 0,
  });

  final WashCyclesStatus status;

  /// `null` tant qu'aucun chargement n'a abouti — à distinguer d'une liste
  /// vide, qui signifie « aucun cycle ».
  final List<WashCycle>? cycles;

  /// Jeton du cycle en cours de démarrage : une seule machine à la fois, pour
  /// que l'on voie exactement laquelle vient d'être lancée.
  final String? startingToken;
  final String? error;

  /// Battement de seconde. Ne porte aucune donnée : il force le rendu pour que
  /// le temps écoulé avance, sans redemander quoi que ce soit au serveur.
  final int tick;

  /// Y a-t-il quelque chose à montrer ?
  ///
  /// Dérivé de la liste, et non d'une énumération d'états. Les deux fois où
  /// l'entrée d'accueil a disparu, c'était parce qu'un état venait d'être
  /// ajouté sans être ajouté à la condition. Ici, un nouvel état est couvert
  /// d'office.
  bool get isEmpty => (cycles ?? const []).isEmpty;

  List<WashCycle> _inState(CycleState state) => (cycles ?? const <WashCycle>[])
      .where((cycle) => cycle.state == state)
      .toList();

  /// Ce qui réclame un geste : lancer la machine, ou la vérifier après un
  /// démarrage refusé.
  List<WashCycle> get toStart => (cycles ?? const <WashCycle>[])
      .where((cycle) => cycle.state.needsAction)
      .toList();

  /// Ce qui tourne — à suivre, pas à faire.
  List<WashCycle> get running => _inState(CycleState.running);

  /// Le cycle à mettre en avant sur l'accueil.
  ///
  /// Un bandeau ne peut en montrer qu'un : on choisit celui qui appelle une
  /// action, sinon celui qui tourne, sinon le dernier terminé. L'ordre traduit
  /// l'urgence — lancer une machine payée passe avant regarder un compte à
  /// rebours, qui passe avant relire une commande finie.
  ///
  /// `null` quand il n'y a rien : le bandeau s'efface alors de lui-même, sans
  /// que l'accueil ait à connaître les états.
  WashCycle? get mostUrgent {
    if (toStart.isNotEmpty) return toStart.first;
    if (running.isNotEmpty) return running.first;
    return justFinished;
  }

  /// Fenêtre au-delà de laquelle un cycle terminé n'a plus rien à annoncer sur
  /// l'accueil.
  static const _fenetreTermine = Duration(hours: 24);

  /// Le dernier cycle terminé, s'il l'est depuis moins de 24 h.
  ///
  /// Cette fenêtre était appliquée par le SERVEUR, et elle a disparu le jour où
  /// « Mes lavages » a dû montrer tout l'historique. Le bandeau d'accueil, lui,
  /// s'est mis à annoncer « Lavage terminé » pendant des jours pour un cycle
  /// récupéré depuis longtemps.
  ///
  /// Les deux surfaces n'ont pas le même objet : la liste est un historique,
  /// le bandeau dit ce qui se passe MAINTENANT. La fenêtre appartient donc au
  /// bandeau, pas à [finished], qui doit rester complet.
  WashCycle? get justFinished {
    final done = finished;
    if (done.isEmpty) return null;

    final dernier = done.first;
    final fin = dernier.endedAt ?? dernier.paidAt;
    return DateTime.now().difference(fin) < _fenetreTermine ? dernier : null;
  }

  /// Le cycle que la feuille de suivi peut montrer.
  ///
  /// Couvre le temps mort entre lavage et séchage, et pas seulement ce qui
  /// tourne. Sans lui, refermer la feuille à cet instant faisait disparaître le
  /// bouton qui permettait de la rouvrir : le client n'avait plus aucun moyen
  /// de revenir à son cycle tant qu'il n'avait pas lancé la sécheuse.
  ///
  /// Le temps mort passe devant ce qui tourne : il attend un geste, un compte
  /// à rebours non.
  WashCycle? get followable {
    final aSecher = _inState(CycleState.dryingToStart);
    if (aSecher.isNotEmpty) return aSecher.first;
    return running.isEmpty ? null : running.first;
  }

  /// TOUS les terminés, du plus récent au plus ancien.
  ///
  /// Sans fenêtre : « Mes lavages » est un historique, et un cycle payé ne doit
  /// pas s'en effacer avec le temps. C'est le bandeau d'accueil qui borne son
  /// horizon — voir [justFinished].
  List<WashCycle> get finished {
    final list = _inState(CycleState.finished);
    list.sort(
      (a, b) => (b.endedAt ?? b.paidAt).compareTo(a.endedAt ?? a.paidAt),
    );
    return list;
  }

  /// Le cycle dont la finition attend encore d'être remise au comptoir.
  ///
  /// Le code venait de la session stockée sur le téléphone. Celle-ci ne couvre
  /// que l'achat fait sur CE téléphone : une vente encaissée au comptoir avec
  /// finition n'affichait donc aucune consigne. Il vient maintenant du cycle,
  /// comme tout le reste de l'écran — une seule source pour les deux surfaces.
  ///
  /// Sans fenêtre de temps, contrairement à [justFinished] : la prestation est
  /// payée et reste due tant que l'agent ne l'a pas prise en charge. C'est le
  /// serveur qui retire le code, et un job d'alerte qui signale les remises
  /// jamais apportées — jamais l'affichage qui les oublie.
  WashCycle? get awaitingHandoff {
    for (final cycle in cycles ?? const <WashCycle>[]) {
      if (cycle.handoffCode != null) return cycle;
    }
    return null;
  }

  /// Les cycles dont l'accueil a quelque chose à dire.
  ///
  /// C'est exactement l'ensemble dans lequel [mostUrgent] puise. Le bandeau
  /// comptait ses « + N autres lavages » sur TOUT l'historique : un client
  /// fidèle y lisait « + 12 autres lavages » alors qu'une seule machine
  /// tournait, les onze autres étant des cycles rendus depuis des semaines.
  ///
  /// Les états étant exclusifs, aucun cycle n'est compté deux fois.
  List<WashCycle> get onHome {
    // Dédoublonné par jeton : un cycle terminé récemment peut être aussi celui
    // qui attend sa remise, et le compter deux fois gonflerait le « + N ».
    final vus = <String>{};
    return [
      ...toStart,
      ...running,
      ?justFinished,
      ?awaitingHandoff,
    ].where((cycle) => vus.add(cycle.token)).toList();
  }

  /// Compteur d'alerte : uniquement ce qui attend une action. Une machine
  /// qui tourne, ou un cycle déjà fini, n'appelle aucun geste.
  int get pendingActionCount => toStart.length;

  WashCyclesState copyWith({
    WashCyclesStatus? status,
    List<WashCycle>? cycles,
    String? startingToken,
    String? error,
    int? tick,
    bool clearError = false,
    bool clearStarting = false,
  }) {
    return WashCyclesState(
      status: status ?? this.status,
      cycles: cycles ?? this.cycles,
      startingToken: clearStarting
          ? null
          : (startingToken ?? this.startingToken),
      error: clearError ? null : (error ?? this.error),
      tick: tick ?? this.tick,
    );
  }

  @override
  List<Object?> get props => [status, cycles, startingToken, error, tick];
}
