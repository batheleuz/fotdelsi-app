import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/core/utils/phone_number.dart';

void main() {
  group('normalizePhone', () {
    test('ramène toutes les écritures d\'un même numéro à la même valeur', () {
      // C'est l'invariant qui compte : le numéro sert de clé côté serveur, donc
      // deux écritures produiraient deux clients.
      for (final saisie in [
        '771234567',
        '+221771234567',
        '221771234567',
        '+221 77 123 45 67',
        '77-123-45-67',
      ]) {
        expect(normalizePhone(saisie), '771234567', reason: saisie);
      }
    });

    test('ne tronque pas un numéro de 9 chiffres commençant par 221', () {
      // Retirer « 221 » ici fabriquerait un numéro à 6 chiffres, donc un autre
      // abonné. Mieux vaut laisser le serveur le refuser franchement.
      expect(normalizePhone('221345678'), '221345678');
    });

    test('laisse passer une saisie incomplète telle quelle', () {
      // Le champ peut être lu avant que l'utilisateur ait fini de taper : ce
      // n'est pas ici qu'on valide, c'est ici qu'on met en forme.
      expect(normalizePhone('77'), '77');
      expect(normalizePhone(''), '');
    });
  });
}
