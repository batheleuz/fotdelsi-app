import 'package:flutter/material.dart';

import '../../domain/entities/payment_provider.dart';

/// Branding présentation des moyens de paiement (logos affichés par nous-mêmes
/// en SOFTPAY — PayDunya n'apparaît jamais).
extension PaymentProviderX on PaymentProvider {
  String get label => switch (this) {
        PaymentProvider.wave => 'Wave',
        PaymentProvider.orangeMoney => 'Orange Money',
      };

  String get tagline => switch (this) {
        PaymentProvider.wave => 'Paiement mobile',
        PaymentProvider.orangeMoney => 'Paiement mobile',
      };

  Color get brandColor => switch (this) {
        PaymentProvider.wave => const Color(0xFF1DC1EC),
        PaymentProvider.orangeMoney => const Color(0xFFFF7900),
      };

  /// Chemin de l'asset logo officiel à intégrer plus tard
  /// (`flutter:` > `assets:` dans pubspec).
  String get logoAsset => switch (this) {
        PaymentProvider.wave => 'assets/payment/wave.png',
        PaymentProvider.orangeMoney => 'assets/payment/orange_money.png',
      };
}
