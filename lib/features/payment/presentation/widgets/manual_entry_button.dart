import 'package:flutter/material.dart';

import 'package:fotdelsi/core/constants/app_icons.dart';

/// Action secondaire du scanner : saisie manuelle du code machine.
class ManualEntryButton extends StatelessWidget {
  const ManualEntryButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.keyboard, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Entrer le code manuellement',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
