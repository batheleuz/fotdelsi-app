import 'package:equatable/equatable.dart';

import 'package:fotdelsi/features/machines/domain/entities/machine.dart';

enum ScanStatus { scanning, processing, success, error }

final class ScanState extends Equatable {
  const ScanState({
    this.status = ScanStatus.scanning,
    this.machine,
    this.error,
  });

  final ScanStatus status;
  final Machine? machine;
  final String? error;

  ScanState copyWith({ScanStatus? status, Machine? machine, String? error}) {
    return ScanState(
      status: status ?? this.status,
      machine: machine ?? this.machine,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, machine, error];
}
