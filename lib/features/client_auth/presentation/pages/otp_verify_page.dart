import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/notifications/presentation/push_notification_service.dart';
import '../cubit/client_session_cubit.dart';
import '../cubit/link_phone_cubit.dart';
import '../widgets/otp_input.dart';

/// Écran « Saisie OTP » : vérifie le code reçu par SMS et lie le numéro.
class OtpVerifyPage extends StatelessWidget {
  const OtpVerifyPage({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<LinkPhoneCubit>(),
      child: _OtpVerifyView(phone: phone),
    );
  }
}

class _OtpVerifyView extends StatefulWidget {
  const _OtpVerifyView({required this.phone});

  final String phone;

  @override
  State<_OtpVerifyView> createState() => _OtpVerifyViewState();
}

class _OtpVerifyViewState extends State<_OtpVerifyView> {
  static const _resendDelay = 30;
  int _remaining = _resendDelay;
  Timer? _timer;
  int _otpAttempt = 0; // change la clé de l'OtpInput pour le réinitialiser

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = _resendDelay);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        _timer?.cancel();
      } else if (mounted) {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resend() {
    context.read<LinkPhoneCubit>().resend(widget.phone);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocConsumer<LinkPhoneCubit, LinkPhoneState>(
          listenWhen: (p, c) =>
              p.verifyStatus != c.verifyStatus ||
              p.requestStatus != c.requestStatus,
          listener: (context, state) {
            if (state.verifyStatus == LinkStatus.success) {
              context.read<ClientSessionCubit>().refresh();
              // Enregistre le device FCM pour ce numéro fraîchement lié
              // (no-op tant que Firebase n'est pas configuré).
              serviceLocator<PushNotificationService>()
                  .registerDeviceIfLinked();

              context.go(AppRoutes.home);

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('Numéro lié avec succès')),
                );
            } else if (state.verifyStatus == LinkStatus.failure &&
                state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    backgroundColor: AppColors.danger,
                  ),
                );
              setState(() => _otpAttempt++); // réinitialise les cases
            } else if (state.requestStatus == LinkStatus.success) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('Nouveau code envoyé')),
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
                    'Entrez le code',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Un code à 4 chiffres a été envoyé au +221 ${widget.phone}.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  OtpInput(
                    key: ValueKey(_otpAttempt),
                    hasError: state.verifyStatus == LinkStatus.failure,
                    onCompleted: (code) => context
                        .read<LinkPhoneCubit>()
                        .verifyOtp(phone: widget.phone, code: code),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.isVerifying)
                    const Center(child: CircularProgressIndicator())
                  else
                    Center(
                      child: _remaining > 0
                          ? Text(
                              'Renvoyer le code dans $_remaining s',
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                              ),
                            )
                          : TextButton(
                              onPressed: _resend,
                              child: const Text('Renvoyer le code'),
                            ),
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
