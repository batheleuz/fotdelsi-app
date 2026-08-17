import 'package:equatable/equatable.dart';

/// Où en est le cycle.
///
/// Un énuméré plutôt que trois booléens (`failedToStart`, `running`,
/// `finished`) : ceux-ci laissaient exprimer des combinaisons impossibles —
/// « en cours ET terminé » — et obligeaient à fabriquer une chaîne maison
/// juste pour comparer deux relevés. Ici les états sont exclusifs par
/// construction, et ajouter un cas fait échouer la compilation partout où il
/// faut le traiter.
enum CycleState {
  /// Payé, machine jamais lancée.
  toStart,

  /// Un démarrage a été tenté et la machine a refusé. L'agent n'agit pas
  /// pareil : il ira d'abord vérifier la machine.
  failed,

  /// La machine tourne.
  running,

  /// Le lavage est fini, la sécheuse n'est pas lancée.
  ///
  /// Un temps mort au milieu du cycle, propre aux formules avec séchage : le
  /// serveur garde la session `RUNNING`, mais plus aucune machine ne tourne et
  /// c'est au client de lancer la seconde. Sans cet état, l'écran continuait
  /// d'égrener le temps écoulé sans rien annoncer — et le client attendait
  /// devant une machine arrêtée.
  dryingToStart,

  /// Terminé.
  finished;

  /// [canStartDrying] vient du serveur : le statut seul ne suffit pas, la
  /// session reste `RUNNING` pendant tout le temps mort entre les deux temps.
  static CycleState fromApi(
    String? sessionStatus, {
    bool canStartDrying = false,
  }) {
    if (canStartDrying) return CycleState.dryingToStart;

    return switch (sessionStatus) {
      'RUNNING' => CycleState.running,
      'DONE' => CycleState.finished,
      'FAILED' => CycleState.failed,
      // PENDING, et tout statut qu'une version ultérieure du backend
      // introduirait : on retombe sur « à démarrer » plutôt que de perdre la
      // ligne. Un cycle payé ne doit jamais disparaître de l'écran.
      _ => CycleState.toStart,
    };
  }

  /// Réclame un geste maintenant.
  bool get needsAction =>
      this == toStart || this == failed || this == dryingToStart;
}

/// Cycle vendu au comptoir pour un client sans application.
///
/// Existe parce qu'encaisser, lancer la machine et suivre le cycle sont trois
/// gestes séparés dans le temps. Tant que ces informations ne vivaient que
/// dans l'écran de vente, le quitter rendait la commande introuvable — alors
/// que l'argent, lui, était bien pris.
///
/// Ne contient QUE des ventes au comptoir : un achat fait par le client depuis
/// son application se démarre depuis son propre téléphone. L'agent ne sait pas
/// si le linge est chargé, et lancer une machine vide gaspillerait le cycle.
class WashCycle extends Equatable {
  const WashCycle({
    required this.token,
    required this.machineId,
    required this.amount,
    required this.paidAt,
    required this.state,
    this.startedAt,
    this.endedAt,
    this.remainingSeconds,
    this.soldByAgentName,
    this.withDrying = false,
    this.isDrying = false,
    this.washCompletedAt,
    this.handoffCode,
    this.machineName,
    this.dryerMachineName,
    this.sizeKg,
    this.formulaLabel,
    this.customerName,
    this.customerPhone,
  });

  /// Jeton de démarrage — la clé que l'agent avait perdue.
  final String token;
  final String machineId;
  /// Machine ACHETÉE — la laveuse pour une formule à deux temps.
  final String? machineName;

  /// Sécheuse choisie pour le second temps, `null` tant qu'elle ne l'est pas.
  final String? dryerMachineName;
  final int? sizeKg;
  final String? formulaLabel;
  final int amount;
  final String? customerName;
  final String? customerPhone;
  final DateTime paidAt;

  final CycleState state;

  /// Instant de démarrage — sert à afficher le temps écoulé.
  final DateTime? startedAt;

  /// Fin du cycle, pour afficher « terminé il y a … ».
  final DateTime? endedAt;

  /// Temps restant annoncé par la MACHINE au dernier relevé. C'est elle qui
  /// fait autorité sur la durée réelle, pas une soustraction locale.
  final int? remainingSeconds;

  /// Agent ayant encaissé. Utile aux relèves d'équipe : celui qui prend le
  /// service doit savoir de qui vient la vente qu'il s'apprête à lancer.
  /// `null` si le compte a depuis été supprimé.
  final String? soldByAgentName;

  /// Temps écoulé depuis le démarrage, recalculé à chaque affichage.
  ///
  /// Se fige à la fin du cycle : c'est alors la durée totale, et non un
  /// compteur qui continuerait de courir après coup.
  /// La prestation payée comporte un séchage : le cycle se joue en deux temps.
  final bool withDrying;

  /// La sécheuse tourne : second temps en cours.
  ///
  /// Ne se déduit pas de [state] : le séchage est `running`, exactement comme
  /// le lavage. C'est le serveur qui tranche, et c'est ce drapeau qui fait la
  /// différence entre les deux temps à l'affichage.
  final bool isDrying;

  /// Fin du lavage, `null` tant qu'il tourne. Sert à mesurer depuis quand le
  /// linge attend d'être passé en sécheuse.
  final DateTime? washCompletedAt;

  /// Code à présenter au comptoir pour la finition déjà payée — pliage,
  /// repassage —, `null` s'il n'y a rien à remettre.
  ///
  /// Le serveur ne le donne qu'une fois TOUTES les machines arrêtées :
  /// l'annoncer plus tôt demandait au client d'apporter un linge encore
  /// enfermé dans le tambour.
  final String? handoffCode;

  /// Machine que le client a sous les yeux à cet instant.
  ///
  /// La laveuse identifie la commande ; pendant le séchage, c'est pourtant la
  /// sécheuse qui tourne, et la nommer « Lavage 12kg » désignerait une machine
  /// arrêtée.
  String? get runningMachineName =>
      isDrying ? (dryerMachineName ?? machineName) : machineName;

  Duration? get elapsed => startedAt == null
      ? null
      : (endedAt ?? DateTime.now()).difference(startedAt!);

  @override
  List<Object?> get props => [
    token,
    // `state` et `remainingSeconds` DOIVENT figurer ici. Avec le seul jeton,
    // deux relevés successifs du même cycle étaient jugés identiques : Bloc
    // ignorait l'émission et l'écran gardait l'ancien temps restant. Il ne
    // bougeait qu'en quittant puis rouvrant la page, ce qui recréait le cubit.
    state,
    isDrying,
    remainingSeconds,
    startedAt,
    endedAt,
    washCompletedAt,
    handoffCode,
  ];
}
