part of 'counter_sale_cubit.dart';

enum SaleLoadStatus { initial, loading, success, failure }

/// Étapes de la vente au comptoir, dans l'ordre du parcours réel.
enum SaleStatus {
  /// L'agent renseigne la commande.
  composing,

  /// Initiation en cours auprès de l'opérateur.
  submitting,

  /// QR affiché, on attend que le client paie depuis son téléphone.
  awaitingPayment,

  /// Paiement confirmé : la machine peut être lancée.
  paid,

  /// Démarrage physique en cours.
  starting,

  /// Machine lancée — la vente est terminée.
  started,

  failure,
}

final class CounterSaleState extends Equatable {
  const CounterSaleState({
    this.step = 0,
    this.loadStatus = SaleLoadStatus.initial,
    this.formulas = const [],
    this.machines = const [],
    this.formulaCode,
    this.machine,
    this.customerName = '',
    this.customerPhone = '',
    this.provider,
    this.saleStatus = SaleStatus.composing,
    this.session,
    this.error,
  });

  /// Étape affichée : 0 prestation · 1 client · 2 paiement · 3 démarrage.
  ///
  /// Portée par l'état plutôt que par la navigation : le parcours est un seul
  /// écran qui change de contenu, et un retour arrière ne doit pas perdre la
  /// vente en cours.
  final int step;

  final SaleLoadStatus loadStatus;
  final List<ServiceFormula> formulas;
  final List<Machine> machines;

  final String? formulaCode;
  final Machine? machine;
  final String customerName;
  final String customerPhone;
  final PaymentProvider? provider;

  final SaleStatus saleStatus;

  /// Renvoyée par l'initiation : porte le lien à encoder en QR et le jeton de
  /// session qui permettra à l'agent de lancer la machine.
  final PaymentSession? session;

  final String? error;

  ServiceFormula? get selectedFormula {
    for (final f in formulas) {
      if (f.code == formulaCode) return f;
    }
    return null;
  }

  /// Montant affiché, lu dans la grille. Indicatif : le serveur retarife.
  int? get total {
    final formula = selectedFormula;
    final size = machine?.size;
    if (formula == null || size == null) return null;
    return formula.priceFor(size);
  }

  /// Lien de paiement à encoder en QR, une fois la vente initiée.
  String? get qrPayload => session?.qrPayload;

  bool get isSubmitting => saleStatus == SaleStatus.submitting;
  bool get isStarting => saleStatus == SaleStatus.starting;

  /// Le QR est à l'écran et le client n'a pas encore payé.
  bool get isAwaitingPayment => saleStatus == SaleStatus.awaitingPayment;

  bool get canSubmit =>
      formulaCode != null &&
      machine != null &&
      provider != null &&
      customerName.trim().length >= 2 &&
      _phoneRegex.hasMatch(customerPhone);

  /// L'agent peut-il avancer depuis l'étape courante ?
  bool get canGoNext => switch (step) {
    0 => formulaCode != null && machine != null,
    1 =>
      provider != null &&
          customerName.trim().length >= 2 &&
          _phoneRegex.hasMatch(customerPhone),
    _ => false,
  };

  /// Le retour arrière s'arrête au paiement : une fois le QR présenté, la
  /// commande est engagée côté opérateur, on ne la recompose plus.
  bool get canGoBack => step > 0 && step < 2;

  CounterSaleState copyWith({
    int? step,
    SaleLoadStatus? loadStatus,
    List<ServiceFormula>? formulas,
    List<Machine>? machines,
    String? formulaCode,
    Machine? machine,
    bool clearMachine = false,
    String? customerName,
    String? customerPhone,
    PaymentProvider? provider,
    SaleStatus? saleStatus,
    PaymentSession? session,
    String? error,
    bool clearError = false,
  }) {
    return CounterSaleState(
      step: step ?? this.step,
      loadStatus: loadStatus ?? this.loadStatus,
      formulas: formulas ?? this.formulas,
      machines: machines ?? this.machines,
      formulaCode: formulaCode ?? this.formulaCode,
      machine: clearMachine ? null : (machine ?? this.machine),
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      provider: provider ?? this.provider,
      saleStatus: saleStatus ?? this.saleStatus,
      session: session ?? this.session,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    step,
    loadStatus,
    formulas,
    machines,
    formulaCode,
    machine,
    customerName,
    customerPhone,
    provider,
    saleStatus,
    session?.washSessionToken,
    error,
  ];
}

final _phoneRegex = RegExp(r'^(70|71|75|76|77|78)\d{7}$');
