import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/domain/repositories/machine_repository.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import '../../domain/entities/laundry_type.dart';
import '../../domain/entities/prestation.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'new_dropoff_state.dart';

/// Assistant nouveau dépôt (4 étapes) — pilote un stepper interne.
///
/// Étapes : client → linge → prestation → attente paiement.
/// La soumission crée le draft (`POST /drop-offs/draft`) puis déclenche le
/// paiement (`POST /payments/initiate` purpose DROP_OFF, push vers le client).
class NewDropOffCubit extends Cubit<NewDropOffState> {
  NewDropOffCubit(
    this._dropOffRepository,
    this._paymentRepository,
    this._machineRepository,
  ) : super(const NewDropOffState()) {
    _loadPrestations();
  }

  final DropOffRepository _dropOffRepository;
  final PaymentRepository _paymentRepository;
  final MachineRepository _machineRepository;

  // ── Catalogue de prestations (dérivé des machines) ──────────────────────────

  Future<void> _loadPrestations() async {
    emit(state.copyWith(prestationsStatus: LoadStatus.loading));

    final result = await _machineRepository.getMachines();
    
    result.fold(
      (failure) => emit(state.copyWith(prestationsStatus: LoadStatus.failure)),
      (machines) {
        print("Machines Prestation => $machines");
        final sorted = machines.where((m) => m.size != null && m.type == MachineType.washer).toList()
          ..sort((a, b) => a.size!.compareTo(b.size!));
        final seen = <int>{};
        final prestations = <Prestation>[];
        for (final m in sorted) {
          final amount = m.price.toInt();
          if (seen.add(amount)) {
            prestations.add(Prestation(amount: amount, sizeKg: m.size));
          }
        }
        emit(
          state.copyWith(
            prestations: prestations,
            prestationsStatus: LoadStatus.success,
          ),
        );
      },
    );
  }

  void retryPrestations() => _loadPrestations();

  // ── Saisies ─────────────────────────────────────────────────────────────────

  void setPhone(String value) =>
      emit(state.copyWith(contactPhone: value.trim()));

  void setName(String value) =>
      emit(state.copyWith(customerName: value.trim()));

  void incrementPieces() => emit(state.copyWith(pieces: state.pieces + 1));

  void decrementPieces() {
    if (state.pieces > 1) emit(state.copyWith(pieces: state.pieces - 1));
  }

  void toggleType(LaundryType type) {
    final next = Set<LaundryType>.from(state.types);
    next.contains(type) ? next.remove(type) : next.add(type);
    emit(state.copyWith(types: next));
  }

  void setInstructions(String value) =>
      emit(state.copyWith(instructions: value));

  void selectPrestation(int amount) => emit(state.copyWith(amount: amount));

  void selectProvider(PaymentProvider provider) =>
      emit(state.copyWith(provider: provider));

  // ── Navigation entre étapes ─────────────────────────────────────────────────

  void next() {
    if (state.step == 0 && state.canLeaveClient) {
      emit(state.copyWith(step: 1));
    } else if (state.step == 1 && state.canLeaveLaundry) {
      emit(state.copyWith(step: 2));
    }
  }

  void back() {
    if (state.step > 0) emit(state.copyWith(step: state.step - 1));
  }

  // ── Soumission : draft + paiement ───────────────────────────────────────────

  Future<void> submit() async {
    if (!state.canSubmit || state.submitStatus == SubmitStatus.loading) return;

    emit(state.copyWith(submitStatus: SubmitStatus.loading, clearError: true));

    final draft = await _dropOffRepository.createDraft(
      contactPhone: state.contactPhone,
      customerName: state.customerName,
      amount: state.amount!,
      pieces: state.pieces,
      types: state.types.toList(),
      instructions: state.instructions,
    );

    await draft.fold(
      (failure) async => emit(
        state.copyWith(
          submitStatus: SubmitStatus.failure,
          error: failure.message,
        ),
      ),
      (_) async {
        final payment = await _initiate();
        payment.fold(
          (failure) => emit(
            state.copyWith(
              submitStatus: SubmitStatus.failure,
              error: failure.message,
            ),
          ),
          (_) =>
              emit(state.copyWith(submitStatus: SubmitStatus.success, step: 3)),
        );
      },
    );
  }

  /// Renvoie la demande de paiement au client (étape d'attente).
  Future<bool> resend() async {
    final result = await _initiate();
    return result.isRight();
  }

  Future<Either<Failure, void>> _initiate() =>
      _paymentRepository.initiateDropOffPayment(
        amount: state.amount!,
        provider: state.provider!,
        customerFullName: state.customerName,
        customerPhone: state.contactPhone,
      );
}
