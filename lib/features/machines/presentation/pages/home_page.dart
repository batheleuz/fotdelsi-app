import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import '../bloc/machines_bloc.dart';
import '../bloc/machines_event.dart';
import '../bloc/machines_state.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/machines_content.dart';
import '../widgets/machines_status_views.dart';

/// Page Accueil
///
/// Le `BlocProvider` récupère le Bloc depuis le service locator (`get_it`) et
/// déclenche l'abonnement. La construction des dépendances vit en un seul
/// endroit : `core/di/service_locator.dart`.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          serviceLocator<MachinesBloc>()..add(const MachinesSubscriptionRequested()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<MachinesBloc, MachinesState>(
          builder: (context, state) {
            return Column(
              children: [
                HomeAppBar(connected: state.isConnected),
                Expanded(child: _body(context, state)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
                  ),
                  child: PrimaryButton(
                    label: 'Scanner une machine',
                    icon: Icons.qr_code_scanner_rounded,
                    onPressed: () => context.push(AppRoutes.scan),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, MachinesState state) {
    return switch (state.status) {
      MachinesStatus.initial ||
      MachinesStatus.loading =>
        const MachinesLoading(),
      MachinesStatus.failure => MachinesError(
          message: state.error ?? 'Connexion au temps réel impossible.',
          onRetry: () => context
              .read<MachinesBloc>()
              .add(const MachinesSubscriptionRequested()),
        ),
      MachinesStatus.success => MachinesContent(machines: state.machines),
    };
  }
}
