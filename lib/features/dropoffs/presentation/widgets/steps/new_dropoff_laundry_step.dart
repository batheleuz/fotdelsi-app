import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../cubit/new_dropoff_cubit.dart';

/// Étape 2 — description du linge.
class NewDropOffLaundryStep extends StatefulWidget {
  const NewDropOffLaundryStep({super.key});

  @override
  State<NewDropOffLaundryStep> createState() => _NewDropOffLaundryStepState();
}

class _NewDropOffLaundryStepState extends State<NewDropOffLaundryStep> {
  late final TextEditingController _instructions;

  @override
  void initState() {
    super.initState();
    _instructions = TextEditingController(
      text: context.read<NewDropOffCubit>().state.instructions,
    );
  }

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewDropOffCubit>();
    final state = context.watch<NewDropOffCubit>().state;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const _Title('Combien de pièces ?'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundBtn(icon: Icons.remove, onTap: cubit.decrementPieces),
            SizedBox(
              width: 90,
              child: Text(
                '${state.pieces}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _RoundBtn(icon: Icons.add, onTap: cubit.incrementPieces),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _Title('Instructions (optionnel)'),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _instructions,
          maxLines: 3,
          maxLength: 500,
          onChanged: cubit.setInstructions,
          decoration: InputDecoration(
            hintText: 'Ex. séparer les blancs, lavage à froid…',
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
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 30,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Icon(icon, color: AppColors.primaryLight, size: 24),
      ),
    );
  }
}


