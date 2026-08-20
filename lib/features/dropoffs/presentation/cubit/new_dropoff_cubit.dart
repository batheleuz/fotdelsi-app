import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/catalog/domain/repositories/service_formula_repository.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_delivery.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_session.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import '../../domain/entities/laundry_type.dart';
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
    this._formulaRepository,
  ) : super(const NewDropOffState()) {
    _loadFormulas();
  }

  final DropOffRepository _dropOffRepository;
  final PaymentRepository _paymentRepository;
  final ServiceFormulaRepository _formulaRepository;

  // ── Catalogue de services ───────────────────────────────────────────────────

  /// Charge la grille tarifaire officielle. Le comptoir propose toutes les
  /// formules, y compris celles réalisées à la main (pliage, repassage).
  Future<void> _loadFormulas() async {
    emit(state.copyWith(formulasStatus: LoadStatus.loading));

    final result = await _formulaRepository.getFormulas();

    result.fold(
      (failure) {
        final errorState = state.copyWith(formulasStatus: LoadStatus.failure);
        emit(errorState);
      },
      (formulas) {
        final newState = state.copyWith(
          formulas: formulas,
          formulasStatus: LoadStatus.success,
        );
        emit(newState);
      },
    );
  }

  void retryFormulas() => _loadFormulas();

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

  /// Choisit une formule. La capacité est réinitialisée si elle n'est pas
  /// tarifée pour cette formule — mieux vaut redemander que d'afficher un
  /// total incohérent.
  void selectFormula(ServiceFormula formula) {
    final keepSize =
        state.sizeKg != null && formula.priceFor(state.sizeKg!) != null;
    emit(
      state.copyWith(
        formulaCode: formula.code,
        sizeKg: keepSize ? state.sizeKg : null,
        clearSize: !keepSize,
      ),
    );
  }

  void selectSize(int sizeKg) => emit(state.copyWith(sizeKg: sizeKg));

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

    // Aucun montant transmis : le serveur retarifie depuis la grille à partir
    // du couple (formule, capacité).
    final draft = await _dropOffRepository.createDraft(
      contactPhone: state.contactPhone,
      customerName: state.customerName,
      formulaCode: state.formulaCode!,
      sizeKg: state.sizeKg!,
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
      (draftId) async {
        emit(state.copyWith(draftId: draftId));
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

  /// Comment la demande atteindra le payeur. Choisi avant de la lancer.
  void chooseDelivery(PaymentDelivery delivery) {
    emit(state.copyWith(delivery: delivery));
  }

  /// Renvoie la demande de paiement au client (étape d'attente).
  Future<bool> resend() async {
    final result = await _initiate();
    return result.isRight();
  }

  Future<Either<Failure, PaymentSession>> _initiate() async {
    final result = await _paymentRepository.initiateDropOffPayment(
      draftId: state.draftId!,
      provider: state.provider!,
      customerFullName: state.customerName,
      customerPhone: state.contactPhone,
      delivery: state.delivery,
    );

    // La session porte le lien de paiement : sans elle, « le client est là »
    // n'aurait aucun code à montrer.
    result.fold(
      (_) => null,
      (session) => emit(state.copyWith(session: session)),
    );
    return result;
  }
}
