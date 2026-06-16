import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/constants/app_icons.dart';
import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import '../../domain/entities/payment_provider.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_session_cubit.dart';
import '../utils/payment_launcher.dart';
import '../utils/payment_provider_presentation.dart';
import '../widgets/order_recap_card.dart';
import '../widgets/payment_provider_card.dart';
import '../widgets/payment_redirect_hint.dart';
import '../widgets/phone_number_field.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key, required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<PaymentBloc>(),
      child: _PaymentView(machine: machine),
    );
  }
}

class _PaymentView extends StatelessWidget {
  const _PaymentView({required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PaymentBloc>();

    return Scaffold(
      body: SafeArea(
        child: BlocListener<PaymentBloc, PaymentState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) async {
            if (state.status == PaymentStatus.success &&
                state.session != null) {
              // Lance l'app de paiement (Wave / Orange Money / QR).
              final session = context
                  .read<WashSessionCubit>()
                  .state
                  .pendingSession;
              if (session != null && context.mounted) {
                await PaymentLauncher.launch(context, session);
              }
              // Retour à l'accueil — la bannière prendra le relais.
              if (context.mounted) context.go(AppRoutes.home);
            } else if (state.status == PaymentStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ?? 'Paiement impossible. Réessayez.',
                  ),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          },
          child: Column(
            children: [
              _TopBar(
                title: 'Paiement',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: BlocBuilder<PaymentBloc, PaymentState>(
                  builder: (context, state) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OrderRecapCard(machine: machine),
                          const SizedBox(height: AppSpacing.lg),

                          const _SectionLabel('Votre nom complet'),
                          const SizedBox(height: AppSpacing.sm + 2),
                          
                          _NameField(
                            initialValue: state.customerFullName,
                            onChanged: (v) =>
                                bloc.add(PaymentNameChanged(v)),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _SectionLabel('Moyen de paiement'),
                          
                          const SizedBox(height: AppSpacing.sm + 2),
                          for (final provider in PaymentProvider.values) ...[
                            PaymentProviderCard(
                              provider: provider,
                              selected: state.provider == provider,
                              onTap: () =>
                                  bloc.add(PaymentProviderSelected(provider)),
                            ),
                            const SizedBox(height: AppSpacing.sm + 2),
                          ],
                          const SizedBox(height: AppSpacing.xs),
                          
                          const _SectionLabel('Numéro mobile money'),
                          const SizedBox(height: AppSpacing.sm + 2),
                          
                          PhoneNumberField(
                            initialValue: state.phone,
                            onChanged: (v) => bloc.add(PaymentPhoneChanged(v)),
                          ),
                          if (state.provider != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            PaymentRedirectHint(
                              providerLabel: state.provider!.label,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              BlocBuilder<PaymentBloc, PaymentState>(
                builder: (context, state) => _PayBar(
                  total: machine.price.toInt(),
                  state: state,
                  onPay: () => bloc.add(
                    PaymentSubmitted(machineId: machine.id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Champ nom ─────────────────────────────────────────────────────────────────

class _NameField extends StatefulWidget {
  const _NameField({required this.onChanged, this.initialValue = ''});

  final ValueChanged<String> onChanged;
  final String initialValue;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        hintText: 'Prénom et nom',
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Barre de paiement ─────────────────────────────────────────────────────────

class _PayBar extends StatelessWidget {
  const _PayBar({
    required this.total,
    required this.state,
    required this.onPay,
  });

  final int total;
  final PaymentState state;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final label = state.provider == null
        ? 'Payer'
        : 'Payer via ${state.provider!.label}';
    
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border:
            Border(top: BorderSide(color: Color(0xFFEEF1F6), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total à payer',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
              Text(
                formatFcfa(total),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          PrimaryButton(
            label: label,
            icon: AppIcons.lock,
            enabled: state.canPay,
            loading: state.isProcessing,
            onPressed: onPay,
          ),
        ],
      ),
    );
  }
}

// ── Utilitaires ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(
                AppIcons.back,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
