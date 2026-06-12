import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fotdelsi/features/wash_session/domain/entities/pending_wash_session.dart';
import '../../domain/entities/payment_provider.dart';

/// Gère le lancement de l'application de paiement après initiation.
///
/// - Wave      : ouvre `redirectUrl` en mode external application.
/// - Orange Money : essaie Maxit (`maxitUrl`), puis OM app (`omUrl`),
///               sinon affiche le QR code dans une dialog.
abstract final class PaymentLauncher {
  const PaymentLauncher._();

  static Future<void> launch(
    BuildContext context,
    PendingWashSession session,
  ) async {
    switch (session.provider) {
      case PaymentProvider.wave:
        await _launchWave(context, session.redirectUrl);
      case PaymentProvider.orangeMoney:
        await _launchOrangeMoney(context, session);
    }
  }

  // ── Wave ────────────────────────────────────────────────────────────────────

  static Future<void> _launchWave(
    BuildContext context,
    String? redirectUrl,
  ) async {
    if (redirectUrl == null) {
      _showError(context, 'URL Wave indisponible.');
      return;
    }
    final uri = Uri.parse(redirectUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) _showError(context, 'Wave n\'est pas installé.');
    }
  }

  // ── Orange Money ─────────────────────────────────────────────────────────────

  static Future<void> _launchOrangeMoney(
    BuildContext context,
    PendingWashSession session,
  ) async {
    // 1. Maxit (prioritaire)
    if (session.maxitUrl != null) {
      final uri = Uri.parse(session.maxitUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // 2. OM app
    if (session.omUrl != null) {
      final uri = Uri.parse(session.omUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // 3. QR code de secours
    if (context.mounted) {
      if (session.qrCodeUrl != null) {
        _showQrDialog(context, session.qrCodeUrl!);
      } else {
        _showError(context, 'Orange Money n\'est pas disponible sur cet appareil.');
      }
    }
  }

  // ── Helpers UI ──────────────────────────────────────────────────────────────

  static void _showQrDialog(BuildContext context, String qrCodeUrl) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scanner le QR Orange Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ouvrez votre app Orange Money et scannez ce QR pour finaliser le paiement.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Image.network(
              qrCodeUrl,
              width: 200,
              height: 200,
              errorBuilder: (context, error, stack) => const Icon(
                Icons.qr_code_2_rounded,
                size: 80,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
