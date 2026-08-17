import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import '../cubit/client_session_cubit.dart';

/// Modification du nom du client, sans quitter son compte.
///
/// Même parti pris que la liaison du numéro : une feuille plutôt qu'une page.
/// Le geste est court, et le contexte — la fiche du compte — reste visible
/// derrière.
Future<void> showEditNameSheet(BuildContext context) {
  final cubit = context.read<ClientSessionCubit>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // `.value` : la feuille s'ouvre sur une autre branche de l'arbre, elle
    // n'hériterait pas du cubit fourni plus haut.
    builder: (_) => BlocProvider.value(value: cubit, child: const _EditName()),
  );
}

class _EditName extends StatefulWidget {
  const _EditName();

  @override
  State<_EditName> createState() => _EditNameState();
}

class _EditNameState extends State<_EditName> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<ClientSessionCubit>().state.fullName ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _controller.text.trim();

    // Un champ vidé efface le nom au lieu d'enregistrer une chaîne blanche :
    // ne pas se nommer est un état légitime, et il doit s'écrire d'une seule
    // façon.
    final message = await context.read<ClientSessionCubit>().rename(
      raw.isEmpty ? null : raw,
    );

    if (!mounted) return;
    if (message == null) {
      Navigator.of(context).pop();
      return;
    }
    // Le message vient du serveur et s'affiche ici : renvoyer l'utilisateur
    // ailleurs pour lire une erreur lui ferait perdre sa saisie.
    setState(() => _error = message);
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.select<ClientSessionCubit, bool>(
      (c) => c.state.saving,
    );

    return Padding(
      // Remonte la feuille au-dessus du clavier, sinon le champ est masqué au
      // moment précis où on le remplit.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            const Text(
              'Votre nom',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Il pré-remplira vos paiements et permettra à l\'agent de vous '
              'reconnaître au comptoir.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 100,
              decoration: const InputDecoration(
                hintText: 'Awa Diop',
                prefixIcon: Icon(Icons.person_outline),
                counterText: '',
              ),
              onSubmitted: (_) => _save(),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Enregistrer',
              loading: saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
