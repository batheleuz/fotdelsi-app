import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/drop_off_search_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/drop_off_status_badge.dart';

/// Alphabet du code court : sans caractères ambigus (O/0/I/1/L).
class _CodeFormatter extends TextInputFormatter {
  static final _allowed = RegExp(r'[ABCDEFGHJKMNPQRSTUVWXYZ23456789]');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final filtered = newValue.text
        .toUpperCase()
        .split('')
        .where(_allowed.hasMatch)
        .join();
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

/// Recherche d'un dépôt par son code court (client revenu sans l'app).
class DropOffSearchPage extends StatelessWidget {
  const DropOffSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<DropOffSearchCubit>(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DropOffSearchCubit>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Rechercher',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextField(
            autofocus: true,
            textAlign: TextAlign.center,
            maxLength: 4,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [_CodeFormatter()],
            style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 12),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'A7K3',
              filled: true,
              fillColor: AppColors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide:
                    const BorderSide(color: AppColors.primaryLight, width: 1.5),
              ),
            ),
            onChanged: (v) {
              if (v.length == 4) {
                cubit.search(v);
              } else {
                cubit.reset();
              }
            },
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Lettres et chiffres, sans O · 0 · I · 1 · L',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ),
          const SizedBox(height: AppSpacing.lg),
          BlocBuilder<DropOffSearchCubit, DropOffSearchState>(
            builder: (context, state) => _result(context, state),
          ),
        ],
      ),
    );
  }

  Widget _result(BuildContext context, DropOffSearchState state) {
    return switch (state.status) {
      SearchStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      SearchStatus.notFound => const _Hint('Aucun dépôt pour ce code.'),
      SearchStatus.failure => _Hint(state.error ?? 'Erreur de recherche.'),
      SearchStatus.found => _ResultCard(
          dropOff: state.result!,
          onTap: () =>
              context.push(AppRoutes.agentDropOffDetail(state.result!.id)),
        ),
      SearchStatus.idle => const SizedBox.shrink(),
    };
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: Text(text,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.dropOff, required this.onTap});

  final DropOff dropOff;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dropOff.code,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(dropOff.customerName,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const Spacer(),
            DropOffStatusBadge(status: dropOff.status),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
