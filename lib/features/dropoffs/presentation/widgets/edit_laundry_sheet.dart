import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import '../../domain/entities/laundry.dart';

/// Feuille d'édition de la description du linge d'un dépôt.
class EditLaundrySheet extends StatefulWidget {
  const EditLaundrySheet({
    super.key,
    required this.initial,
    required this.onSave,
  });

  final Laundry initial;
  final void Function(int pieces, String? instructions) onSave;

  @override
  State<EditLaundrySheet> createState() => _EditLaundrySheetState();
}

class _EditLaundrySheetState extends State<EditLaundrySheet> {
  late int _pieces = widget.initial.pieces;
  late final TextEditingController _instructions = TextEditingController(
    text: widget.initial.instructions,
  );

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  bool get _valid => _pieces >= 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: AppSpacing.md),
          Text(
            'Modifier le linge',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Text(
                'Pièces',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              _round(
                Icons.remove,
                () => setState(() => _pieces = _pieces > 1 ? _pieces - 1 : 1),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$_pieces',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _round(Icons.add, () => setState(() => _pieces++)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _instructions,
            maxLines: 2,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Instructions (optionnel)',
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
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: 'Enregistrer',
            enabled: _valid,
            backgroundColor: AppColors.primaryLight,
            onPressed: () {
              widget.onSave(
                _pieces,
                _instructions.text.trim(),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _round(IconData icon, VoidCallback onTap) => InkResponse(
    onTap: onTap,
    radius: 26,
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Icon(icon, color: AppColors.primaryLight, size: 20),
    ),
  );
}
