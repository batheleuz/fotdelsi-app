import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import '../../domain/entities/drop_off.dart';
import '../../domain/entities/drop_off_status.dart';

/// Une étape du parcours : son intitulé et l'instant où elle a été franchie.
typedef _Stage = (String, DateTime?);

/// Timeline verticale des étapes d'un dépôt.
///
/// ─── Deux parcours, pas un ───
///
/// Un dépôt confié au comptoir passe par : Reçu → Lavage lancé → Prêt → Remis.
/// Un dépôt né d'un libre-service, non : le client a lavé et séché lui-même, et
/// [DropOff.assignMachine] lui INTERDIT tout cycle machine. Son `startedAt` ne
/// marque donc pas un lavage mais la prise en charge au comptoir.
///
/// Leur imposer le parcours agent affichait « Lavage lancé » jamais coché sur un
/// linge pourtant lavé — l'étape ne pouvait structurellement pas se franchir —
/// et « Reçu » coché alors que le linge était encore chez le client, `receivedAt`
/// étant posé dès le paiement.
class DropOffTimeline extends StatelessWidget {
  const DropOffTimeline({super.key, required this.dropOff});

  final DropOff dropOff;

  static const _green = Color(0xFF1D9E75);
  static const _future = Color(0xFFD7E0EE);

  /// Étapes du parcours suivi par CE dépôt.
  List<_Stage> get _stages => dropOff.isSelfService
      ? [
          // Les machines sont derrière : elles ont tourné sur la session de
          // lavage du client, pas sur ce dépôt. L'étape est acquise par
          // construction — un dépôt libre-service n'existe qu'une fois payé,
          // et le code de remise ne lui parvient qu'en fin de cycle.
          ('Lavé par le client', dropOff.receivedAt),
          ('Apporté au comptoir', dropOff.startedAt),
          ('Prêt', dropOff.readyAt),
          ('Remis au client', dropOff.collectedAt),
        ]
      : [
          ('Reçu', dropOff.receivedAt),
          ('Lavage lancé', dropOff.startedAt),
          ('Prêt', dropOff.readyAt),
          ('Remis au client', dropOff.collectedAt),
        ];

  /// Étape en cours — celle qui attend un geste.
  ///
  /// `awaitingHandoff` manquait à ce filtrage et retombait sur le repli, qui
  /// désignait la DERNIÈRE étape : un linge pas encore apporté s'affichait au
  /// stade « Remis au client ».
  int get _activeIndex => switch (dropOff.status) {
    DropOffStatus.awaitingHandoff => 1,
    DropOffStatus.received => 0,
    DropOffStatus.inProgress => 1,
    DropOffStatus.ready => 2,
    DropOffStatus.collected => 3,
    _ => 3,
  };

  @override
  Widget build(BuildContext context) {
    final stages = _stages;

    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          _Row(
            label: stages[i].$1,
            time: stages[i].$2,
            done: stages[i].$2 != null,
            active: i == _activeIndex && !dropOff.status.isTerminal,
            isLast: i == stages.length - 1,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.time,
    required this.done,
    required this.active,
    required this.isLast,
  });

  final String label;
  final DateTime? time;
  final bool done;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done ? DropOffTimeline._green : DropOffTimeline._future;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: done
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: DropOffTimeline._future),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: done || active
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                if (time != null)
                  Text(
                    _hhmm(time!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
