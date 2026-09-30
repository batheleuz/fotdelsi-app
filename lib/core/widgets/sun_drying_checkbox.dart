import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';

/// Signale un linge qui ne doit jamais entrer dans une sécheuse.
class SunDryingCheckbox extends StatelessWidget {
  const SunDryingCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const warning = Color(0xFF9A4D00);

    return Semantics(
      checked: value,
      button: true,
      label: 'Vêtements à sécher au soleil uniquement',
      child: Material(
        color: value ? const Color(0xFFFFF4E5) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: value ? const Color(0xFFFFB45E) : AppColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: value,
                  activeColor: warning,
                  onChanged: (checked) => onChanged(checked ?? false),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Séchage au soleil uniquement',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Vêtements wolof, costumes ou couettes. Ne jamais les mettre en sécheuse.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
