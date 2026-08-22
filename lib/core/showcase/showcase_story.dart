/// Le contenu inventé que montrent les captures d'écran.
///
/// ─── C'est le seul fichier à modifier pour changer ce qu'on voit ───
///
/// Rien ici n'est du vrai : ni le nom, ni le numéro, ni les cycles. C'est
/// volontaire. Une capture prise sur des données réelles exposerait le numéro
/// et les achats d'un client sur une fiche App Store publique — donc on ne
/// prend jamais de capture sur des données réelles, et le mode vitrine existe
/// pour rendre ça inutile.
///
/// **Les prix, eux, sont vrais** : repris de la grille officielle
/// (`backend/src/shared/infrastructure/persistence/seeds/serviceFormulas.seed.ts`).
/// Une fiche App Store qui annonce un tarif faux est un engagement commercial
/// faux — c'est le seul endroit où l'invention n'est pas permise.
///
/// Toutes les dates sont calculées **au moment de l'appel**, relativement à
/// maintenant. Le lavage affiche donc toujours un décompte plausible, quel que
/// soit le jour où on reprend les captures — et il tourne réellement à
/// l'écran, ce qu'un horodatage figé ne ferait pas.
library;

abstract final class ShowcaseStory {
  const ShowcaseStory._();

  // ─────────────────────────── Scène ───────────────────────────

  /// Quelle situation l'accueil doit montrer.
  ///
  ///     flutter run -t lib/main_showcase.dart --dart-define=SCENE=remise
  ///
  /// Deux captures veulent le haut de l'accueil, et une seule peut l'occuper :
  ///
  ///  • `lavage` (défaut) — le lavage en cours et son décompte. C'est la
  ///    capture principale : elle dit ce que fait le produit.
  ///  • `remise` — le bandeau « Apportez votre linge au comptoir » et son code.
  ///    Elle explique les formules avec pliage et repassage.
  ///
  /// Sans ce commutateur, le bandeau de remise gagne toujours la première
  /// place et le lavage en cours n'est jamais photographiable sur l'accueil.
  static const String scene = String.fromEnvironment(
    'SCENE',
    defaultValue: 'lavage',
  );

  static bool get _montreLaRemise => scene == 'remise';

  // ─────────────────────────── Identité ───────────────────────────

  /// Nom affiché en tête d'accueil et sur les cycles.
  static const String clientName = 'Awa Fall';

  /// Numéro fictif. Format sénégalais valide pour que l'affichage soit exact
  /// (`displayPhone` le met en forme), mais suite volontairement lisible comme
  /// un exemple.
  static const String clientPhone = '+221771234567';

  /// Jeton de session client : 64 caractères hexadécimaux, comme le vrai
  /// (`clientAuthRequired` refuse tout autre format).
  static const String sessionToken =
      '5howca5e0000000000000000000000000000000000000000000000000000d3m0';

  // ─────────────────────────── Horodatage ───────────────────────────

  static String _ago(Duration d) =>
      DateTime.now().toUtc().subtract(d).toIso8601String();

  static String _within(Duration d) =>
      DateTime.now().toUtc().add(d).toIso8601String();

  // ─────────────────────────── Réponses ───────────────────────────

  static Map<String, dynamic> envelope(Object? data) => {
    'code': '200',
    'message': 'OK',
    'data': data,
  };

  /// `GET /status` — aucun service en panne.
  ///
  /// Un `available: false` ferait apparaître un bandeau orange en haut de
  /// l'accueil. Correct en exploitation, désastreux sur une fiche App Store.
  static Map<String, dynamic> status() => {
    'services': {
      'MACHINES': {'available': true},
      'WAVE': {'available': true},
      'ORANGE_MONEY': {'available': true},
    },
  };

  /// `GET /service-formulas` — la grille tarifaire réelle.
  static Map<String, dynamic> formulas() => {
    // Laverie ouverte, explicitement : sans ce bloc l'app retombe déjà sur
    // « ouvert », mais une capture App Store ne doit dépendre d'aucun défaut —
    // un bandeau « Service fermé » y passerait pour une panne.
    'businessHours': {
      'enabled': false,
      'opensAt': '10:00',
      'closesAt': '23:00',
      'open': true,
      'timezone': 'Africa/Dakar',
    },
    'formulas': [
      _formula(
        code: 'LAVAGE',
        label: 'Lavage',
        items: const ['WASHING'],
        order: 1,
        prices: const {12: 4000, 15: 5000, 20: 6000},
      ),
      _formula(
        code: 'LAVAGE_SECHAGE',
        label: 'Lavage & Séchage',
        items: const ['WASHING', 'DRYING'],
        order: 2,
        prices: const {12: 7000, 15: 8000, 20: 9000},
      ),
      _formula(
        code: 'LAVAGE_SECHAGE_PLIAGE',
        label: 'Prêt à ranger',
        items: const ['WASHING', 'DRYING', 'FOLDING'],
        order: 3,
        prices: const {12: 9000, 15: 10000, 20: 12000},
      ),
      _formula(
        code: 'LAVAGE_SECHAGE_PLIAGE_REPASSAGE',
        label: 'Prêt à porter',
        items: const ['WASHING', 'DRYING', 'FOLDING', 'IRONING'],
        order: 4,
        prices: const {12: 11000, 15: 13000, 20: 15000},
      ),
    ],
  };

  static const Map<String, String> _itemLabels = {
    'WASHING': 'Lavage',
    'DRYING': 'Séchage',
    'FOLDING': 'Pliage',
    'IRONING': 'Repassage',
  };

  static Map<String, dynamic> _formula({
    required String code,
    required String label,
    required List<String> items,
    required int order,
    required Map<int, int> prices,
  }) {
    // Pliage et repassage se font à la main : ces deux prestations seules
    // exigent la présence d'un agent, et c'est ce qui déclenche le parcours
    // de remise au comptoir.
    bool manuel(String c) => c == 'FOLDING' || c == 'IRONING';
    return {
      'code': code,
      'label': label,
      'items': [
        for (final c in items)
          {'code': c, 'label': _itemLabels[c], 'requiresAgent': manuel(c)},
      ],
      'includesDrying': items.contains('DRYING'),
      'requiresAgent': items.any(manuel),
      'selfServiceEnabled': true,
      'displayOrder': order,
      'prices': [
        for (final e in prices.entries) {'sizeKg': e.key, 'price': e.value},
      ],
      // Tout ouvert : la vitrine ne montre jamais un service fermé.
      'availability': {'selfService': true, 'dropOff': true},
    };
  }

  /// `GET /machines` — un parc qui respire : de la place, et un cycle en cours.
  ///
  /// Tout afficher comme libre donnerait une laverie déserte ; tout occuper
  /// donnerait une laverie inutilisable. Une seule machine prise, celle du
  /// client, et c'est la sienne qu'il retrouve sur l'accueil.
  static List<Map<String, dynamic>> machines() => [
    _machine(
      id: '1',
      code: 'WASH_01',
      name: 'Laveuse 01',
      size: 12,
      price: 4000,
    ),
    _machine(
      id: '2',
      code: 'WASH_02',
      name: 'Laveuse 02',
      size: 15,
      price: 5000,
    ),
    _machine(
      id: '3',
      code: 'WASH_03',
      name: 'Laveuse 03',
      size: 20,
      price: 6000,
      inUse: true,
      remainSeconds: _washRemainingSeconds,
    ),
    _machine(
      id: '4',
      code: 'DRY_01',
      name: 'Sécheuse 01',
      price: 3000,
      dryer: true,
    ),
    _machine(
      id: '5',
      code: 'DRY_02',
      name: 'Sécheuse 02',
      price: 3000,
      dryer: true,
    ),
  ];

  static Map<String, dynamic> _machine({
    required String id,
    required String code,
    required String name,
    required int price,
    int? size,
    bool dryer = false,
    bool inUse = false,
    int remainSeconds = 0,
  }) => {
    'id': id,
    'code': code,
    'name': name,
    'type': dryer ? 'SECHEUSE' : 'LAVEUSE',
    'status': inUse ? 'IN_USE' : 'AVAILABLE',
    'remain_time': remainSeconds,
    'price': price,
    'size': size,
  };

  // ─────────────────────────── Le récit ───────────────────────────

  /// Temps restant du lavage en cours, en secondes.
  ///
  /// 23 minutes : assez pour que le décompte se lise d'un coup d'œil, pas
  /// assez pour qu'il paraisse interminable. Une valeur ronde (30 min) se
  /// lirait comme une maquette ; celle-ci se lit comme un vrai cycle.
  static const int _washRemainingSeconds = 23 * 60 + 12;

  /// `GET /me/cycles` — quatre cycles qui racontent tout le produit.
  ///
  /// L'ordre compte : le cycle en cours arrive en tête, c'est lui que
  /// l'accueil met en avant et c'est la capture principale.
  static Map<String, dynamic> myCycles() => {
    'cycles': [for (final c in _cycles()) ?c],
  };

  static List<Map<String, dynamic>?> _cycles() => [
    // 1. En cours — le héros. Lavage démarré il y a 12 min sur la Laveuse 03.
    {
      'token': 'showcase-running',
      'machineId': '3',
      'machineName': 'Laveuse 03',
      'dryerMachineName': null,
      'sizeKg': 20,
      'formulaLabel': 'Lavage & Séchage',
      'amount': 9000,
      'customerName': clientName,
      'customerPhone': clientPhone,
      'paidAt': _ago(const Duration(minutes: 14)),
      'sessionStatus': 'RUNNING',
      'canStartDrying': false,
      'startedAt': _ago(const Duration(minutes: 12)),
      'endedAt': null,
      'remainingSeconds': _washRemainingSeconds,
      'withDrying': true,
      'isDrying': false,
      'washCompletedAt': null,
      'handoffCode': null,
      'dropOffId': null,
    },
    // 2. Terminé, linge encore chez le client : le code de remise s'affiche.
    //    C'est l'écran qui explique le service « Prêt à porter » — mais son
    //    bandeau prend le haut de l'accueil, donc il n'apparaît que dans la
    //    scène qui lui est consacrée.
    if (!_montreLaRemise)
      null
    else
      {
        'token': 'showcase-handoff',
        'machineId': '1',
        'machineName': 'Laveuse 01',
        'dryerMachineName': 'Sécheuse 01',
        'sizeKg': 12,
        'formulaLabel': 'Prêt à porter',
        'amount': 11000,
        'customerName': clientName,
        'customerPhone': clientPhone,
        'paidAt': _ago(const Duration(hours: 3, minutes: 40)),
        'sessionStatus': 'DONE',
        'canStartDrying': false,
        'startedAt': _ago(const Duration(hours: 3, minutes: 30)),
        'endedAt': _ago(const Duration(hours: 1, minutes: 50)),
        'remainingSeconds': null,
        'withDrying': true,
        'isDrying': false,
        'washCompletedAt': _ago(const Duration(hours: 2, minutes: 35)),
        'handoffCode': 'A47',
        'dropOffId': null,
      },
    // 3. Linge remis à l'agent : le code a disparu, le suivi prend sa place.
    //    C'est l'entrée vers l'écran de finition (capture n° 5).
    {
      'token': 'showcase-finishing',
      'machineId': '2',
      'machineName': 'Laveuse 02',
      'dryerMachineName': 'Sécheuse 02',
      'sizeKg': 15,
      'formulaLabel': 'Prêt à ranger',
      'amount': 10000,
      'customerName': clientName,
      'customerPhone': clientPhone,
      'paidAt': _ago(const Duration(hours: 6)),
      'sessionStatus': 'DONE',
      'canStartDrying': false,
      'startedAt': _ago(const Duration(hours: 5, minutes: 50)),
      'endedAt': _ago(const Duration(hours: 4)),
      'remainingSeconds': null,
      'withDrying': true,
      'isDrying': false,
      'washCompletedAt': _ago(const Duration(hours: 4, minutes: 45)),
      'handoffCode': null,
      'dropOffId': finishingDropOffId,
    },
    // 4. Cycle d'avant-hier — donne de la profondeur à « Mes lavages » sans
    //    encombrer l'accueil : au-delà de 24 h, la carte active l'ignore.
    {
      'token': 'showcase-past',
      'machineId': '1',
      'machineName': 'Laveuse 01',
      'dryerMachineName': null,
      'sizeKg': 12,
      'formulaLabel': 'Lavage',
      'amount': 4000,
      'customerName': clientName,
      'customerPhone': clientPhone,
      'paidAt': _ago(const Duration(days: 2, hours: 2)),
      'sessionStatus': 'DONE',
      'canStartDrying': false,
      'startedAt': _ago(const Duration(days: 2, hours: 2)),
      'endedAt': _ago(const Duration(days: 2, hours: 1)),
      'remainingSeconds': null,
      'withDrying': false,
      'isDrying': false,
      'washCompletedAt': _ago(const Duration(days: 2, hours: 1)),
      'handoffCode': null,
      'dropOffId': null,
    },
  ];

  /// Identifiant du dépôt en cours de finition, partagé entre le cycle n° 3
  /// et `GET /me/dropoffs/:id` — sinon le lien du cycle ouvrirait un écran
  /// vide.
  static const String finishingDropOffId = 'showcase-dropoff-1';

  /// `GET /me/payments/pending` — aucun.
  ///
  /// Un paiement en attente afficherait « Confirmer le paiement » en haut de
  /// l'accueil : un bandeau d'échec, exactement ce qu'une fiche App Store ne
  /// doit pas montrer.
  static Map<String, dynamic> pendingPayments() => {'payments': const []};

  /// `GET /me/profile`.
  static Map<String, dynamic> profile() => {
    'phone': clientPhone,
    'fullName': clientName,
  };

  /// `GET /me/dropoffs` — le libre-service n'y figure pas (décision produit :
  /// seuls les dépôts d'origine AGENT sont listés). La vitrine respecte la
  /// règle, sinon la capture montrerait un écran que le client ne voit pas.
  static List<Map<String, dynamic>> myDropOffs() => const [];

  /// `GET /me/dropoffs/:id` — la finition à mi-parcours.
  ///
  /// `IN_PROGRESS` est le seul statut qui fait respirer la pastille du badge :
  /// c'est celui qui donne une capture vivante plutôt qu'une liste inerte.
  static Map<String, dynamic> finishingDropOff() => {
    'id': finishingDropOffId,
    'code': 'B12',
    'customerName': clientName,
    'contactPhone': clientPhone,
    'laundry': {
      'pieces': 14,
      'types': ['COLORED', 'WHITE'],
      'instructions': 'Chemises sur cintre, merci.',
    },
    'status': 'IN_PROGRESS',
    'origin': 'SELF_SERVICE',
    'machineId': '2',
    'washSessionId': 'showcase-finishing',
    'withDrying': true,
    'dryerMachineId': '5',
    'dryStartedAt': _ago(const Duration(hours: 4, minutes: 45)),
    'washCompletedAt': _ago(const Duration(hours: 4, minutes: 45)),
    'dryCompletedAt': _ago(const Duration(hours: 4)),
    'paymentId': 'showcase-payment-1',
    'creationDay': DateTime.now().toIso8601String().substring(0, 10),
    // Sur un dépôt libre-service la timeline lit ces deux champs à l'envers de
    // ce que leur nom suggère (voir `DropOffTimeline`) : `receivedAt` porte
    // « Lavé par le client » et `startedAt` « Apporté au comptoir ». Les
    // intervertir donne un suivi où le linge arrive au comptoir avant d'avoir
    // été lavé — invisible en relisant le JSON, flagrant sur la capture.
    'receivedAt': _ago(const Duration(hours: 4)),
    'startedAt': _ago(const Duration(hours: 3, minutes: 20)),
    'readyAt': null,
    'collectedAt': null,
    'terminalReason': null,
  };

  /// Réservation encore tenue — utile si une capture passe par le paiement.
  static Map<String, dynamic> reservationHold() => {
    'reservedUntil': _within(const Duration(minutes: 9)),
  };
}
