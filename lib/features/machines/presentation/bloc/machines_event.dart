import 'package:equatable/equatable.dart';

/// Événements émis par l'UI vers le bloc.
sealed class MachinesEvent extends Equatable {
  const MachinesEvent();

  @override
  List<Object?> get props => [];
}

/// L'UI demande à s'abonner au flux temps réel des machines.
final class MachinesSubscriptionRequested extends MachinesEvent {
  const MachinesSubscriptionRequested();
}
