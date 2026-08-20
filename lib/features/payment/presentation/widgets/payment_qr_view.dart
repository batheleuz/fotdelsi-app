import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import '../../domain/entities/payment_provider.dart';
import 'payment_provider_logo.dart';

/// QR de paiement, généré localement à partir du lien de l'opérateur.
///
/// Destiné au client qui n'a pas l'application : l'agent affiche ce QR, le
/// client le scanne avec l'appareil photo de son téléphone et atterrit dans
/// Wave ou Orange Money, montant et référence déjà rattachés.
///
/// Généré sur l'appareil plutôt que chargé depuis PayDunya : rendu immédiat,
/// aucune dépendance réseau au moment de le montrer — et l'URL « qrCodeUrl »
/// de PayDunya n'est de toute façon pas une image mais une page HTML.
class PaymentQrView extends StatelessWidget {
  const PaymentQrView({
    super.key,
    required this.payload,
    required this.provider,
    this.amount,
    this.size = 240,
  });

  /// Lien de paiement `https` de l'opérateur.
  final String payload;
  final PaymentProvider provider;

  /// Montant rappelé sous le code, pour que l'agent puisse le confirmer à voix
  /// haute — le client, lui, le verra dans son application.
  final int? amount;

  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: QrImageView(
            data: payload,
            version: QrVersions.auto,
            size: size,
            // Marge intégrée : sans zone blanche autour, beaucoup de lecteurs
            // échouent à décoder.
            padding: EdgeInsets.zero,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.textPrimary,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PaymentProviderLogo(provider: provider, size: 26),
            const SizedBox(width: 8),
            if (amount != null)
              Text(
                formatFcfa(amount!),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
