import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_curves.dart';
import '../../domain/entities/machine.dart';
import 'machine_card.dart';

/// Grille 2 colonnes des machines, avec animation d'entrée échelonnée
/// (chaque carte apparaît avec un léger décalage en fondu + glissement).
class MachineGrid extends StatefulWidget {
  const MachineGrid({super.key, required this.machines, this.onTapMachine});

  final List<Machine> machines;
  final ValueChanged<Machine>? onTapMachine;

  @override
  State<MachineGrid> createState() => _MachineGridState();
}

class _MachineGridState extends State<MachineGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.slow,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _intervalFor(int index, int total) {
    final start = (index / total) * 0.5;
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
          curve: AppCurves.standard),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.machines.length;
    // Deux colonnes indépendantes (« masonry ») : chaque carte prend la hauteur
    // de son contenu — pas de cellule à hauteur fixe, donc pas de vide sous les
    // cartes courtes. Répartition en quinconce (pair→gauche, impair→droite).
    final left = <int>[];
    final right = <int>[];
    for (var i = 0; i < total; i++) {
      (i.isEven ? left : right).add(i);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _column(left)),
        const SizedBox(width: 12),
        Expanded(child: _column(right)),
      ],
    );
  }

  Widget _column(List<int> indices) {
    final total = widget.machines.length;
    return Column(
      children: [
        for (final index in indices)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _animatedCard(index, total),
          ),
      ],
    );
  }

  Widget _animatedCard(int index, int total) {
    final machine = widget.machines[index];
    final anim = _intervalFor(index, total);
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(anim),
        child: MachineCard(
          machine: machine,
          onTap: () => widget.onTapMachine?.call(machine),
        ),
      ),
    );
  }
}
