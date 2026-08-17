import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/features/payment/presentation/widgets/payment_qr_view.dart';
import '../../cubit/counter_sale_cubit.dart';

/// Étape 3 — le code à scanner.
///
/// Le seul écran de l'application destiné à être lu par quelqu'un d'AUTRE que
/// son porteur : l'agent tourne son téléphone vers le client. D'où le
/// traitement à part — pas de progression, pas de bouton, fond teinté, code
/// aussi grand que possible. Rien qui puisse être touché par mégarde pendant
/// que le client scanne.
class SalePaymentStep extends StatelessWidget {
  const SalePaymentStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CounterSaleCubit>().state;
    final payload = state.qrPayload;

    return Container(
      width: double.infinity,
      color: AppColors.surfaceTint,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Scannez pour payer',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Avec l\'appareil photo de votre téléphone',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),

          if (payload != null)
            PaymentQrView(
              payload: payload,
              provider: state.provider!,
              amount: state.total,
              size: 240,
            )
          else
            // Sans lien exploitable, on le dit : un QR vide ferait perdre du
            // temps à l'agent devant son client.
            const _NoPayload(),

          const SizedBox(height: 32),
          if (state.isAwaitingPayment) const _Waiting(),
        ],
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 10),
        Text(
          'En attente du paiement…',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _NoPayload extends StatelessWidget {
  const _NoPayload();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger),
      ),
      child: const Text(
        'Lien de paiement indisponible. Reprenez la vente.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: AppColors.danger),
      ),
    );
  }
}
