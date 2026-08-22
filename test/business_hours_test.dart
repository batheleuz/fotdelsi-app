import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/features/catalog/domain/entities/business_hours.dart';

void main() {
  group('BusinessHours — lecture de la réponse serveur', () {
    test('lit la plage et l\'état d\'ouverture', () {
      final hours = BusinessHours.fromJson(const {
        'enabled': true,
        'opensAt': '10:00',
        'closesAt': '23:00',
        'open': false,
        'timezone': 'Africa/Dakar',
      });

      expect(hours.isClosed, isTrue);
      expect(hours.opensAtLabel, '10h');
      expect(hours.closesAtLabel, '23h');
    });

    test('un serveur plus ancien laisse la laverie ouverte', () {
      // Sans ce défaut, une réponse sans le bloc afficherait un bandeau de
      // fermeture sans horaire — pire que pas de bandeau du tout.
      final hours = BusinessHours.fromJson(const {});

      expect(hours.isClosed, isFalse);
    });

    test('rien à annoncer quand aucun horaire n\'est appliqué', () {
      final hours = BusinessHours.fromJson(const {
        'enabled': false,
        'opensAt': '10:00',
        'closesAt': '23:00',
        'open': true,
      });

      expect(hours.isClosed, isFalse);
    });

    test('met en forme les heures avec minutes', () {
      final hours = BusinessHours.fromJson(const {
        'enabled': true,
        'opensAt': '09:30',
        'closesAt': '23:59',
        'open': true,
      });

      expect(hours.opensAtLabel, '9h30');
      expect(hours.closesAtLabel, '23h59');
    });
  });
}
