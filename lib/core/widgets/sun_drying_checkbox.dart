import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';

/// Signale un linge qui ne doit jamais entrer dans une sécheuse.
class SunDryingCheckbox extends StatelessWidget {
  const SunDryingCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.disabledMessage,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final String? disabledMessage;

  @override
  Widget build(BuildContext context) {
    const warning = Color(0xFF9A4D00);

    return Semantics(
      checked: value,
      button: enabled,
      enabled: enabled,
      label: 'Vêtements à sécher au soleil uniquement',
      child: Material(
        color: value ? const Color(0xFFFFF0DC) : const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: enabled ? () => onChanged(!value) : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: value
                    ? const Color(0xFFFF9A2E)
                    : const Color(0xFFFFD7A8),
                width: value ? 2 : 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: value,
                  activeColor: warning,
                  onChanged: enabled
                      ? (checked) => onChanged(checked ?? false)
                      : null,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LINGE SENSIBLE — séchage au soleil',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Vêtements wolof, costumes ou couettes. Ne jamais les mettre en sécheuse.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: warning,
                        ),
                      ),
                      if (!enabled && disabledMessage != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          disabledMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
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
