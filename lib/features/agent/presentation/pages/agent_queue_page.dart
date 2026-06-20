import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/auth/presentation/cubit/auth_cubit.dart';

/// Écran principal de l'agent — placeholder.
///
/// La vraie file d'attente (3 sections, cartes de dépôt, FAB) sera construite
/// à l'étape suivante. Pour l'instant, valide le routage par rôle et la
/// déconnexion.
class AgentQueuePage extends StatelessWidget {
  const AgentQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('File d\'attente'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.checklist_rtl,
                  size: 48, color: AppColors.primaryLight),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Connecté en tant qu\'agent',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (user != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(user.name,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                'La file d\'attente arrive à la prochaine étape.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
