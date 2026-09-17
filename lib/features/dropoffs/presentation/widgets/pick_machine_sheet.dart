import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/start_command_sent_sheet.dart';
import '../cubit/assign_machine_cubit.dart';

/// Choix de la machine qui va tourner, en feuille et non plus en page.
///
/// Une page entière pour un geste aussi court faisait perdre le contexte : le
/// dépôt disparaissait de l'écran, et l'agent revenait à l'aveugle. La feuille
/// laisse le détail visible derrière, comme le choix de sécheuse côté client.
///
/// Le tap sur une machine LANCE : pas de sélection puis de bouton « Démarrer »
/// à aller chercher en bas. Pas de confirmation non plus — choisir une machine
/// précise dans une liste est déjà un geste délibéré, et empiler une feuille
/// sur une feuille se paierait en confusion. C'est le même parti pris que
/// `showPickDryerSheet`, et l'inverse des boutons de lancement directs, qui
/// eux n'ont rien à désigner et passent par `confirmMachineStart`.
///
/// Ne sert plus au lavage que pour les dépôts ANTÉRIEURS au choix de machine à
/// la saisie. Les dépôts récents en portent une : leur bouton lance
/// directement, sans passer par ici.
///
/// Renvoie `true` si un cycle est parti.
Future<bool> showPickMachineSheet(
  BuildContext context, {
  required String dropOffId,
  required AssignMode mode,
}) async {
  final started = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => serviceLocator<AssignMachineCubit>()
        ..loadMachines(
          mode == AssignMode.dry ? MachineType.dryer : MachineType.washer,
        ),
      child: _PickMachine(dropOffId: dropOffId, mode: mode),
    ),
  );
  return started ?? false;
}

class _PickMachine extends StatefulWidget {
  const _PickMachine({required this.dropOffId, required this.mode});

  final String dropOffId;
  final AssignMode mode;

  @override
  State<_PickMachine> createState() => _PickMachineState();
}

class _PickMachineState extends State<_PickMachine> {
  /// Machine en cours de démarrage : seule sa ligne tourne, les autres restent
  /// lisibles.
  String? _starting;

  /// Motif du dernier refus, affiché ICI et non en snackbar : celui-ci
  /// s'afficherait derrière la feuille restée ouverte, donc invisible.
  String? _error;

  bool get _isDry => widget.mode == AssignMode.dry;

  Future<void> _start(Machine machine) async {
    if (_starting != null) return;
    setState(() {
      _starting = machine.id;
      _error = null;
    });

    final cubit = context.read<AssignMachineCubit>();
    cubit.select(machine.id);
    final ok = _isDry
        ? await cubit.startDrying(widget.dropOffId)
        : await cubit.assign(widget.dropOffId);

    if (!mounted) return;

    // On ne ferme que si la machine est réellement partie. Sinon l'agent reste
    // ici, lit pourquoi, et en choisit une autre.
    if (ok) {
      final navigator = Navigator.of(context);
      navigator.pop(true);

      // La commande est partie ; le tambour, lui, attend qu'on appuie sur
      // l'écran de la machine. Sans ce geste la pièce est créditée et rien ne
      // tourne — et personne ne le voit côté serveur.
      final host = navigator.context;
      if (host.mounted) {
        await showStartCommandSent(
          host,
          machineName: machine.name,
          drying: _isDry,
        );
      }
      return;
    }

    setState(() {
      _starting = null;
      _error = cubit.state.error ?? 'Démarrage refusé.';
    });

    // Un refus signifie presque toujours que la liste affichée est en retard :
    // la machine paraissait libre, elle ne l'est plus. On redemande l'état réel
    // pour que la ligne disparaisse et que le refus s'explique de lui-même.
    cubit.loadMachines(_isDry ? MachineType.dryer : MachineType.washer);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AssignMachineCubit>().state;

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
            // Référentiel client : « Choisissez votre machine ». La
            // distinction laveuse/sécheuse est conservée — elle dit CE QU'ON
            // choisit, ce qu'un « votre machine » générique perdrait.
            _isDry ? 'Choisissez votre sécheuse' : 'Choisissez votre laveuse',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isDry
                ? 'Chargez le linge, puis lancez la machine.'
                : 'Sélectionnez une machine disponible pour continuer.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          switch (state.status) {
            AssignLoad.success when state.machines.isEmpty => _empty(),
            AssignLoad.success => Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final machine in state.machines)
                    _MachineRow(
                      machine: machine,
                      isDry: _isDry,
                      starting: _starting == machine.id,
                      onTap: () => _start(machine),
                    ),
                ],
              ),
            ),
            AssignLoad.failure => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                state.error ?? 'Chargement impossible.',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
            _ => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          },

          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: const TextStyle(fontSize: 13, color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
    child: Row(
      children: [
        Icon(
          _isDry
              ? Icons.dry_cleaning_outlined
              : Icons.local_laundry_service_outlined,
          size: 22,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            _isDry
                ? 'Aucune sécheuse libre pour le moment.'
                : 'Aucune laveuse libre pour le moment.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );
}

class _MachineRow extends StatelessWidget {
  const _MachineRow({
    required this.machine,
    required this.isDry,
    required this.starting,
    required this.onTap,
  });

  final Machine machine;
  final bool isDry;
  final bool starting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: starting ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Le NOM, et non le code : « WASH_01 » ne désigne rien
                      // pour qui se tient devant les machines. C'est le nom qui
                      // est écrit dessus.
                      Text(
                        machine.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (machine.size != null)
                        Text(
                          '${machine.size} kg',
                          style: const TextStyle(
                            fontSize: 11.5,
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
                else
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primaryLight,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
