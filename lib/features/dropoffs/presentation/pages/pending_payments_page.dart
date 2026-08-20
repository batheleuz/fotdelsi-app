import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/motion/entrance.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../cubit/pending_payments_cubit.dart';
import '../widgets/pending_payment_card.dart';

/// Dépôts saisis dont le paiement n'est pas encore confirmé.
///
/// Ces commandes sont absentes de la file de travail pour une raison
/// structurelle : la file ne liste que des dépôts, et un dépôt n'est créé qu'à
/// la confirmation du paiement. Avant, il n'existe qu'un brouillon — invisible.
///
/// L'agent envoyait donc une demande de paiement, servait le client suivant, et
/// n'avait plus aucun moyen de savoir si le premier avait payé. Cet écran est
/// ce moyen.
class PendingPaymentsPage extends StatelessWidget {
  const PendingPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<PendingPaymentsCubit>()
        ..load()
        ..startRealtime(),
      child: const _PendingPaymentsView(),
    );
  }
}

class _PendingPaymentsView extends StatelessWidget {
  const _PendingPaymentsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('En attente de paiement'),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<PendingPaymentsCubit, PendingPaymentsState>(
          builder: (context, state) {
            if (state.status == PendingPaymentsStatus.loading ||
                state.status == PendingPaymentsStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == PendingPaymentsStatus.failure) {
              return _Error(
                message: state.error,
                onRetry: () => context.read<PendingPaymentsCubit>().load(),
              );
            }

            final pending = state.pending ?? const [];

            return RefreshIndicator(
              onRefresh: () => context.read<PendingPaymentsCubit>().refresh(),
              child: pending.isEmpty
                  ? const _Empty()
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      children: [
                        const _Explanation(),
                        const SizedBox(height: AppSpacing.md),
                        // Entrée en cascade. La clé suit le dépôt : quand la
                        // liste se rafraîchit, seules les nouvelles lignes
                        // s'animent — les autres restent en place.
                        for (final (i, item) in pending.indexed)
                          EntranceFade(
                            key: ValueKey(item.draftId),
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: PendingPaymentCard(payment: item),
                            ),
                          ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

/// Dit à l'agent ce qu'il regarde : ces lignes ne sont pas encore des dépôts.
class _Explanation extends StatelessWidget {
  const _Explanation();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ces dépôts entrent dans la file dès que le client paie. '
              'Ils disparaissent d\'ici tout seuls — inutile de recharger.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'Impossible de charger les paiements en attente.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    // Liste scrollable malgré tout : sinon le pull-to-refresh ne fonctionne pas.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.24),
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 44,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 12),
        const Text(
          'Tout est encaissé',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(
            'Les dépôts dont le client n\'a pas encore payé apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
