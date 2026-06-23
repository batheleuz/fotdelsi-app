import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/new_dropoff_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/steps/new_dropoff_client_step.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/steps/new_dropoff_laundry_step.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/steps/new_dropoff_service_step.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/steps/new_dropoff_awaiting_step.dart';

/// Assistant nouveau dépôt — un stepper interne en 4 étapes.
class NewDropOffPage extends StatelessWidget {
  const NewDropOffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<NewDropOffCubit>(),
      child: const _NewDropOffView(),
    );
  }
}

class _NewDropOffView extends StatelessWidget {
  const _NewDropOffView();

  static const _subtitles = [
    'Étape 1 / 4 · Le client',
    'Étape 2 / 4 · Le linge',
    'Étape 3 / 4 · Prestation',
    'Demande envoyée',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<NewDropOffCubit, NewDropOffState>(
      listenWhen: (p, c) => p.submitStatus != c.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == SubmitStatus.failure && state.error != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.danger,
            ));
        }
      },
      child: BlocBuilder<NewDropOffCubit, NewDropOffState>(
        builder: (context, state) {
          final cubit = context.read<NewDropOffCubit>();

          return Scaffold(
            backgroundColor: const Color(0xFFF5F8FC),
            appBar: AppBar(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (state.step > 0 && state.step < 3) {
                    cubit.back();
                  } else {
                    context.pop();
                  }
                },
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nouveau dépôt',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  Text(
                    _subtitles[state.step],
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            body: SafeArea(
              top: false,
              child: IndexedStack(
                index: state.step,
                children: const [
                  NewDropOffClientStep(),
                  NewDropOffLaundryStep(),
                  NewDropOffServiceStep(),
                  NewDropOffAwaitingStep(),
                ],
              ),
            ),
            bottomNavigationBar:
                state.step >= 3 ? null : _BottomBar(state: state),
          );
        },
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state});

  final NewDropOffState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewDropOffCubit>();
    final isService = state.step == 2;

    final enabled = switch (state.step) {
      0 => state.canLeaveClient,
      1 => state.canLeaveLaundry,
      _ => state.canSubmit,
    };

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: PrimaryButton(
        label: isService ? 'Demander le paiement' : 'Suivant',
        icon: isService ? Icons.send_rounded : Icons.arrow_forward_rounded,
        enabled: enabled && !state.isSubmitting,
        loading: state.isSubmitting,
        backgroundColor: AppColors.primaryLight,
        onPressed: () => isService ? cubit.submit() : cubit.next(),
      ),
    );
  }
}
