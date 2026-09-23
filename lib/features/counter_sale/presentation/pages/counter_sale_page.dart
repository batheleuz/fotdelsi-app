import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/pick_cycle_machine_sheet.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import '../cubit/counter_sale_cubit.dart';
import '../widgets/counter_sale_stepper.dart';
import '../widgets/steps/sale_customer_step.dart';
import '../widgets/steps/sale_payment_step.dart';
import '../widgets/steps/sale_service_step.dart';
import '../widgets/steps/sale_start_step.dart';

/// Vente d'un cycle au comptoir, pour un client qui n'a pas l'application.
///
/// La page n'orchestre que la coquille — en-tête, progression, barre d'action.
/// Chaque étape vit dans son propre widget : le parcours a quatre moments
/// distincts, et l'écran de paiement obéit à des règles opposées aux autres
/// (il est lu par le client, pas par l'agent).
class CounterSalePage extends StatelessWidget {
  const CounterSalePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<CounterSaleCubit>(),
      child: const _CounterSaleView(),
    );
  }
}

class _CounterSaleView extends StatelessWidget {
  const _CounterSaleView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CounterSaleCubit, CounterSaleState>(
      listenWhen: (p, c) =>
          (p.error != c.error && c.error != null) ||
          (p.saleStatus != c.saleStatus && c.saleStatus == SaleStatus.started),
      listener: (context, state) {
        if (state.saleStatus == SaleStatus.started) {
          _leaveForDirectCycles(context, state.machine?.name);
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.danger,
            ),
          );
      },
      builder: (context, state) {
        // L'étape de paiement occupe tout l'écran : ni progression, ni bouton.
        final isPayment = state.step == 2;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Lancer un cycle'),
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
          ),
          // Tap n'importe où hors d'un champ → ferme le clavier. Sans ça,
          // l'agent n'avait aucun moyen de le refermer : les deux champs de
          // l'étape client enchaînent sur « suivant » plutôt que sur
          // « terminé », et le bouton d'action se retrouve masqué dessous.
          // Même geste que l'assistant de dépôt.
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: switch (state.loadStatus) {
                SaleLoadStatus.initial || SaleLoadStatus.loading =>
                  const Center(child: CircularProgressIndicator()),
                SaleLoadStatus.failure => _LoadError(
                  onRetry: () => context.read<CounterSaleCubit>().retryLoad(),
                ),
                SaleLoadStatus.success =>
                  isPayment
                      ? const SalePaymentStep()
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppSpacing.sm),
                              CounterSaleStepper(step: state.step),
                              Expanded(child: _stepBody(state.step)),
                              _ActionBar(state: state),
                            ],
                          ),
                        ),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _stepBody(int step) => switch (step) {
    0 => const SaleServiceStep(),
    1 => const SaleCustomerStep(),
    _ => const SaleStartStep(),
  };
}

/// Une fois la machine lancée, l'agent quitte l'assistant pour la liste des
/// Cycles Directs.
///
/// Deux navigations enchaînées et non une seule : `go` repose la pile sur
/// l'accueil agent, `push` empile la liste par-dessus. Le bouton retour ramène
/// donc à l'accueil, jamais dans un assistant dont la vente est consommée —
/// c'est ce que `go` seul aurait laissé faire.
///
/// L'assistant s'arrêtait auparavant sur « Lavage lancé » et proposait
/// « Nouveau Cycle Direct ». Le cycle qui venait de démarrer n'apparaissait
/// alors nulle part : pour le suivre, il fallait ressortir et rouvrir la liste
/// à la main.
///
/// La confirmation passe par un SnackBar plutôt que par une pause avant de
/// naviguer : le `ScaffoldMessenger` est au-dessus du routeur, le message
/// survit donc au changement d'écran. L'agent voit la confirmation ET le cycle
/// dans la liste, sans attendre.
void _leaveForDirectCycles(BuildContext context, String? machineName) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          machineName == null
              ? 'Machine lancée.'
              : 'Machine lancée — $machineName.',
        ),
        backgroundColor: AppColors.success,
      ),
    );

  context.go(AppRoutes.agentHome);
  context.push(AppRoutes.agentCycles);
}

/// Barre d'action du bas : le libellé dit ce qui va se passer, pas « Suivant ».
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.state});

  final CounterSaleState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CounterSaleCubit>();
    final isStartStep = state.step == 3;
    final started = state.saleStatus == SaleStatus.started;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.sm),
      child: Column(
        children: [
          if (isStartStep)
            PrimaryButton(
              // « Machine lancée » n'est visible que le temps d'un frame :
              // l'écran part aussitôt vers les Cycles Directs. Le bouton reste
              // rendu, mais inerte — un appui pendant la transition ne doit
              // rien relancer sur un cycle deja consomme.
              label: started ? 'Machine lancée' : 'Démarrer la machine',
              icon: started ? Icons.check_rounded : Icons.play_arrow_rounded,
              enabled: !state.isStarting && !started,
              loading: state.isStarting,
              backgroundColor: started
                  ? AppColors.primaryLight
                  : AppColors.secondary,
              onPressed: started
                  // `enabled: false` neutralise déjà l'appui ; le rappel doit
                  // quand même exister, il n'est pas nullable.
                  ? () {}
                  // Confirmation avant tout démarrage physique : ici le
                  // téléphone est dans la main de l'agent, souvent tendu vers
                  // le client, et un appui involontaire consommerait le cycle
                  // qui vient d'être payé sur un tambour vide.
                  : () => showPickCycleMachineSheet(
                      context,
                      machineType: state.machine!.type,
                      onStart: cubit.startMachine,
                    ),
            )
          else
            PrimaryButton(
              label: state.step == 1
                  ? 'Afficher le QR de paiement'
                  : 'Continuer',
              icon: state.step == 1
                  ? Icons.qr_code_2_rounded
                  : Icons.arrow_forward_rounded,
              enabled: state.canGoNext && !state.isSubmitting,
              loading: state.isSubmitting,
              backgroundColor: AppColors.primaryLight,
              onPressed: cubit.next,
            ),
          if (state.canGoBack)
            TextButton(onPressed: cubit.back, child: const Text('Retour')),
          if (isStartStep && !started)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Démarrer plus tard'),
            ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Impossible de charger les prestations et les machines.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}
