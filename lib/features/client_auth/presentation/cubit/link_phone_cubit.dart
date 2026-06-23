import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/repositories/client_auth_repository.dart';

part 'link_phone_state.dart';

/// Flux de liaison du numéro : demande d'OTP puis vérification.
///
/// Une instance par parcours (factory). Le numéro est transmis explicitement
/// d'un écran à l'autre.
class LinkPhoneCubit extends Cubit<LinkPhoneState> {
  LinkPhoneCubit(this._repository) : super(const LinkPhoneState());

  final ClientAuthRepository _repository;

  Future<void> requestOtp(String phone) async {
    emit(state.copyWith(requestStatus: LinkStatus.loading, clearError: true));
    final result = await _repository.requestOtp(phone);
    result.fold(
      (f) => emit(state.copyWith(
        requestStatus: LinkStatus.failure,
        error: f.message,
      )),
      (_) => emit(state.copyWith(requestStatus: LinkStatus.success)),
    );
  }

  /// Renvoi du code (même appel que la demande initiale).
  Future<void> resend(String phone) => requestOtp(phone);

  Future<void> verifyOtp({required String phone, required String code}) async {
    emit(state.copyWith(verifyStatus: LinkStatus.loading, clearError: true));
    final result = await _repository.verifyOtp(phone: phone, code: code);
    result.fold(
      (f) => emit(state.copyWith(
        verifyStatus: LinkStatus.failure,
        error: f.message,
      )),
      (linkedPhone) => emit(state.copyWith(
        verifyStatus: LinkStatus.success,
        linkedPhone: linkedPhone,
      )),
    );
  }
}
