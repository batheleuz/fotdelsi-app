import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';

/// Contenu unifié d'un cycle en cours — même design partout dans l'app.
///
/// Affiche :
///  - un badge de phase (« Lavage lancé », « Séchage en cours »…)
///  - une carte d'instructions (optionnelle)
///  - le temps écoulé depuis le démarrage (« 00:07 / Depuis »)
///  - un message optionnel en bas
///
/// [StatefulWidget] : un `Timer` interne fait avancer le compteur chaque
/// seconde, indépendamment du rythme des relevés serveur.
class CycleRunningCard extends StatefulWidget {
  const CycleRunningCard({
    super.key,
    required this.startedAt,
    required this.phaseLabel,
    this.phaseIcon = Icons.local_laundry_service_rounded,
    this.instructionTitle,
    this.instructionBody,
    this.footerMessage,
  });

  /// Instant de démarrage du cycle — sert à calculer le temps écoulé.
  final DateTime? startedAt;

  /// Texte du badge de phase (ex. « Lavage lancé »).
  final String phaseLabel;

  /// Icône du badge de phase.
  final IconData phaseIcon;

  /// Titre gras de la carte d'instructions (ex. « Commande de démarrage
  /// envoyée »). `null` → pas de titre.
  final String? instructionTitle;

  /// Corps de la carte d'instructions. `null` → pas de carte.
  final String? instructionBody;

  /// Message gris en bas (ex. « Nous vous préviendrons… »). `null` → rien.
  final String? footerMessage;

  @override
  State<CycleRunningCard> createState() => _CycleRunningCardState();
}

class _CycleRunningCardState extends State<CycleRunningCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.startedAt;
    final elapsed = start != null
        ? (DateTime.now().isAfter(start)
            ? DateTime.now().difference(start)
            : Duration.zero)
        : null;

    return Column(
      children: [
        // Badge de phase
        _PhaseBadge(label: widget.phaseLabel, icon: widget.phaseIcon),

        // Carte d'instructions
        if (widget.instructionTitle != null ||
            widget.instructionBody != null) ...[
          const SizedBox(height: AppSpacing.md),
          _InstructionCard(
            title: widget.instructionTitle,
            body: widget.instructionBody,
          ),
        ],

        // Temps écoulé
        const SizedBox(height: AppSpacing.lg),
        Text(
          elapsed != null ? _clock(elapsed) : '--:--',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Depuis',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),

        // Message de bas de page
        if (widget.footerMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.footerMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  static String _clock(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }
}

/// Pilule colorée indiquant la phase du cycle.
class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surfaceTint,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );
}

/// Carte d'information avec icône de validation, titre optionnel et corps.
class _InstructionCard extends StatelessWidget {
  const _InstructionCard({this.title, this.body});

  final String? title;
  final String? body;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceTint,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              if (title != null && body != null) const SizedBox(height: 3),
              if (body != null)
                Text(
                  body!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
