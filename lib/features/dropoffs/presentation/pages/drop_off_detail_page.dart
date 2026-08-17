import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/app_popup_menu.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off_status.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/drop_off_detail_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/drop_off_status_badge.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/drop_off_timeline.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/edit_laundry_sheet.dart';

/// Détail d'un dépôt côté agent + actions contextuelles selon le statut.
class DropOffDetailPage extends StatelessWidget {
  const DropOffDetailPage({super.key, required this.dropOffId});

  final String dropOffId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<DropOffDetailCubit>()
        ..load(dropOffId)
        ..startRealtime(),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DropOffDetailCubit, DropOffDetailState>(
      listenWhen: (p, c) => p.actionStatus != c.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == ActionStatus.failure &&
            state.actionError != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.actionError!),
                backgroundColor: AppColors.danger,
              ),
            );
        }
      },
      builder: (context, state) {
        final d = state.dropOff;
        return Scaffold(
          backgroundColor: const Color(0xFFF5F8FC),
          appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            title: const Text(
              'Détail dépôt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            actions: [
              if (d != null && !d.status.isTerminal)
                AppPopupMenu(
                  entries: [
                    AppMenuEntry(
                      icon: Icons.edit_outlined,
                      label: 'Modifier le linge',
                      onSelected: () => _editLaundry(context, d),
                    ),
                  ],
                ),
            ],
          ),
          body: switch (state.status) {
            DetailStatus.success => _content(context, d!),
            DetailStatus.failure => Center(
              child: Text(state.error ?? 'Chargement impossible.'),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
          bottomNavigationBar: d == null
              ? null
              : _actionBar(context, d, state.isActing),
        );
      },
    );
  }

  Widget _content(BuildContext context, DropOff d) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                d.code,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropOffStatusBadge(
                status: d.status,
                // Une machine tourne : la pastille respire.
                pulse: d.status.isInProgress,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        DropOffTimeline(dropOff: d),

        const SizedBox(height: AppSpacing.sm),

        _infoCard(d),

        if (d.status == DropOffStatus.ready)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: _banner(
              'Vérifiez le code présenté par le client avant de remettre le linge.',
              const Color(0xFFE1F6EF),
              const Color(0xFF0F6E56),
              Icons.verified_outlined,
            ),
          ),

        if (d.terminalReason != null && d.terminalReason!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: _banner(
              d.terminalReason!,
              const Color(0xFFFCEBEB),
              const Color(0xFFA32D2D),
              Icons.info_outline,
            ),
          ),
      ],
    );
  }

  Widget _infoCard(DropOff d) {
    final laundry = d.laundry.types.isEmpty
        ? '${d.laundry.pieces} pièces'
        : '${d.laundry.pieces} pièces · ${d.laundry.typesLabel}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          _kv('Client', d.customerName),
          _kv('Téléphone', '+221 ${d.contactPhone.replaceFirst("+221", "")}'),
          _kv('Linge', laundry),
          if (d.laundry.instructions.isNotEmpty)
            _kv('Instructions', d.laundry.instructions),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            k,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _banner(String text, Color bg, Color fg, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Row(
      children: [
        Icon(icon, color: fg, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: fg)),
        ),
      ],
    ),
  );

  Widget? _actionBar(BuildContext context, DropOff dropOff, bool isActing) {
    final cubit = context.read<DropOffDetailCubit>();

    return switch (dropOff.status) {
      // Libre-service : le client a lavé lui-même, il apporte son linge pour
      // la finition payée. Aucun lavage à lancer — seulement à prendre en
      // charge, ce que le backend refuserait autrement.
      DropOffStatus.awaitingHandoff => _bar(
        PrimaryButton(
          label: 'Prendre en charge',
          icon: Icons.inventory_2_outlined,
          loading: isActing,
          backgroundColor: AppColors.primaryLight,
          onPressed: () => cubit.receiveHandoff(),
        ),
      ),

      DropOffStatus.received => _bar(
        PrimaryButton(
          label: 'Lancer le lavage',
          icon: Icons.play_arrow_rounded,
          loading: isActing,
          backgroundColor: AppColors.primaryLight,
          onPressed: () async {
            await context.push(AppRoutes.agentAssignMachine(dropOff.id));
            if (context.mounted) cubit.load(dropOff.id);
          },
        ),
      ),

      // Lavage terminé (auto) + séchage payé → l'agent lance le séchage.
      DropOffStatus.inProgress when dropOff.canStartDrying => _bar(
        PrimaryButton(
          label: 'Lancer le séchage',
          icon: Icons.dry_cleaning_outlined,
          loading: isActing,
          backgroundColor: AppColors.secondary,
          onPressed: () async {
            await context.push(AppRoutes.agentStartDrying(dropOff.id));
            if (context.mounted) cubit.load(dropOff.id);
          },
        ),
      ),

      // Cycle requis terminé → l'agent peut marquer prêt.
      DropOffStatus.inProgress when dropOff.canMarkReady => _bar(
        PrimaryButton(
          label: 'Marquer prêt',
          icon: Icons.check_rounded,
          loading: isActing,
          backgroundColor: AppColors.primaryLight,
          onPressed: () => cubit.markReady(),
        ),
      ),

      // Un cycle tourne encore : on attend sa fin (détectée automatiquement).
      // Sans objet en libre-service, où le travail restant est manuel :
      // `canMarkReady` y est vrai dès la prise en charge.
      DropOffStatus.inProgress => _bar(
        _CycleRunningBar(
          label: dropOff.dryStartedAt != null
              ? 'Séchage en cours…'
              : 'Lavage en cours…',
        ),
      ),

      DropOffStatus.ready => _bar(
        PrimaryButton(
          label: 'Remettre au client',
          icon: Icons.back_hand_outlined,
          loading: isActing,
          backgroundColor: AppColors.success,
          onPressed: () => _confirmCollect(context, cubit),
        ),
      ),

      _ => null,
    };
  }

  Widget _bar(Widget child) =>
      SafeArea(minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: child);

  Future<void> _confirmCollect(
    BuildContext context,
    DropOffDetailCubit cubit,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remettre au client ?'),
        content: const Text(
          'Confirmez que le linge a bien été remis au client présentant ce code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (ok == true) cubit.markCollected();
  }

  Future<void> _editLaundry(BuildContext context, DropOff dropOff) async {
    final cubit = context.read<DropOffDetailCubit>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => EditLaundrySheet(
        initial: dropOff.laundry,
        onSave: (pieces, types, instructions) => cubit.updateLaundry(
          pieces: pieces,
          types: types,
          instructions: instructions,
        ),
      ),
    );
  }
}

/// Barre non-actionnable affichée pendant qu'un cycle tourne : l'agent attend
/// la fin (marquée automatiquement quand la machine repasse disponible).
class _CycleRunningBar extends StatelessWidget {
  const _CycleRunningBar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
