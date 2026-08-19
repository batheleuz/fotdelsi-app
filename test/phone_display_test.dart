import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/utils/phone_number.dart';

void main() {
  group('displayPhone', () {
    test('groupe le numéro comme on le dicte', () {
      // Un bloc de neuf chiffres collés est exact mais illisible, et un agent
      // qui recopie à l'oral se trompe d'autant plus qu'il doit les compter.
      expect(displayPhone('771234567'), '77 123 45 67');
    });

    test('accepte une forme avec indicatif', () {
      // Le stockage est canonique, mais rien ne garantit ce qui arrive ici.
      expect(displayPhone('+221771234567'), '77 123 45 67');
    });

    test('rend tel quel ce qu\'il ne sait pas découper', () {
      // Mieux vaut afficher une valeur inattendue que la découper à tort et
      // laisser croire à un autre numéro.
      expect(displayPhone('12345'), '12345');
    });
  });

  group('dialablePhone', () {
    test('rétablit l\'indicatif, qui n\'est jamais stocké', () {
      // Sans lui, un `tel:` dépend du pays configuré sur le téléphone.
      expect(dialablePhone('771234567'), '+221771234567');
    });

    test('ne double pas un indicatif déjà présent', () {
      expect(dialablePhone('+221771234567'), '+221771234567');
    });

    test('ne fabrique rien à partir d\'une valeur incomplète', () {
      expect(dialablePhone('12345'), '12345');
    });
  });
}
