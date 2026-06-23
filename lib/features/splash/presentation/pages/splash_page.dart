import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/constants/app_images.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/auth/presentation/cubit/auth_cubit.dart';

/// Écran de démarrage : affiche le logo pendant la détermination du profil
/// (lecture du secure storage via [AuthCubit.bootstrap]).
///
/// Une fois le profil connu (statut ≠ unknown), le `redirect` du routeur
/// quitte automatiquement le splash vers la bonne destination.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// Durée minimale d'affichage, pour que le logo ne « flashe » pas.
  static const _minDisplay = Duration(milliseconds: 1500);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Affiche le logo un minimum, puis déclenche la restauration de session.
    await Future.delayed(SplashPage._minDisplay);
    if (!mounted) return;
    await context.read<AuthCubit>().bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 96,
              child: Image.asset(AppImages.logo, fit: BoxFit.contain),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
