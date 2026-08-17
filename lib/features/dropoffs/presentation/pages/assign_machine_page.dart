import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/assign_machine_cubit.dart';

/// Choix d'une machine disponible pour lancer le lavage (laveuse) ou le
/// séchage (sécheuse) d'un dépôt, selon [mode].
class AssignMachinePage extends StatelessWidget {
  const AssignMachinePage({
    super.key,
    required this.dropOffId,
    this.mode = AssignMode.wash,
  });

  final String dropOffId;
  final AssignMode mode;

  @override
  Widget build(BuildContext context) {
    final type = mode == AssignMode.dry
        ? MachineType.dryer
        : MachineType.washer;
    return BlocProvider(
      create: (_) => serviceLocator<AssignMachineCubit>()..loadMachines(type),
      child: _AssignView(dropOffId: dropOffId, mode: mode),
    );
  }
}

class _AssignView extends StatelessWidget {
  const _AssignView({required this.dropOffId, required this.mode});

  final String dropOffId;
  final AssignMode mode;

  bool get _isDry => mode == AssignMode.dry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          _isDry ? 'Choisir une sécheuse' : 'Choisir une laveuse',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocConsumer<AssignMachineCubit, AssignMachineState>(
        listenWhen: (p, c) => p.assignStatus != c.assignStatus,
        listener: (context, state) {
          if (state.assignStatus == AssignStatus.success) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(_isDry ? 'Séchage démarré' : 'Lavage démarré'),
                ),
              );
            context.pop();
          } else if (state.assignStatus == AssignStatus.failure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    state.error ?? 'Échec du démarrage',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppColors.danger,
                ),
              );
          }
        },
        builder: (context, state) => switch (state.status) {
          AssignLoad.success =>
            state.machines.isEmpty ? _empty() : _list(context, state),
          AssignLoad.failure => Center(
            child: Text(state.error ?? 'Chargement impossible.'),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _list(BuildContext context, AssignMachineState state) {
    final cubit = context.read<AssignMachineCubit>();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: state.machines
                .map(
                  (m) => _MachineTile(
                    machine: m,
                    selected: state.selectedId == m.id,
                    isDry: _isDry,
                    onTap: () => cubit.select(m.id),
                  ),
                )
                .toList(),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PrimaryButton(
            label: _isDry ? 'Démarrer le séchage' : 'Démarrer le lavage',
            icon: Icons.play_arrow_rounded,
            enabled: state.selectedId != null && !state.isAssigning,
            loading: state.isAssigning,
            backgroundColor: AppColors.primaryLight,
            onPressed: () =>
                _isDry ? cubit.startDrying(dropOffId) : cubit.assign(dropOffId),
          ),
        ),
      ],
    );
  }

  Widget _empty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isDry
                ? Icons.dry_cleaning_outlined
                : Icons.local_laundry_service_outlined,
            size: 44,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _isDry
                ? 'Aucune sécheuse libre actuellement.'
                : 'Aucune laveuse libre actuellement.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}

class _MachineTile extends StatelessWidget {
  const _MachineTile({
    required this.machine,
    required this.selected,
    required this.isDry,
    required this.onTap,
  });

  final Machine machine;
  final bool selected;
  final bool isDry;
  final VoidCallback onTap;

  String _label() {
    final kind = isDry ? 'Sèche-linge' : 'Lave-linge';
    return machine.size != null ? '$kind · ${machine.size} kg' : kind;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceTint : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                isDry
                    ? Icons.dry_cleaning_rounded
                    : Icons.local_laundry_service_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machine.code,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _label(),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryLight,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
