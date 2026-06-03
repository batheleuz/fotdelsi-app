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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 160,
      ),
      itemCount: total,
      itemBuilder: (context, index) {
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
      },
    );
  }
}
