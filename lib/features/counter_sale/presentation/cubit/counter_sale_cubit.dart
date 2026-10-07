import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:fotdelsi/features/catalog/domain/entities/drying_duration_tier.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/catalog/domain/repositories/service_formula_repository.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/domain/repositories/machine_repository.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_session.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import 'package:fotdelsi/features/wash_session/domain/entities/session_payment_status.dart';
import 'package:fotdelsi/features/wash_session/domain/repositories/wash_session_repository.dart';

part 'counter_sale_state.dart';

/// Vente d'un cycle au comptoir, pour un client qui n'a pas l'application.
///
/// L'agent choisit la prestation et la machine, saisit les coordonnées du
/// client, puis lui présente un QR. Le client scanne avec l'appareil photo de
/// son téléphone et paie dans Wave ou Orange Money — il n'installe rien.
///
/// Deux différences avec le parcours client :
///   - le jeton de session reste chez l'AGENT, c'est donc lui qui lancera la
///     machine une fois le linge chargé ;
///   - la confirmation du paiement est suivie ici par interrogation régulière,
///     puisque l'agent doit savoir quand il peut démarrer.
class CounterSaleCubit extends Cubit<CounterSaleState> {
  CounterSaleCubit(
    this._formulas,
    this._machines,
    this._payments,
    this._sessions,
  ) : super(
        CounterSaleState(dryingTier: DryingDurationTier.configuredDefault),
      ) {
    _load();
  }

  final ServiceFormulaRepository _formulas;
  final MachineRepository _machines;
  final PaymentRepository _payments;
  final WashSessionRepository _sessions;

  Timer? _poll;

  /// Cadence d'interrogation du statut. Assez court pour que l'agent n'attende
  /// pas devant le client, assez espacé pour rester dans la limite du backend
  /// (60 req/min sur cet endpoint).
  static const _pollInterval = Duration(seconds: 3);

  // ── Chargement ──────────────────────────────────────────────────────────────

  Future<void> _load() async {
    emit(state.copyWith(loadStatus: SaleLoadStatus.loading));

    // Seules les prestations vendables en libre-service : les autres sont déjà
    // couvertes par le dépôt classique.
    final results = await Future.wait([
      _formulas.getFormulas(selfServiceOnly: true),
      _machines.getMachines(),
    ]);

    final catalog = results[0] as dynamic;
    final machines = results[1] as dynamic;

    if (catalog.isLeft() || machines.isLeft()) {
      emit(state.copyWith(loadStatus: SaleLoadStatus.failure));
      return;
    }

    emit(
      state.copyWith(
        loadStatus: SaleLoadStatus.success,
        formulas: catalog.fold(
          (_) => <ServiceFormula>[],
          (c) => c.formulas as List<ServiceFormula>,
        ),
        machines: machines.getOrElse(() => <Machine>[]),
        dryingTier: DryingDurationTier.configuredDefault,
      ),
    );
  }

  void retryLoad() => _load();

  // ── Saisies ─────────────────────────────────────────────────────────────────

  void selectFormula(ServiceFormula formula) {
    if (state.requiresSunDrying &&
        (!formula.isReadyToWear || !formula.needsWasher)) {
      return;
    }
    // La machine n'est conservée que si elle convient à la formule (type et
    // tarifée) : on la réinitialise plutôt que d'afficher un total faux.
    final keep = state.machine != null && _fits(formula, state.machine!);
    final keepSize =
        !formula.needsMachine && formula.lotSizes.contains(state.sizeKg);
    final updatedFormulas = state.formulas.any((f) => f.code == formula.code)
        ? state.formulas
        : [...state.formulas, formula];
    emit(
      state.copyWith(
        formulas: updatedFormulas,
        formulaCode: formula.code,
        machine: keep ? state.machine : null,
        clearMachine: !keep,
        clearSize: !keepSize,
        requiresSunDrying: state.requiresSunDrying,
      ),
    );
  }

  void selectMachine(Machine machine) {
    final formula = state.selectedFormula;
    if (formula == null || !_fits(formula, machine)) return;
    emit(state.copyWith(machine: machine, clearSize: true));
  }

  void selectSize(int sizeKg) {
    final formula = state.selectedFormula;
    if (formula == null ||
        formula.needsMachine ||
        !formula.lotSizes.contains(sizeKg)) {
      return;
    }
    emit(state.copyWith(sizeKg: sizeKg, clearMachine: true));
  }

  void setCustomerName(String value) =>
      emit(state.copyWith(customerName: value.trim()));

  void setCustomerPhone(String value) =>
      emit(state.copyWith(customerPhone: value.trim()));

  void selectProvider(PaymentProvider provider) =>
      emit(state.copyWith(provider: provider));

  bool _fits(ServiceFormula formula, Machine machine) {
    if (!formula.needsMachine) return false;
    final wanted = formula.needsWasher ? MachineType.washer : MachineType.dryer;
    return machine.type == wanted &&
        machine.size != null &&
        formula.priceFor(machine.size!) != null;
  }

  /// Machines proposables pour la prestation choisie : bon type, capacité
  /// tarifée. La disponibilité est affichée mais ne filtre pas — l'agent doit
  /// voir tout le parc pour renseigner le client.
  List<Machine> get eligibleMachines {
    final formula = state.selectedFormula;
    if (formula == null) return const [];
    return state.machines.where((m) => _fits(formula, m)).toList()
      ..sort((a, b) => a.size!.compareTo(b.size!));
  }

  void selectDryingTier(DryingDurationTier tier) {
    emit(state.copyWith(dryingTier: tier));
  }

  void selectQuantity(int quantity) => emit(state.copyWith(quantity: quantity));

  void setRequiresSunDrying(bool value) {
    if (!value) {
      emit(state.copyWith(requiresSunDrying: false));
      return;
    }

    ServiceFormula? readyToWear;
    for (final formula in state.formulas) {
      if (formula.isReadyToWear && formula.needsWasher) {
        readyToWear = formula;
        break;
      }
    }

    if (readyToWear == null) {
      emit(
        state.copyWith(
          requiresSunDrying: true,
          dryingTier: DryingDurationTier.configuredDefault,
          clearFormula: true,
          clearMachine: true,
          clearSize: true,
        ),
      );
      return;
    }

    final keepMachine =
        state.machine != null && _fits(readyToWear, state.machine!);
    emit(
      state.copyWith(
        requiresSunDrying: true,
        dryingTier: DryingDurationTier.configuredDefault,
        formulaCode: readyToWear.code,
        machine: keepMachine ? state.machine : null,
        clearMachine: !keepMachine,
        clearSize: true,
      ),
    );
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void next() {
    if (!state.canGoNext) return;
    // Quitter l'étape « client » déclenche la vente : l'étape suivante est
    // celle du QR, qui n'a de sens qu'une fois le paiement initié.
    if (state.step == 1) {
      submit();
      return;
    }
    emit(state.copyWith(step: state.step + 1));
  }

  void back() {
    if (state.canGoBack) emit(state.copyWith(step: state.step - 1));
  }

  // ── Vente ───────────────────────────────────────────────────────────────────

  /// Initie le paiement et récupère le lien à présenter en QR.
  ///
  /// Aucun montant n'est transmis : le serveur le recalcule depuis la grille.
  Future<void> submit() async {
    if (!state.canSubmit || state.isSubmitting) return;

    final total = state.total;
    if (total == null || total <= 0) {
      emit(
        state.copyWith(
          saleStatus: SaleStatus.failure,
          error:
              'Le montant calculé doit être strictement supérieur à 0 F CFA.',
        ),
      );
      return;
    }

    emit(state.copyWith(saleStatus: SaleStatus.submitting, clearError: true));

    final result = await _payments.initiatePayment(
      machineId: state.needsMachine ? state.machine!.id : null,
      sizeKg: state.needsMachine ? null : state.sizeKg,
      formulaCode: state.formulaCode!,
      provider: state.provider!,
      customerFullName: state.customerName,
      customerPhone: state.customerPhone,
      // Impose au serveur d'exiger un jeton d'agent valide. Sans ça, un jeton
      // expiré passait sans bruit et la vente perdait son vendeur.
      atCounter: true,
      dryingDurationMinutes: state.hasDrying ? state.dryingTier.minutes : null,
      quantity: state.quantity,
      requiresSunDrying: state.requiresSunDrying,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(saleStatus: SaleStatus.failure, error: failure.message),
      ),
      (session) {
        emit(
          state.copyWith(
            step: 2,
            saleStatus: SaleStatus.awaitingPayment,
            session: session,
          ),
        );
        _startPolling(session);
      },
    );
  }

  // ── Suivi du paiement ───────────────────────────────────────────────────────

  void _startPolling(PaymentSession session) {
    _poll?.cancel();
    final token = session.washSessionToken;
    Future<void> refresh() => token == null
        ? _refreshManualPayment(session.paymentId)
        : _refreshStatus(token);
    _poll = Timer.periodic(_pollInterval, (_) => refresh());
    refresh();
  }

  Future<void> _refreshManualPayment(String paymentId) async {
    final result = await _payments.isPaymentConfirmed(paymentId);
    if (isClosed) return;
    result.fold((_) => null, (confirmed) {
      if (confirmed) {
        _poll?.cancel();
        emit(state.copyWith(step: 3, saleStatus: SaleStatus.paid));
      }
    });
  }

  Future<void> _refreshStatus(String token) async {
    final result = await _sessions.getSessionStatus(token);
    if (isClosed) return;

    result.fold(
      // Erreur réseau : on garde l'écran en l'état, le tick suivant retentera.
      (_) => null,
      (status) {
        if (status.paymentStatus == SessionPaymentStatus.confirmed) {
          _poll?.cancel();
          emit(state.copyWith(step: 3, saleStatus: SaleStatus.paid));
        } else if (status.paymentStatus.isTerminalFailure) {
          _poll?.cancel();
          emit(
            state.copyWith(
              saleStatus: SaleStatus.failure,
              error: 'Le paiement n\'a pas abouti.',
            ),
          );
        }
      },
    );
  }

  /// Force une lecture PayDunya quand le client vient de confirmer son geste.
  Future<bool?> verifyPayment() async {
    final paymentId = state.session?.paymentId;
    if (paymentId == null || state.isVerifyingPayment) return null;

    emit(state.copyWith(isVerifyingPayment: true, clearError: true));
    final result = await _payments.reconcilePayment(paymentId);
    if (isClosed) return null;

    return result.fold(
      (failure) {
        emit(state.copyWith(isVerifyingPayment: false, error: failure.message));
        return null;
      },
      (confirmed) {
        emit(
          state.copyWith(
            isVerifyingPayment: false,
            step: confirmed ? 3 : state.step,
            saleStatus: confirmed ? SaleStatus.paid : state.saleStatus,
            clearError: true,
          ),
        );
        if (confirmed) _poll?.cancel();
        return confirmed;
      },
    );
  }

  // ── Démarrage par l'agent ───────────────────────────────────────────────────

  /// Le client n'ayant pas l'app, c'est l'agent qui lance la machine une fois
  /// le linge chargé. Le jeton de session est resté de son côté.
  Future<String?> startMachine(Machine machine) async {
    final session = state.session;
    if (session == null ||
        !state.needsMachine ||
        session.washSessionToken == null ||
        state.saleStatus != SaleStatus.paid) {
      return 'Ce cycle ne peut pas être démarré.';
    }

    emit(state.copyWith(saleStatus: SaleStatus.starting, clearError: true));

    final result = await _sessions.startMachine(
      session.washSessionToken!,
      machineId: machine.id,
    );

    return result.fold(
      (failure) {
        emit(
          // Retour à « payé » : le paiement reste valide, l'agent peut réessayer.
          state.copyWith(saleStatus: SaleStatus.paid, clearError: true),
        );
        return failure.message;
      },
      (_) {
        emit(
          state.copyWith(
            saleStatus: SaleStatus.started,
            machine: machine,
            clearError: true,
          ),
        );
        return null;
      },
    );
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
