import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import '../cubit/link_phone_cubit.dart';

final _phoneRegex = RegExp(r'^(70|71|75|76|77|78)\d{7}$');

/// Écran « Lier mon numéro » : saisie du numéro, envoi de l'OTP.
class LinkPhonePage extends StatelessWidget {
  const LinkPhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<LinkPhoneCubit>(),
      child: const _LinkPhoneView(),
    );
  }
}

class _LinkPhoneView extends StatefulWidget {
  const _LinkPhoneView();

  @override
  State<_LinkPhoneView> createState() => _LinkPhoneViewState();
}

class _LinkPhoneViewState extends State<_LinkPhoneView> {
  final _controller = TextEditingController();
  String _phone = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _phoneRegex.hasMatch(_phone);

  void _submit() {
    if (_valid) {
      FocusScope.of(context).unfocus();
      context.read<LinkPhoneCubit>().requestOtp(_phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lier mon numéro'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocConsumer<LinkPhoneCubit, LinkPhoneState>(
          listenWhen: (p, c) => p.requestStatus != c.requestStatus,
          listener: (context, state) {
            if (state.requestStatus == LinkStatus.success) {
              context.push(AppRoutes.linkPhoneVerify, extra: _phone);
            } else if (state.requestStatus == LinkStatus.failure &&
                state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    backgroundColor: AppColors.danger,
                  ),
                );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Recevez vos notifications',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Liez votre numéro pour suivre vos dépôts et être prévenu quand votre linge est prêt.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) => setState(() => _phone = v),
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone',
                      hintText: '77 123 45 67',
                      counterText: '',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Text(
                          '+221',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(
                          color: AppColors.primaryLight,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 2),
                    child: Text(
                      'Préfixes acceptés : 70 · 71 · 75 · 76 · 77 · 78',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Recevoir le code',
                    icon: Icons.sms_outlined,
                    enabled: _valid && !state.isRequesting,
                    loading: state.isRequesting,
                    backgroundColor: AppColors.primaryLight,
                    onPressed: _submit,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
