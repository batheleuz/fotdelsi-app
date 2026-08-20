import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/motion/entrance.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../domain/entities/drop_off.dart';
import '../cubit/my_dropoffs_cubit.dart';
import '../utils/relative_time.dart';
import '../widgets/drop_off_status_badge.dart';

/// Historique des dépôts du client lié.
class MyDropOffsPage extends StatelessWidget {
  const MyDropOffsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<MyDropOffsCubit>()..load(),
      child: const _MyDropOffsView(),
    );
  }
}

class _MyDropOffsView extends StatelessWidget {
  const _MyDropOffsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text('Mes dépôts'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<MyDropOffsCubit, MyDropOffsState>(
          builder: (context, state) {
            if (state.status == MyDropOffsStatus.loading ||
                state.status == MyDropOffsStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == MyDropOffsStatus.failure &&
                state.items == null) {
              return _Centered(
                icon: Icons.cloud_off_rounded,
                message: state.error ?? 'Chargement impossible.',
                onRetry: () => context.read<MyDropOffsCubit>().load(),
              );
            }
            final items = state.items ?? const [];
            return RefreshIndicator(
              onRefresh: () => context.read<MyDropOffsCubit>().refresh(),
              child: items.isEmpty
                  ? _emptyList()
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: items.length,
                      itemBuilder: (_, i) => EntranceFade(
                        key: ValueKey(items[i].id),
                        index: i,
                        child: _MyDropOffCard(dropOff: items[i]),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _emptyList() => ListView(
    children: const [
      SizedBox(height: 140),
      Icon(
        Icons.local_laundry_service_outlined,
        size: 48,
        color: AppColors.textTertiary,
      ),
      SizedBox(height: AppSpacing.md),
      Center(
        child: Text(
          'Aucun dépôt pour le moment',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    ],
  );
}

class _MyDropOffCard extends StatelessWidget {
  const _MyDropOffCard({required this.dropOff});

  final DropOff dropOff;

  @override
  Widget build(BuildContext context) {
    final laundry = dropOff.laundry.types.isEmpty
        ? '${dropOff.laundry.pieces} pièces'
        : '${dropOff.laundry.pieces} pièces · ${dropOff.laundry.typesLabel}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => context.push(AppRoutes.myDropOffDetail(dropOff.id)),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dropOff.code,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    DropOffStatusBadge(
                      status: dropOff.status,
                      // Une machine tourne : la pastille respire.
                      pulse: dropOff.status.isInProgress,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  laundry,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'déposé ${relativeTimeFr(dropOff.receivedAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
