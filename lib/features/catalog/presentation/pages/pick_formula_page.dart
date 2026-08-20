import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_router.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import '../cubit/service_catalog_cubit.dart';
import '../widgets/formula_card.dart';

/// Choix de la prestation pour une machine déjà identifiée (scan du QR).
///
/// Miroir de [PickMachinePage] : c'est le même achat, saisi dans l'autre sens.
/// Le scan physique ayant déjà désigné la machine, seules les prestations
/// compatibles avec son type et tarifées pour sa capacité sont proposées.
class PickFormulaPage extends StatelessWidget {
  const PickFormulaPage({super.key, required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<ServiceCatalogCubit>()..load(),
      child: _PickFormulaView(machine: machine),
    );
  }
}

class _PickFormulaView extends StatelessWidget {
  const _PickFormulaView({required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context) {
    final size = machine.size;

    return Scaffold(
      appBar: AppBar(
        title: Text(size == null ? machine.name : 'Machine $size kg'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<ServiceCatalogCubit, ServiceCatalogState>(
          builder: (context, state) => switch (state.status) {
            CatalogStatus.initial || CatalogStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            CatalogStatus.failure => _Message(
              text: state.error ?? 'Impossible de charger les prestations.',
              onRetry: () => context.read<ServiceCatalogCubit>().load(),
            ),
            CatalogStatus.success => _list(context, state),
          },
        ),
      ),
    );
  }

  Widget _list(BuildContext context, ServiceCatalogState state) {
    final size = machine.size;
    final isWasher = machine.type == MachineType.washer;

    final eligible = state.formulas
        .where(
          (f) =>
              f.needsWasher == isWasher &&
              size != null &&
              f.priceFor(size) != null,
        )
        .toList();

    if (eligible.isEmpty) {
      return const _Message(
        text: 'Aucune prestation n\'est proposée sur cette machine.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: eligible.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Que souhaitez-vous faire ?',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          );
        }

        final formula = eligible[index - 1];
        return FormulaCard(
          available: formula.availability.selfService,
          formula: formula,
          // Le prix exact est connu ici (la capacité est déterminée) : la
          // carte affiche « dès X », le récapitulatif de paiement tranchera.
          onTap: () {
            final PaymentArgs args = (formula: formula, machine: machine);
            context.push(AppRoutes.payment, extra: args);
          },
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }
}
