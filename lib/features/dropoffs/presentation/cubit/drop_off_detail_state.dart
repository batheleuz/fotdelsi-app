part of 'drop_off_detail_cubit.dart';

enum DetailStatus { initial, loading, success, failure }

enum ActionStatus { idle, loading, success, failure }

final class DropOffDetailState extends Equatable {
  const DropOffDetailState({
    this.status = DetailStatus.initial,
    this.dropOff,
    this.error,
    this.actionStatus = ActionStatus.idle,
    this.actionError,
  });

  final DetailStatus status;
  final DropOff? dropOff;
  final String? error;

  final ActionStatus actionStatus;
  final String? actionError;

  bool get isActing => actionStatus == ActionStatus.loading;

  DropOffDetailState copyWith({
    DetailStatus? status,
    DropOff? dropOff,
    String? error,
    ActionStatus? actionStatus,
    String? actionError,
    bool clearActionError = false,
  }) {
    return DropOffDetailState(
      status: status ?? this.status,
      dropOff: dropOff ?? this.dropOff,
      error: error ?? this.error,
      actionStatus: actionStatus ?? this.actionStatus,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props =>
      [status, dropOff, error, actionStatus, actionError];
}
