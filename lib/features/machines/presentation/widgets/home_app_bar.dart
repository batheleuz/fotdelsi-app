import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/constants/app_images.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/websocket/ws_connection_cubit.dart';
import 'package:fotdelsi/core/websocket/ws_connection_status.dart';
import 'package:fotdelsi/core/widgets/app_popup_menu.dart';
import 'package:fotdelsi/features/client_auth/presentation/cubit/client_session_cubit.dart';
import 'connection_status_chip.dart';

/// En-tête de l'accueil : logo + état de connexion + menu d'actions.
///
/// Les actions (lier son numéro / mon compte, connexion personnel) sont
/// regroupées dans un menu overflow pour garder l'en-tête épuré.
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
              BlocBuilder<WsConnectionCubit, WsConnectionStatus>(
                builder: (context, status) =>
                    ConnectionStatusChip(status: status),
              ),
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
                    ] else
                      AppMenuEntry(
                        icon: Icons.sms_outlined,
                        label: 'Lier mon numéro',
                        onSelected: () => context.push(AppRoutes.linkPhone),
                      ),
                    AppMenuEntry(
                      icon: Icons.badge_outlined,
                      label: 'Connexion personnel',
                      onSelected: () => context.push(AppRoutes.login),
                    ),
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
