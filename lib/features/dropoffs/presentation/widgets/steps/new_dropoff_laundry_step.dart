import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../../domain/entities/laundry_type.dart';
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
        const _Title('Type de linge'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LaundryType.values.map((type) {
            final selected = state.types.contains(type);
            return _Chip(
              label: type.label,
              selected: selected,
              onTap: () => cubit.toggleType(type),
            );
          }).toList(),
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceTint : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16, color: AppColors.primaryDark),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
