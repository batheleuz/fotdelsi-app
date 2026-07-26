import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../domain/entities/drop_off.dart';
import '../../domain/entities/drop_off_status.dart';
import '../cubit/my_dropoff_detail_cubit.dart';
import '../widgets/drop_off_status_badge.dart';
import '../widgets/drop_off_timeline.dart';

/// Détail d'un dépôt côté client : code, statut, suivi et résumé du linge.
class MyDropOffDetailPage extends StatelessWidget {
  const MyDropOffDetailPage({super.key, required this.dropOffId});

  final String dropOffId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<MyDropOffDetailCubit>()..load(dropOffId),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Mon dépôt',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<MyDropOffDetailCubit, MyDropOffDetailState>(
          builder: (context, state) {
            return switch (state.status) {
              MyDropOffDetailStatus.success =>
                _content(context, state.dropOff!),
              MyDropOffDetailStatus.failure => _Failure(
                  message: state.error ?? 'Chargement impossible.',
                  onRetry: () =>
                      context.read<MyDropOffDetailCubit>().refresh(),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            };
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, DropOff d) {
    return RefreshIndicator(
      onRefresh: () => context.read<MyDropOffDetailCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _header(d),
          if (d.status == DropOffStatus.ready)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: _banner(
                'Votre linge est prêt ! Présentez ce code au comptoir pour le récupérer.',
                const Color(0xFFE1F6EF),
                const Color(0xFF0F6E56),
                Icons.check_circle_outline,
              ),
            ),
          if (d.terminalReason != null && d.terminalReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: _banner(d.terminalReason!, const Color(0xFFFCEBEB),
                  const Color(0xFFA32D2D), Icons.info_outline),
            ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle('Suivi'),
          const SizedBox(height: AppSpacing.sm),
          DropOffTimeline(dropOff: d),
          const SizedBox(height: AppSpacing.sm),
          _sectionTitle('Votre linge'),
          const SizedBox(height: AppSpacing.sm),
          _laundryCard(d),
        ],
      ),
    );
  }

  Widget _header(DropOff d) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Text('Votre code de retrait',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(d.code,
                style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            DropOffStatusBadge(status: d.status),
          ],
        ),
      );

  Widget _laundryCard(DropOff d) {
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
          _kv('Linge', laundry),
          if (d.laundry.instructions.isNotEmpty)
            _kv('Instructions', d.laundry.instructions),
          _kv('Déposé le', _dateFr(d.receivedAt)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 90,
                child: Text(k,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary))),
            Expanded(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ),
          ],
        ),
      );

  Widget _banner(String text, Color bg, Color fg, IconData icon) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text, style: TextStyle(fontSize: 12.5, color: fg))),
          ],
        ),
      );

  String _dateFr(DateTime d) {
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} à $hh:$mm';
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});

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
            const Icon(Icons.cloud_off_rounded,
                size: 44, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
