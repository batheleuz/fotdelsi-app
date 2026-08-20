import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/confirm_start_sheet.dart';
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
      listenWhen: (p, c) => p.error != c.error && c.error != null,
      listener: (context, state) {
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
            title: const Text('Vente au comptoir'),
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
              label: started ? 'Nouvelle vente' : 'Démarrer la machine',
              icon: started ? Icons.refresh_rounded : Icons.play_arrow_rounded,
              enabled: !state.isStarting,
              loading: state.isStarting,
              backgroundColor: started
                  ? AppColors.primaryLight
                  : AppColors.secondary,
              onPressed: started
                  ? () => Navigator.of(context).pop()
                  // Confirmation avant tout démarrage physique : ici le
                  // téléphone est dans la main de l'agent, souvent tendu vers
                  // le client, et un appui involontaire consommerait le cycle
                  // qui vient d'être payé sur un tambour vide.
                  : () async {
                      if (await confirmMachineStart(
                        context,
                        machineName: state.machine?.name,
                      )) {
                        await cubit.startMachine();
                      }
                    },
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
