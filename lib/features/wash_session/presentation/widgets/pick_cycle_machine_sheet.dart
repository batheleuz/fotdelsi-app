import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/presentation/bloc/machines_bloc.dart';
import 'package:fotdelsi/features/machines/presentation/bloc/machines_event.dart';
import 'confirm_start_sheet.dart';
import 'start_command_sent_sheet.dart';

typedef StartSelectedMachine = Future<String?> Function(Machine machine);

/// Sélectionne la machine physique au moment du démarrage.
///
/// La capacité achetée reste le tarif de référence ; elle ne réserve plus un
/// appareil. Toute machine libre du bon type peut exécuter le cycle.
Future<bool> showPickCycleMachineSheet(
  BuildContext context, {
  required MachineType machineType,
  required StartSelectedMachine onStart,
}) async {
  final started = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: serviceLocator<MachinesBloc>(),
      child: _PickCycleMachine(machineType: machineType, onStart: onStart),
    ),
  );
  return started ?? false;
}

class _PickCycleMachine extends StatefulWidget {
  const _PickCycleMachine({required this.machineType, required this.onStart});

  final MachineType machineType;
  final StartSelectedMachine onStart;

  @override
  State<_PickCycleMachine> createState() => _PickCycleMachineState();
}

class _PickCycleMachineState extends State<_PickCycleMachine> {
  String? _starting;
  String? _error;

  bool get _isDryer => widget.machineType == MachineType.dryer;

  @override
  void initState() {
    super.initState();
    context.read<MachinesBloc>().add(const MachinesSubscriptionRequested());
  }

  Future<void> _start(Machine machine) async {
    if (_starting != null) return;
    final confirmed = await confirmMachineStart(
      context,
      machineName: machine.name,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _starting = machine.id;
      _error = null;
    });
    final error = await widget.onStart(machine);
    if (!mounted) return;

    if (error == null) {
      final navigator = Navigator.of(context);
      navigator.pop(true);
      final host = navigator.context;
      if (host.mounted) {
        await showStartCommandSent(
          host,
          machineName: machine.name,
          drying: _isDryer,
        );
      }
      return;
    }

    setState(() {
      _starting = null;
      _error = error;
    });
    context.read<MachinesBloc>().add(const MachinesSubscriptionRequested());
  }

  @override
  Widget build(BuildContext context) {
    final machines = context.select<MachinesBloc, List<Machine>>(
      (bloc) => bloc.state.machines
          .where((machine) => machine.type == widget.machineType)
          .toList()
        ..sort((a, b) => (a.size ?? 0).compareTo(b.size ?? 0)),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Text(
            _isDryer
                ? 'Choisissez votre sécheuse'
                : 'Choisissez votre laveuse',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Votre cycle est déjà payé. Vous pouvez utiliser n’importe quelle '
            'machine disponible du bon type.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (machines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                _isDryer
                    ? 'Aucune sécheuse visible pour le moment.'
                    : 'Aucune laveuse visible pour le moment.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final machine in machines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MachineTile(
                        machine: machine,
                        starting: _starting == machine.id,
                        onTap: _starting == null ? () => _start(machine) : null,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MachineTile extends StatelessWidget {
  const _MachineTile({
    required this.machine,
    required this.starting,
    required this.onTap,
  });

  final Machine machine;
  final bool starting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final available = machine.status == MachineStatus.available;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: available ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Icon(
                machine.type == MachineType.dryer
                    ? Icons.dry_cleaning_rounded
                    : Icons.local_laundry_service_rounded,
                color: available ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: available
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      available
                          ? [
                              if (machine.size != null) '${machine.size} kg',
                              'Disponible',
                            ].join(' · ')
                          : 'Indisponible',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (starting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (available)
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
