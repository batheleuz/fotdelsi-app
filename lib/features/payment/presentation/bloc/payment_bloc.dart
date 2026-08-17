import 'package:bloc/bloc.dart';

import 'package:fotdelsi/features/payment/domain/entities/customer_profile.dart';
import 'package:fotdelsi/features/payment/domain/repositories/customer_profile_repository.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import 'package:fotdelsi/features/wash_session/domain/entities/pending_wash_session.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_session_cubit.dart';
import 'payment_event.dart';
import 'payment_state.dart';

/// Bloc de l'écran de paiement.
///
/// Préremplit le nom et le numéro depuis le profil mémorisé, collecte le
/// provider, puis appelle [PaymentRepository.initiatePayment] sur soumission.
/// En cas de succès, mémorise les coordonnées pour les prochains paiements.
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc(
    this._paymentRepository,
    CustomerProfileRepository profileRepository,
    this._sessionCubit,
  ) : _profileRepository = profileRepository,
      super(_initialState(profileRepository.load())) {
    on<PaymentNameChanged>(_onNameChanged);
    on<PaymentProviderSelected>(_onProviderSelected);
    on<PaymentPhoneChanged>(_onPhoneChanged);
    on<PaymentSubmitted>(_onSubmitted);
  }

  final PaymentRepository _paymentRepository;
  final CustomerProfileRepository _profileRepository;
  final WashSessionCubit _sessionCubit;

  /// État initial prérempli avec le profil mémorisé.
  static PaymentState _initialState(CustomerProfile profile) =>
      PaymentState(customerFullName: profile.fullName, phone: profile.phone);

  void _onNameChanged(PaymentNameChanged event, Emitter<PaymentState> emit) {
    emit(state.copyWith(customerFullName: event.name));
  }

  void _onProviderSelected(
    PaymentProviderSelected event,
    Emitter<PaymentState> emit,
  ) {
    emit(state.copyWith(provider: event.provider));
  }

  void _onPhoneChanged(PaymentPhoneChanged event, Emitter<PaymentState> emit) {
    emit(state.copyWith(phone: event.phone));
  }

  Future<void> _onSubmitted(
    PaymentSubmitted event,
    Emitter<PaymentState> emit,
  ) async {
    if (!state.canPay) return;

    emit(state.copyWith(status: PaymentStatus.processing));

    final result = await _paymentRepository.initiatePayment(
      machineId: event.machineId,
      formulaCode: event.formulaCode,
      provider: state.provider!,
      customerFullName: state.customerFullName.trim(),
      customerPhone: state.phone,
    );

    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: PaymentStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (session) async {
        // Mémorise les coordonnées pour les prochains paiements.
        await _profileRepository.save(
          CustomerProfile(
            fullName: state.customerFullName.trim(),
            phone: state.phone,
          ),
        );
        // Persiste la session et met à jour le cubit global.
        await _sessionCubit.onPaymentInitiated(
          PendingWashSession.fromPaymentSession(session),
        );
        emit(state.copyWith(status: PaymentStatus.success, session: session));
      },
    );
  }
}
