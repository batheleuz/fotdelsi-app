import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/presentation/bloc/machines_bloc.dart';

/// Le backend pousse `machine.state` MACHINE PAR MACHINE : chaque message ne
/// décrit qu'un seul équipement. L'affecter tel quel à la liste la réduisait à
/// un élément, et faisait disparaître de l'écran la machine d'une session en
/// cours — bouton « Démarrer » compris.
Machine machine(String id, MachineStatus status) => Machine(
  id: id,
  code: 'M-$id',
  name: 'Machine $id',
  type: MachineType.washer,
  status: status,
  size: 12,
  price: 4000,
  remainTime: 0,
);

void main() {
  group('MachinesBloc — fusion temps réel', () {
    final parc = [
      machine('a', MachineStatus.available),
      machine('b', MachineStatus.available),
      machine('c', MachineStatus.available),
    ];

    test('met à jour une machine sans supprimer les autres', () {
      final merged = MachinesBloc.mergeForTest(parc, [
        machine('b', MachineStatus.inUse),
      ]);

      // Le cœur du bug : la liste tombait à un seul élément.
      expect(merged, hasLength(3));
      expect(merged.firstWhere((m) => m.id == 'b').status, MachineStatus.inUse);
    });

    test('conserve la machine ciblée quand une AUTRE bouge', () {
      // C'est exactement ce qui faisait clignoter le bouton « Démarrer » :
      // n'importe quel mouvement ailleurs dans le parc effaçait la machine
      // de la session en cours.
      final merged = MachinesBloc.mergeForTest(parc, [
        machine('c', MachineStatus.inUse),
      ]);

      expect(merged.any((m) => m.id == 'a'), isTrue);
    });

    test('ajoute une machine encore inconnue', () {
      final merged = MachinesBloc.mergeForTest(parc, [
        machine('d', MachineStatus.available),
      ]);

      expect(merged, hasLength(4));
    });

    test('ne vide jamais la liste sur un message vide', () {
      // Une reconnexion ou un message mal formé ne doit pas faire disparaître
      // le parc : seul un rechargement complet fait autorité sur sa
      // composition.
      expect(MachinesBloc.mergeForTest(parc, const []), hasLength(3));
    });

    test('préserve l\'ordre d\'affichage', () {
      // Les machines sont triées à l'affichage ; un réordonnancement à chaque
      // message ferait sauter les cartes sous le doigt du client.
      final merged = MachinesBloc.mergeForTest(parc, [
        machine('a', MachineStatus.inUse),
      ]);

      expect(merged.map((m) => m.id).toList(), ['a', 'b', 'c']);
    });
  });
}
