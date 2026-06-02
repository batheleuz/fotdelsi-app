import 'package:flutter/material.dart';

import '../../domain/entities/machine.dart';
import '../utils/machine_status_presentation.dart';

/// Bandeau récapitulatif : nombre de machines par état.
class MachinesSummary extends StatelessWidget {
  const MachinesSummary({super.key, required this.machines});

  final List<Machine> machines;

  int _count(MachineStatus s) =>
      machines.where((m) => m.status == s).length;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final status in MachineStatus.values)
          if (_count(status) > 0)
            _SummaryChip(count: _count(status), status: status),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.count, required this.status});

  final int count;
  final MachineStatus status;

  String get _label => switch (status) {
        MachineStatus.available => '$count disponible${count > 1 ? 's' : ''}',
        MachineStatus.inUse => '$count en cours',
        MachineStatus.offline => '$count hors ligne',
      };

  @override
  Widget build(BuildContext context) {
    final dark = status == MachineStatus.available
        ? const Color(0xFF0F6E56)
        : status == MachineStatus.inUse
            ? const Color(0xFF993C1D)
            : const Color(0xFF5A6B85);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: dark),
      ),
    );
  }
}
