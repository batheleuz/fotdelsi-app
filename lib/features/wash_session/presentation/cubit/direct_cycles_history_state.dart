import 'package:equatable/equatable.dart';
import '../../domain/entities/wash_cycle.dart';

enum DirectCyclesHistoryStatus { initial, loading, success, failure }

final class DirectCyclesHistoryState extends Equatable {
  const DirectCyclesHistoryState({
    this.status = DirectCyclesHistoryStatus.initial,
    this.cycles,
    this.searchQuery = '',
    this.error,
  });

  final DirectCyclesHistoryStatus status;
  final List<WashCycle>? cycles;
  final String searchQuery;
  final String? error;

  List<WashCycle> get filteredCycles {
    final list = cycles ?? const [];
    if (searchQuery.trim().isEmpty) return list;

    final q = searchQuery.trim().toLowerCase();
    return list.where((c) {
      final name = (c.customerName ?? '').toLowerCase();
      final phone = (c.customerPhone ?? '').toLowerCase();
      final machine = (c.machineName ?? '').toLowerCase();
      final formula = (c.formulaLabel ?? '').toLowerCase();
      return name.contains(q) ||
          phone.contains(q) ||
          machine.contains(q) ||
          formula.contains(q);
    }).toList();
  }

  bool get isEmpty => (cycles ?? const []).isEmpty;

  DirectCyclesHistoryState copyWith({
    DirectCyclesHistoryStatus? status,
    List<WashCycle>? cycles,
    String? searchQuery,
    String? error,
    bool clearError = false,
  }) {
    return DirectCyclesHistoryState(
      status: status ?? this.status,
      cycles: cycles ?? this.cycles,
      searchQuery: searchQuery ?? this.searchQuery,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, cycles, searchQuery, error];
}
