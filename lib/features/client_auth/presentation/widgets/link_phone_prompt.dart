import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';

/// Résultat de l'interaction avec le bottom sheet.
typedef _PromptResult = ({bool link, bool dontShowAgain});

/// Incitation discrète à lier son numéro de téléphone.
///
/// Affiché à l'arrivée sur l'accueil (après un court délai) si : le numéro
/// n'est pas lié, l'utilisateur n'a pas coché « ne plus afficher », et le
/// dernier affichage date de plus de 24 h (throttling anti-spam).
abstract final class LinkPhonePrompt {
  const LinkPhonePrompt._();

  static const _kDismissed = 'link_phone_prompt_dismissed';
  static const _kLastShownMs = 'link_phone_prompt_last_shown_ms';
  static const _throttle = Duration(hours: 24);

  static Future<void> maybeShow(BuildContext context) async {
    final prefs = serviceLocator<SharedPreferences>();

    if (prefs.getBool(_kDismissed) ?? false) return;
    final last = prefs.getInt(_kLastShownMs);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (last != null && now - last < _throttle.inMilliseconds) return;

    await prefs.setInt(_kLastShownMs, now);
    if (!context.mounted) return;

    final result = await showModalBottomSheet<_PromptResult>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const _LinkPhonePromptSheet(),
    );

    if (result == null) return; // fermé en tapant à l'extérieur
    if (result.dontShowAgain) await prefs.setBool(_kDismissed, true);
    if (result.link && context.mounted) {
      context.push(AppRoutes.linkPhone);
    }
  }
}

class _LinkPhonePromptSheet extends StatefulWidget {
  const _LinkPhonePromptSheet();

  @override
  State<_LinkPhonePromptSheet> createState() => _LinkPhonePromptSheetState();
}

class _LinkPhonePromptSheetState extends State<_LinkPhonePromptSheet> {
  bool _dontShowAgain = false;

  void _close({required bool link}) {
    Navigator.of(context).pop((link: link, dontShowAgain: _dontShowAgain));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sms_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Lier votre téléphone',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Recevez une alerte dès que votre linge est prêt et retrouvez '
            'l\'historique de vos dépôts. C\'est rapide : un simple code reçu par SMS.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: _dontShowAgain,
                    onChanged: (v) =>
                        setState(() => _dontShowAgain = v ?? false),
                    activeColor: AppColors.primaryLight,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Ne plus afficher',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: 'Lier mon numéro',
            icon: Icons.arrow_forward_rounded,
            backgroundColor: AppColors.primaryLight,
            onPressed: () => _close(link: true),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => _close(link: false),
            child: const Text('Plus tard'),
          ),
        ],
      ),
    );
  }
}
