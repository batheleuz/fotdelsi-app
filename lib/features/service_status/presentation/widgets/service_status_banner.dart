import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import '../cubit/service_status_cubit.dart';

/// Bannière d'avertissement (bas d'écran) listant les services critiques
/// momentanément indisponibles. Invisible tant que tout va bien.
///
/// À placer dans le `bottomNavigationBar` (ou en bas du body) des écrans clés.
class ServiceStatusBanner extends StatelessWidget {
  const ServiceStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceStatusCubit, ServiceStatusState>(
      builder: (context, state) {
        if (!state.hasWarnings) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final w in state.warnings)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _WarningBar(message: w.message),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WarningBar extends StatelessWidget {
  const _WarningBar({required this.message});

  final String message;

  static const _text = Color(0xFF8A5A0E);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: _text),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: _text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
