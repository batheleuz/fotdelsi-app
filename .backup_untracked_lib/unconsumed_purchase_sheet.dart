import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../domain/entities/wash_cycle.dart';
import '../cubit/wash_cycles_cubit.dart';
import 'confirm_start_sheet.dart';
import 'start_command_sent_sheet.dart';

/// Ce qui remplace le refus sec quand le client essaie d'acheter alors qu'il a
/// déjà un lavage payé et jamais lancé.
///
/// ─── Pourquoi une feuille, et pas un message ───
///
/// Le refus est juste, mais il laissait le client sur l'écran de paiement avec
/// une phrase rouge et rien à faire : il devait revenir à l'accueil et
/// retrouver son bouton lui-même. Or ce qu'on lui demande — démarrer la machine
/// qu'il a déjà payée — se fait d'un geste. Autant le lui tendre.
///
/// ─── D'où vient le cycle ───
///
/// De `GET /me/cycles`, pas du refus. `POST /payments/initiate` s'authentifie
/// par le NUMÉRO fourni dans la requête : y faire transiter un jeton de
/// démarrage permettrait à qui devine un numéro d'agir sur la machine d'un
/// autre. La liste des cycles, elle, exige une session client.
///
/// Renvoie `true` si un démarrage est parti — l'appelant peut alors quitter
/// l'écran de paiement.
Future<bool> showUnconsumedPurchaseSheet(
  BuildContext context, {
  /// Le refus tel que le serveur l'a formulé : il nomme déjà la machine.
  required String message,
}) async {
  final started = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => BlocProvider<WashCyclesCubit>(
      // Une instance à soi, chargée à l'ouverture : l'écran de paiement n'est
      // pas sous le fournisseur de l'accueil, et le locator rend une NOUVELLE
      // instance à chaque appel. Un chargement de plus, sur un chemin que le
      // client ne prend qu'en cas de refus.
      create: (_) => serviceLocator<MyCyclesCubit>()..load(),
      child: _UnconsumedPurchase(message: message),
    ),
  );

  return started ?? false;
}

class _UnconsumedPurchase extends StatelessWidget {
  const _UnconsumedPurchase({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.local_laundry_service_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Vous avez déjà un lavage payé',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Text(
            // Le texte du serveur, qui nomme la machine. Le recopier ici en
            // ferait deux versions à tenir, et c'est le serveur qui sait
            // laquelle des quatre a été payée.
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          const _StartPaidCycleButton(),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Plus tard'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le bouton qui démarre la machine déjà payée, sans quitter la feuille.
class _StartPaidCycleButton extends StatelessWidget {
  const _StartPaidCycleButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WashCyclesCubit, WashCyclesState>(
      builder: (context, state) {
        final cycle = _unstarted(state);
        final busy = state.startingToken != null;

        // Chargement, ou cycle introuvable — un achat fait depuis un autre
        // appareil, un numéro non lié ici. On n'invente pas de bouton : le
        // message a déjà dit quoi faire, et l'accueil porte le geste.
        if (cycle == null) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(
                state.status == WashCyclesStatus.loading ||
                        state.status == WashCyclesStatus.initial
                    ? 'Recherche de votre lavage…'
                    : 'Démarrez-le depuis l\'accueil',
              ),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : () => _start(context, cycle),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(
              busy
                  ? 'Envoi…'
                  : cycle.machineName == null
                  ? 'Démarrer ma machine'
                  : 'Démarrer ${cycle.machineName}',
            ),
          ),
        );
      },
    );
  }

  /// Le lavage payé et jamais lancé. `failed` n'y figure pas : un démarrage
  /// refusé par la machine n'empêche pas d'acheter ailleurs, et ce n'est donc
  /// pas lui qui a provoqué ce refus.
  WashCycle? _unstarted(WashCyclesState state) {
    for (final cycle in state.toStart) {
      if (cycle.state == CycleState.toStart) return cycle;
    }
    return null;
  }

  Future<void> _start(BuildContext context, WashCycle cycle) async {
    final cubit = context.read<WashCyclesCubit>();
    final navigator = Navigator.of(context);

    // Même confirmation que partout ailleurs : le geste consomme le cycle payé,
    // et un appui involontaire le dépenserait sur un tambour vide.
    if (!await confirmMachineStart(context, machineName: cycle.machineName)) {
      return;
    }
    if (!await cubit.start(cycle)) return;

    navigator.pop(true);

    final host = navigator.context;
    if (host.mounted) {
      await showStartCommandSent(host, machineName: cycle.machineName);
    }
  }
}
