import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import '../cubit/client_session_cubit.dart';

/// Écran « Mon compte » : affiche le numéro lié et permet de le déconnecter.
class ClientAccountPage extends StatefulWidget {
  const ClientAccountPage({super.key});

  @override
  State<ClientAccountPage> createState() => _ClientAccountPageState();
}

class _ClientAccountPageState extends State<ClientAccountPage> {
  bool _unlinking = false;

  Future<void> _confirmUnlink() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnecter ce numéro ?'),
        content: const Text(
            'Vous ne recevrez plus de notifications sur ce téléphone. '
            'Vous pourrez relier votre numéro à tout moment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _unlinking = true);
    await context.read<ClientSessionCubit>().unlink();
    if (!mounted) return;
    context.go(AppRoutes.home);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Numéro déconnecté')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon compte'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<ClientSessionCubit, ClientSessionState>(
          builder: (context, session) {
            if (!session.isLinked) {
              return _notLinked(context);
            }
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_outline,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Numéro lié',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text('+221 ${session.phone}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      'Vous recevez vos notifications (demandes de paiement, linge prêt) sur ce numéro.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _AccountTile(
                    icon: Icons.local_laundry_service_outlined,
                    label: 'Mes dépôts',
                    onTap: () => context.push(AppRoutes.myDropOffs),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Déconnecter ce numéro',
                    icon: Icons.logout,
                    loading: _unlinking,
                    backgroundColor: AppColors.danger,
                    onPressed: _confirmUnlink,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _notLinked(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sms_outlined,
                  size: 44, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              const Text('Aucun numéro lié',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Lier mon numéro',
                expanded: false,
                backgroundColor: AppColors.primaryLight,
                onPressed: () => context.go(AppRoutes.linkPhone),
              ),
            ],
          ),
        ),
      );
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
