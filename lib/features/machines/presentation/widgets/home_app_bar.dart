import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/constants/app_images.dart';
import 'connection_status_chip.dart';

/// En-tête de l'accueil : logo textuel FOT DELSI + état de connexion.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key, required this.connected});

  final bool connected;

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
          ConnectionStatusChip(connected: connected),
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
