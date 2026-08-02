import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/features/service_status/presentation/widgets/service_status_banner.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/client_auth/presentation/cubit/client_session_cubit.dart';
import 'package:fotdelsi/features/client_auth/presentation/widgets/link_phone_prompt.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_session_cubit.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/wash_running_sheet.dart';
import '../bloc/machines_bloc.dart';
import '../bloc/machines_event.dart';
import '../bloc/machines_state.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/machines_content.dart';
import '../widgets/machines_status_views.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          serviceLocator<MachinesBloc>()
            ..add(const MachinesSubscriptionRequested()),
      child: const _HomeView(),
    );
  }
}

/// Vue principale — gère aussi le cycle de vie de l'app pour rafraîchir
/// le statut de paiement quand l'utilisateur revient de l'app mobile money.
class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _maybePromptLinkPhone();
  }

  /// Propose discrètement de lier son numéro, peu après l'arrivée sur l'accueil
  /// (uniquement si aucun numéro n'est lié). Le throttling et le « ne plus
  /// afficher » sont gérés par [LinkPhonePrompt].
  Future<void> _maybePromptLinkPhone() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (context.read<ClientSessionCubit>().state.isLinked) return;
    await LinkPhonePrompt.maybeShow(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Vérifie si le paiement a été confirmé pendant l'absence de l'utilisateur.
      context.read<WashSessionCubit>().onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retour d'info du bouton « Démarrer » (désormais dans la carte machine) :
    // en cas d'échec on prévient, et on réinitialise le statut dans tous les cas.
    return BlocListener<WashSessionCubit, WashSessionState>(
      listenWhen: (p, c) => p.startStatus != c.startStatus,
      listener: (context, state) {
        if (state.startStatus == WashStartStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  state.startError ?? 'Impossible de démarrer la machine.',
                ),
                backgroundColor: AppColors.danger,
              ),
            );
          context.read<WashSessionCubit>().resetStartStatus();
        } else if (state.startStatus == WashStartStatus.success) {
          context.read<WashSessionCubit>().resetStartStatus();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const HomeAppBar(),
              Expanded(
                child: BlocBuilder<MachinesBloc, MachinesState>(
                  builder: (context, state) => _body(context, state),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: const _HomeFabs(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: const ServiceStatusBanner(),
      ),
    );
  }

  Widget _body(BuildContext context, MachinesState state) {
    return switch (state.status) {
      MachinesStatus.initial ||
      MachinesStatus.loading => const MachinesLoading(),
      MachinesStatus.failure => MachinesError(
        message: state.error ?? 'Connexion au temps réel impossible.',
        onRetry: () => context.read<MachinesBloc>().add(
          const MachinesSubscriptionRequested(),
        ),
      ),
      MachinesStatus.success => MachinesContent(machines: state.machines),
    };
  }
}

/// Colonne de FABs en bas à droite.
///
/// Structure (de bas en haut) :
///   • FAB scan — toujours visible.
///   • FAB session — visible si paiement confirmé ET machine pas encore démarrée.
///   • FAB running — visible si machine en cours.
class _HomeFabs extends StatelessWidget {
  const _HomeFabs();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WashSessionCubit, WashSessionState>(
      buildWhen: (prev, curr) => prev.isRunning != curr.isRunning,
      builder: (context, sessionState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // FAB « session en cours » (le bouton « Démarrer » est désormais
            // dans la carte de la machine concernée).
            if (sessionState.isRunning) ...[
              _SessionFab(state: sessionState),
              const SizedBox(height: AppSpacing.sm),
            ],
            // FAB scan — toujours présent
            _ScanFab(),
          ],
        );
      },
    );
  }
}

class _SessionFab extends StatelessWidget {
  const _SessionFab({required this.state});

  final WashSessionState state;

  /// Retrouve la machine de la session dans la liste temps réel.
  ///
  /// Priorité au `machineId` de la session ; repli sur `startedMachine`.
  Machine? _resolveMachine(BuildContext context) {
    final session = state.pendingSession;
    if (session == null) return state.startedMachine;

    final machines = context.read<MachinesBloc>().state.machines;
    for (final m in machines) {
      if (m.id == session.machineId) return m;
    }
    return state.startedMachine;
  }

  @override
  Widget build(BuildContext context) {
    // N'apparaît que pour une session EN COURS (voir _HomeFabs).
    return FloatingActionButton.extended(
      heroTag: 'session_fab',
      onPressed: () {
        final machine = _resolveMachine(context);
        if (machine != null) WashRunningSheet.show(context, machine);
      },
      backgroundColor: AppColors.success,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.local_laundry_service_rounded),
      label: const Text(
        'En cours',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ScanFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'scan_fab',
      onPressed: () => context.push(AppRoutes.scan),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      child: const Icon(Icons.qr_code_scanner_rounded),
    );
  }
}
