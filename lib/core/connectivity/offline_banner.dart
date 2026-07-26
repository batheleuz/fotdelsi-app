import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_cubit.dart';
import 'connectivity_status.dart';

/// Bandeau global « hors ligne » (inspiré de l'app Wave) : une barre sombre
/// flottante qui apparaît en bas de l'écran quand l'appareil perd la connexion.
///
/// Pensé pour être posé au-dessus de toutes les pages via le `builder` de
/// `MaterialApp.router`. En ligne : masqué (glissé hors champ + transparent, et
/// ne capture aucun tap).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, status) {
        final offline = status == ConnectivityStatus.offline;
        return IgnorePointer(
          ignoring: !offline,
          child: SafeArea(
            top: false,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              offset: offline ? Offset.zero : const Offset(0, 1.6),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: offline ? 1 : 0,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _OfflineBar(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OfflineBar extends StatelessWidget {
  const _OfflineBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2B303B),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Vous êtes actuellement hors ligne. Vérifiez votre connexion internet.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
