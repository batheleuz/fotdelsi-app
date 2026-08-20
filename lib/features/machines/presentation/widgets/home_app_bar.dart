import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/constants/app_images.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/app_popup_menu.dart';
import 'package:fotdelsi/features/client_auth/presentation/cubit/client_session_cubit.dart';

/// En-tête de l'accueil : logo + menu d'actions.
///
/// Pas de pastille de connexion : l'accueil présente un catalogue de services,
/// qui ne dépend d'aucun flux temps réel. L'y afficher laissait croire à une
/// panne alors que rien n'était en cause — sa place est sur les écrans qui
/// montrent réellement l'état des machines.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _Logo(),
          Row(
            children: [
              BlocBuilder<ClientSessionCubit, ClientSessionState>(
                builder: (context, session) => AppPopupMenu(
                  entries: [
                    if (session.isLinked) ...[
                      AppMenuEntry(
                        icon: Icons.local_laundry_service_outlined,
                        label: 'Mes dépôts',
                        onSelected: () => context.push(AppRoutes.myDropOffs),
                      ),
                      AppMenuEntry(
                        icon: Icons.account_circle_outlined,
                        label: 'Mon compte',
                        onSelected: () => context.push(AppRoutes.clientAccount),
                      ),
                    ] else ...[
                      AppMenuEntry(
                        icon: Icons.sms_outlined,
                        label: 'Connexion Client',
                        onSelected: () => context.push(AppRoutes.linkPhone),
                      ),
                      // Réservé à l'appareil encore anonyme : les deux
                      // identités sont mutuellement exclusives, proposer la
                      // connexion personnel à un client déjà lié n'a pas de
                      // sens et l'invite à une impasse.
                      AppMenuEntry(
                        icon: Icons.badge_outlined,
                        label: 'Connexion Admin',
                        onSelected: () => context.push(AppRoutes.login),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Image.asset(AppImages.logo, fit: BoxFit.cover),
    );
  }
}
