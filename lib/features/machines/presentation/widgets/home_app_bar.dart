import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/constants/app_images.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/websocket/ws_connection_cubit.dart';
import 'package:fotdelsi/core/websocket/ws_connection_status.dart';
import 'connection_status_chip.dart';

/// En-tête de l'accueil : logo textuel FOT DELSI + état de connexion.
///
/// L'état WS est lu directement depuis le [WsConnectionCubit] global — aucun
/// paramètre à passer depuis la page parente.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _Logo(),
          BlocBuilder<WsConnectionCubit, WsConnectionStatus>(
            builder: (context, status) =>
                ConnectionStatusChip(status: status),
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
