import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fotdelsi/core/motion/entrance.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import '../../domain/entities/pending_payment.dart';
import '../cubit/pending_payments_cubit.dart';

/// Bandeau « Paiement en attente », avec de quoi le reprendre.
///
/// Le lien de paiement reste honorable une trentaine de minutes, mais il ne
/// vivait nulle part au-delà de l'écran qui l'avait affiché : un client dont le
/// solde manquait n'avait aucun moyen d'y revenir après avoir rechargé. Il est
/// désormais conservé par le serveur, et repris ici.
class PendingPaymentBanner extends StatelessWidget {
  const PendingPaymentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final paiement = context.select<ClientPendingPaymentsCubit, PendingPayment?>(
      (c) => c.state.mostRecent,
    );

    return AnimatedReveal(
      visible: paiement != null,
      child: paiement == null
          ? const SizedBox.shrink()
          : _Banner(paiement: paiement),
    );
  }
}

/// Bandeau dont le décompte avance vraiment.
///
/// Le temps restant se calcule au rendu : sans horloge, il gardait la valeur
/// qu'il avait à l'ouverture de l'écran. Un client resté dix minutes sur
/// l'accueil lisait toujours « il vous reste 28 min », et découvrait le lien
/// mort sans avoir vu le compte s'écouler.
///
/// Un battement d'une minute, pas d'une seconde : l'affichage est en minutes,
/// et reconstruire soixante fois plus souvent ne changerait rien à ce qui est
/// écrit.
class _Banner extends StatefulWidget {
  const _Banner({required this.paiement});

  final PendingPayment paiement;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> {
  Timer? _horloge;

  @override
  void initState() {
    super.initState();
    _horloge = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _horloge?.cancel();
    super.dispose();
  }

  PendingPayment get paiement => widget.paiement;

  Future<void> _payer(BuildContext context) async {
    final cubit = context.read<ClientPendingPaymentsCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final uri = Uri.tryParse(paiement.checkoutUrl!);
    final ouvert =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ouvert) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir la page de paiement.'),
            backgroundColor: AppColors.danger,
          ),
        );
      return;
    }

    // Le résultat n'est connu que du serveur : on retire la ligne sans
    // prétendre que c'est payé. Le prochain chargement dira la vérité.
    cubit.dismiss(paiement.paymentId);
  }

  /// La réservation ne dure que cinq minutes : sous la minute, afficher
  /// « 0 min » ferait croire que c'est déjà perdu alors qu'il reste du temps.
  static String? _dureeDeGarde(Duration? reste) {
    if (reste == null) return null;
    final minutes = reste.inMinutes;
    return minutes < 1 ? 'moins d\'une minute' : '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final minutes = paiement.remaining.inMinutes;
    final garde = _dureeDeGarde(paiement.holdRemaining);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3E2),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFEF9F27).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hourglass_bottom_rounded,
                size: 19,
                color: Color(0xFF8A5A0E),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Paiement en attente',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A5A0E),
                  ),
                ),
              ),
              Text(
                formatFcfa(paiement.amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A5A0E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            [
              ?paiement.formulaLabel,
              ?paiement.machineName,
            ].join(' · '),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 10),
          // DEUX échéances, jamais dans la même phrase.
          //
          // « Votre machine est réservée. Il vous reste 27 min pour payer. »
          // se lit comme une machine tenue 27 minutes. Elle l'est cinq. Le
          // client repartait donc tranquille, et retrouvait sa machine prise.
          //
          // Chaque durée porte désormais son propre sujet, et la plus courte
          // — la seule qui contraigne vraiment — passe en premier, en gras.
          Text(
            garde == null
                ? 'La machine n\'est plus réservée'
                : 'Votre machine est réservée pour encore $garde',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: garde == null
                  ? AppColors.danger
                  : const Color(0xFF8A5A0E),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            garde == null
                ? 'Elle a pu être prise par quelqu\'un d\'autre. '
                      'Le paiement reste possible pendant $minutes min.'
                : 'Ensuite, elle peut être prise par quelqu\'un d\'autre. '
                      'Le paiement, lui, reste possible pendant $minutes min.',
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _payer(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Confirmer le paiement'),
            ),
          ),
        ],
      ),
    );
  }
}
