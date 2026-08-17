import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/features/service_status/presentation/widgets/service_status_banner.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/client_auth/presentation/cubit/client_session_cubit.dart';
import 'package:fotdelsi/features/client_auth/presentation/widgets/link_phone_prompt.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_session_cubit.dart';
import '../bloc/machines_bloc.dart';
import '../bloc/machines_event.dart';
import '../bloc/machines_state.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_fabs.dart';
import 'package:fotdelsi/features/catalog/presentation/cubit/service_catalog_cubit.dart';
import 'package:fotdelsi/features/catalog/presentation/widgets/service_catalog_content.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/active_session_card.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_cycles_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Toujours nécessaire : alimente le temps réel et permet de retrouver
        // la machine ciblée par une session en cours.
        // `.value` et non `create` : le bloc est partagé, le fermer en
        // quittant l'accueil couperait le flux des autres écrans.
        BlocProvider.value(
          value: serviceLocator<MachinesBloc>()
            ..add(const MachinesSubscriptionRequested()),
        ),
        BlocProvider(
          create: (_) => serviceLocator<ServiceCatalogCubit>()..load(),
        ),
        // Alimente le bandeau de cycle. Le battement fait avancer le temps
        // écoulé et resynchronise sur le serveur toutes les 10 s, au rythme
        // du relevé des machines.
        BlocProvider(
          create: (_) => serviceLocator<MyCyclesCubit>()
            ..load()
            ..startTicking(),
        ),
      ],
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
    // Retour d'info du seul « Démarrer » de cet écran : celui du bandeau de
    // cycle en cours, qui passe par `MyCyclesCubit`.
    //
    // Cet écouteur guettait auparavant `WashSessionCubit.startStatus`, hérité
    // du temps où le démarrage partait de la carte machine. Plus personne ne
    // fait sortir ce statut de `idle` : l'accueil écoutait donc un canal muet,
    // et un refus du serveur — machine occupée, hors-ligne — n'y produisait
    // rien, alors que « Mes lavages », branché sur le bon cubit, affichait
    // bien le message.
    //
    // `start()` vide l'erreur avant chaque tentative : deux échecs identiques
    // d'affilée restent deux transitions distinctes, et le second geste obtient
    // bien son message.
    return BlocListener<MyCyclesCubit, WashCyclesState>(
      listenWhen: (p, c) => p.error != c.error && c.error != null,
      listener: (context, state) => _signalerEchec(context, state.error!),
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
        floatingActionButton: const HomeFabs(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: const ServiceStatusBanner(),
      ),
    );
  }

  /// Annonce un échec de démarrage, d'où qu'il vienne.
  ///
  /// `hideCurrentSnackBar` d'abord : sans cela, un second essai fait la queue
  /// derrière le message du premier, et la réponse paraît ne pas venir.
  void _signalerEchec(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
  }

  /// L'accueil présente les services ; les machines ne servent plus qu'à
  /// afficher la session en cours et sont choisies à l'étape suivante. Un échec
  /// de chargement des machines n'empêche donc plus de consulter l'offre.
  Widget _body(BuildContext context, MachinesState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ne dépend plus de la liste des machines : le cycle et son temps
          // restant viennent du serveur. C'est cette dépendance qui faisait
          // clignoter le bandeau à chaque message temps réel.
          const ActiveSessionCard(),
          const ServiceCatalogContent(),
        ],
      ),
    );
  }
}

/// Colonne de FABs en bas à droite.
///
/// Structure (de bas en haut) :
///   • FAB scan — toujours visible.
///   • FAB session — visible si paiement confirmé ET machine pas encore démarrée.
///   • FAB running — visible si machine en cours.
