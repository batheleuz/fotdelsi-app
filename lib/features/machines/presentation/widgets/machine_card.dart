import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_session_cubit.dart';
import '../../domain/entities/machine.dart';
import 'machine_countdown.dart';
import 'machine_status_badge.dart';
import 'machine_type_tile.dart';

/// Libellé de service affiché : « Laveuse »→« Lavage », « Sécheuse »→« Séchage ».
String machineServiceLabel(String name) => name
    .replaceAll('Laveuse', 'Lavage')
    .replaceAll('Sécheuse', 'Séchage')
    .replaceAll('Secheuse', 'Séchage');

/// Carte d'une machine : icône de type, badge d'état, nom, et — selon le cas —
/// le bouton « Démarrer » (paiement confirmé), le temps restant, ou rien.
class MachineCard extends StatelessWidget {
  const MachineCard({super.key, required this.machine, this.onTap});

  final Machine machine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final offline = machine.status == MachineStatus.offline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MachineTypeTile(type: machine.type, offline: offline),
                const Spacer(),
                MachineStatusBadge(status: machine.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              machineServiceLabel(machine.name),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            _Footer(machine: machine),
          ],
        ),
      ),
    );
  }
}

/// Bas de carte, dépendant de la session de lavage en cours :
///  - paiement confirmé sur CETTE machine → bouton « Démarrer » ;
///  - machine en cours → temps restant ;
///  - sinon → rien (le badge d'état en haut suffit).
class _Footer extends StatelessWidget {
  const _Footer({required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WashSessionCubit, WashSessionState>(
      buildWhen: (p, c) =>
          p.hasConfirmedPendingSession != c.hasConfirmedPendingSession ||
          p.isStarting != c.isStarting ||
          p.pendingSession?.machineId != c.pendingSession?.machineId,
      builder: (context, session) {
        final pendingHere =
            session.hasConfirmedPendingSession &&
            session.pendingSession?.machineId == machine.id;

        if (pendingHere) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _StartButton(
              loading: session.isStarting,
              onPressed: () =>
                  context.read<WashSessionCubit>().startMachine(machine),
            ),
          );
        }
        if (machine.isInUse) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: MachineCountdown(seconds: machine.remainTime),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.play_arrow_rounded, size: 18),
        label: const Text(
          'Démarrer',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
