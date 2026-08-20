/// Indicatif du Sénégal : accepté à la saisie, jamais transmis.
const _countryCode = '221';

/// Forme canonique d'un numéro : **9 chiffres, sans indicatif**.
///
/// C'est le seul format que le backend enregistre, parce que le numéro y sert
/// de clé fonctionnelle — il relie un client à ses paiements, ses dépôts et ses
/// lavages. Tant que deux écritures coexistaient, la même personne pouvait
/// exister sous « +221771234567 » et « 771234567 », et aucune comparaison ne
/// la retrouvait : c'est exactement ce qui vidait la liste « Mes lavages ».
///
/// Le serveur normalise déjà ce qu'il reçoit. On le fait aussi ici pour que la
/// valeur gardée sur le téléphone — celle qui pré-remplit les champs — soit
/// dans la même forme que celle du serveur, et pour ne pas dépendre de ce que
/// l'utilisateur a tapé.
///
/// L'indicatif reste une affaire d'AFFICHAGE : les champs de saisie le montrent
/// à côté de la zone de texte, et les fiches l'ajoutent à la lecture.
String normalizePhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');

  // Ne retirer l'indicatif que s'il reste un numéro derrière : mieux vaut
  // transmettre une valeur inattendue, que le serveur refusera clairement,
  // qu'une valeur tronquée qui désignerait quelqu'un d'autre.
  return digits.startsWith(_countryCode) && digits.length > 9
      ? digits.substring(_countryCode.length)
      : digits;
}

/// Numéro tel qu'on le montre à un humain : « 77 123 45 67 ».
///
/// Le groupement est celui que les gens lisent et dictent au Sénégal — deux
/// chiffres d'opérateur, puis trois groupes. Un bloc de neuf chiffres collés
/// est exact mais illisible, et un agent qui recopie un numéro à l'oral se
/// trompe d'autant plus qu'il doit compter les caractères.
///
/// Toute entrée non canonique ressort telle quelle : mieux vaut afficher une
/// valeur inattendue que la découper à tort et laisser croire à un autre numéro.
String displayPhone(String canonical) {
  final digits = normalizePhone(canonical);
  if (digits.length != 9) return canonical;

  return '${digits.substring(0, 2)} ${digits.substring(2, 5)} '
      '${digits.substring(5, 7)} ${digits.substring(7)}';
}

/// Numéro sous la forme attendue par un composeur : indicatif inclus.
///
/// L'indicatif n'est pas enregistré — il ne l'est jamais — mais un `tel:` sans
/// lui dépend du pays configuré sur le téléphone. On le rétablit ici, au seul
/// endroit qui en a besoin.
String dialablePhone(String canonical) {
  final digits = normalizePhone(canonical);
  return digits.length == 9 ? '+$_countryCode$digits' : digits;
}
