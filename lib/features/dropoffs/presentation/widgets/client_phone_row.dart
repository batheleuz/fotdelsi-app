import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/utils/phone_number.dart';

/// Numéro du client, avec de quoi l'appeler.
///
/// Le numéro était enregistré partout et affiché nulle part côté agent : pour
/// convenir d'une remise, il fallait le retrouver ailleurs. Il est ici lisible
/// (« 77 123 45 67 » plutôt qu'un bloc de neuf chiffres) et directement
/// composable.
///
/// L'appui long copie : un agent qui préfère son propre répertoire, ou dont le
/// téléphone n'a pas d'application de téléphonie, ne se retrouve pas bloqué.
class ClientPhoneRow extends StatelessWidget {
  const ClientPhoneRow({super.key, required this.phone, this.dense = false});

  final String phone;

  /// Version compacte, pour une carte de liste.
  final bool dense;

  Future<void> _appeler(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: dialablePhone(phone));

    // `launchUrl` échoue sur un appareil sans application de téléphonie — une
    // tablette, un simulateur. On le dit, au lieu de ne rien faire.
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Impossible de lancer l\'appel.')),
        );
    }
  }

  Future<void> _copier(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: dialablePhone(phone)));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Numéro copié')));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _appeler(context),
      onLongPress: () => _copier(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 0 : 4,
          vertical: dense ? 2 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phone_rounded,
              size: dense ? 14 : 17,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              displayPhone(phone),
              style: TextStyle(
                fontSize: dense ? 12.5 : 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
