import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_radius.dart';
import '../../domain/entities/payment_provider.dart';
import '../utils/payment_provider_presentation.dart';

/// Logo du moyen de paiement.
///
/// Phase design : tuile colorée à la marque avec l'initiale. À remplacer par
/// `Image.asset(provider.logoAsset)` une fois les logos officiels ajoutés.
class PaymentProviderLogo extends StatelessWidget {
  const PaymentProviderLogo({
    super.key,
    required this.provider,
    this.size = 42,
  });

  final PaymentProvider provider;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm + 3),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Image.asset(provider.logoAsset, fit: BoxFit.cover),
    );
  }
}
