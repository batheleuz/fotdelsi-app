part of 'service_status_cubit.dart';

final class ServiceStatusState extends Equatable {
  const ServiceStatusState({this.warnings = const []});

  final List<ServiceWarning> warnings;

  bool get hasWarnings => warnings.isNotEmpty;

  ServiceStatusState copyWith({List<ServiceWarning>? warnings}) {
    return ServiceStatusState(warnings: warnings ?? this.warnings);
  }

  @override
  List<Object?> get props => [warnings];
}
