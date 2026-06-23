part of 'link_phone_cubit.dart';

enum LinkStatus { idle, loading, success, failure }

final class LinkPhoneState extends Equatable {
  const LinkPhoneState({
    this.requestStatus = LinkStatus.idle,
    this.verifyStatus = LinkStatus.idle,
    this.linkedPhone,
    this.error,
  });

  final LinkStatus requestStatus;
  final LinkStatus verifyStatus;
  final String? linkedPhone;
  final String? error;

  bool get isRequesting => requestStatus == LinkStatus.loading;
  bool get isVerifying => verifyStatus == LinkStatus.loading;

  LinkPhoneState copyWith({
    LinkStatus? requestStatus,
    LinkStatus? verifyStatus,
    String? linkedPhone,
    String? error,
    bool clearError = false,
  }) {
    return LinkPhoneState(
      requestStatus: requestStatus ?? this.requestStatus,
      verifyStatus: verifyStatus ?? this.verifyStatus,
      linkedPhone: linkedPhone ?? this.linkedPhone,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [requestStatus, verifyStatus, linkedPhone, error];
}
