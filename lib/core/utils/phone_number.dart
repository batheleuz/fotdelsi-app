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
