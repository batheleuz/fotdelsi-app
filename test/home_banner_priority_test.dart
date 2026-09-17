import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/features/wash_session/domain/entities/wash_cycle.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_cycles_cubit.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/active_session_card.dart';

/// Cycle d'une formule avec finition : le serveur pose son code de remise dès
/// la confirmation du paiement, bien avant que le linge soit lavé.
WashCycle _cycle({
  required String token,
  required CycleState state,
  String? handoffCode,
}) => WashCycle(
  token: token,
  machineId: 'machine-$token',
  amount: 9000,
  paidAt: DateTime.now(),
  state: state,
  formulaLabel: 'Prêt à porter',
  handoffCode: handoffCode,
  startedAt: state == CycleState.toStart
      ? null
      : DateTime.now().subtract(const Duration(minutes: 30)),
  endedAt: state == CycleState.finished ? DateTime.now() : null,
  withDrying: true,
);

WashCyclesState _state(List<WashCycle> cycles) =>
    const WashCyclesState().copyWith(
      status: WashCyclesStatus.success,
      cycles: cycles,
    );

void main() {
  group('bandeau d\'accueil — geste avant consigne', () {
    test('montre le CYCLE quand la machine reste à démarrer', () {
      // Le bug signalé le 26 août : le client paie une formule avec pliage,
      // le serveur crée aussitôt la remise avec son code, et le bandeau
      // affichait ce code au lieu du bouton de démarrage. Il fallait ouvrir
      // « Cycles Directs » pour lancer sa machine.
      final state = _state([
        _cycle(token: 'a', state: CycleState.toStart, handoffCode: '8X5Z'),
      ]);

      expect(homeBannerFor(state), HomeBanner.cycle);
    });

    test('montre le CYCLE quand le séchage reste à lancer', () {
      // Même situation au second temps : le linge est trempé, le code de
      // remise ne sert à rien encore.
      final state = _state([
        _cycle(
          token: 'a',
          state: CycleState.dryingToStart,
          handoffCode: '8X5Z',
        ),
      ]);

      expect(homeBannerFor(state), HomeBanner.cycle);
    });

    test('montre la REMISE une fois le cycle terminé', () {
      // C'est là que le code sert : le linge est lavé, il faut l'apporter.
      final state = _state([
        _cycle(token: 'a', state: CycleState.finished, handoffCode: '8X5Z'),
      ]);

      expect(homeBannerFor(state), HomeBanner.handoff);
    });

    test('le geste l\'emporte même sur une AUTRE remise en attente', () {
      // Deux cycles : l'un fini et à remettre, l'autre à démarrer. Le second
      // est le seul à réclamer quelque chose.
      final state = _state([
        _cycle(token: 'a', state: CycleState.finished, handoffCode: '8X5Z'),
        _cycle(token: 'b', state: CycleState.toStart),
      ]);

      expect(homeBannerFor(state), HomeBanner.cycle);
    });

    test('montre la REMISE quand rien n\'attend de geste', () {
      final state = _state([
        _cycle(token: 'a', state: CycleState.finished, handoffCode: '8X5Z'),
        _cycle(token: 'b', state: CycleState.running),
      ]);

      expect(homeBannerFor(state), HomeBanner.handoff);
    });

    test('montre le CYCLE quand aucune finition n\'est due', () {
      final state = _state([_cycle(token: 'a', state: CycleState.running)]);

      expect(homeBannerFor(state), HomeBanner.cycle);
    });

    test('ne montre rien sans aucun cycle', () {
      expect(homeBannerFor(_state(const [])), HomeBanner.none);
    });
  });
}
