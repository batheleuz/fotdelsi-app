import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import '../cubit/client_session_cubit.dart';
import '../cubit/link_phone_cubit.dart';
import 'otp_input.dart';

/// Demande au client de lier son numéro, sans quitter l'écran en cours.
///
/// Une feuille plutôt qu'une page : le client est en train de payer, l'envoyer
/// sur un autre écran lui ferait perdre le fil de son achat. Ici il voit
/// toujours ce qu'il est en train de faire derrière la feuille, et revient
/// exactement là où il était.
///
/// Retourne `true` si le numéro a bien été lié — l'appelant peut alors
/// poursuivre. `false` ou `null` si le client a renoncé.
Future<bool> showLinkPhoneSheet(BuildContext context) async {
  final linked = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Fermeture par glissement autorisée : exiger le numéro ne veut pas dire
    // piéger le client dans une feuille dont il ne peut pas sortir.
    isDismissible: true,
    builder: (_) => BlocProvider(
      create: (_) => serviceLocator<LinkPhoneCubit>(),
      child: const _LinkPhoneSheet(),
    ),
  );

  if (linked == true && context.mounted) {
    // La session vient de changer : le reste de l'app doit le savoir.
    await context.read<ClientSessionCubit>().refresh();
  }
  return linked ?? false;
}

class _LinkPhoneSheet extends StatefulWidget {
  const _LinkPhoneSheet();

  @override
  State<_LinkPhoneSheet> createState() => _LinkPhoneSheetState();
}

class _LinkPhoneSheetState extends State<_LinkPhoneSheet> {
  final _phoneController = TextEditingController();
  String _phone = '';

  /// La feuille porte les DEUX temps du parcours : saisie du numéro, puis du
  /// code. Les séparer en deux feuilles ferait clignoter l'écran entre les
  /// deux et perdrait le contexte de l'achat.
  bool _awaitingCode = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _phoneLooksValid => _phone.replaceAll(RegExp(r'\D'), '').length >= 9;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LinkPhoneCubit, LinkPhoneState>(
      listener: (context, state) {
        // Liaison aboutie — directement, ou après vérification du code.
        if (state.verifyStatus == LinkStatus.success) {
          Navigator.of(context).pop(true);
          return;
        }
        // Code envoyé : on passe au second temps, dans la même feuille.
        if (state.requestStatus == LinkStatus.success && !_awaitingCode) {
          setState(() => _awaitingCode = true);
        }
      },
      builder: (context, state) {
        return Padding(
          // Remonte la feuille au-dessus du clavier, sinon les champs sont
          // masqués au moment précis où on les remplit.
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

                Text(
                  _awaitingCode ? 'Code de vérification' : 'Votre numéro',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _awaitingCode
                      ? 'Saisissez le code envoyé au $_phone.'
                      : 'Nécessaire pour retrouver vos lavages et vous '
                            'prévenir quand votre linge est prêt.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_awaitingCode)
                  _CodeStep(state: state, phone: _phone)
                else
                  _PhoneStep(
                    controller: _phoneController,
                    onChanged: (v) => setState(() => _phone = v),
                  ),

                // Le message vient du backend et s'affiche ICI : renvoyer le
                // client sur une autre surface pour lire une erreur, c'est lui
                // faire perdre ce qu'il vient de saisir.
                if (state.error != null) ...[
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
                          state.error!,
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
                if (!_awaitingCode)
                  PrimaryButton(
                    label: 'Continuer',
                    enabled: _phoneLooksValid,
                    loading: state.isRequesting,
                    onPressed: () =>
                        context.read<LinkPhoneCubit>().start(_phone),
                  )
                else
                  TextButton(
                    onPressed: state.isRequesting
                        ? null
                        : () => context.read<LinkPhoneCubit>().resend(_phone),
                    child: Text(
                      state.isRequesting ? 'Envoi…' : 'Renvoyer le code',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: true,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
        LengthLimitingTextInputFormatter(15),
      ],
      decoration: const InputDecoration(
        hintText: '77 000 00 00',
        prefixIcon: Icon(Icons.phone_outlined),
      ),
    );
  }
}

class _CodeStep extends StatelessWidget {
  const _CodeStep({required this.state, required this.phone});

  final LinkPhoneState state;
  final String phone;

  @override
  Widget build(BuildContext context) {
    if (state.isVerifying) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return OtpInput(
      hasError: state.verifyStatus == LinkStatus.failure,
      onCompleted: (code) =>
          context.read<LinkPhoneCubit>().verifyOtp(phone: phone, code: code),
    );
  }
}
