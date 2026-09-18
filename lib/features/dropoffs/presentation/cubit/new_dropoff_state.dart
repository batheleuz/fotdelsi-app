part of 'new_dropoff_cubit.dart';

enum LoadStatus { initial, loading, success, failure }

enum SubmitStatus { idle, loading, success, failure }

final _phoneRegex = RegExp(r'^(70|71|75|76|77|78)\d{7}$');

final class NewDropOffState extends Equatable {
  const NewDropOffState({
    this.step = 0,
    this.contactPhone = '',
    this.customerName = '',
    this.pieces = 0,
    this.types = const {},
    this.instructions = '',
    this.formulas = const [],
    this.formulasStatus = LoadStatus.initial,
    this.formulaCode,
    this.sizeKg,
    this.dryingTier = DryingDurationTier.defaultTier,
    this.provider,
    this.draftId,
    this.delivery = PaymentDelivery.notify,
    this.session,
    this.submitStatus = SubmitStatus.idle,
    this.error,
    this.isPaid = false,
  });

  final int step;

  final String contactPhone;
  final String customerName;

  final int pieces;
  final Set<LaundryType> types;
  final String instructions;

  /// Catalogue officiel, chargé depuis le serveur.
  final List<ServiceFormula> formulas;
  final LoadStatus formulasStatus;

  /// Formule et capacité choisies — le seul couple transmis au serveur.
  final String? formulaCode;
  final int? sizeKg;
  final DryingDurationTier dryingTier;

  final PaymentProvider? provider;

  /// Brouillon créé à la soumission (réutilisé par le renvoi de paiement).
  final String? draftId;

  /// Comment la demande atteint le payeur, choisi par l'agent au moment de la
  /// demande. Le client est-il devant lui, ou a-t-il envoyé quelqu'un ?
  final PaymentDelivery delivery;

  /// Session de paiement rendue par le serveur.
  ///
  /// Elle porte le lien à encoder en QR. Elle était jetée, ce qui interdisait
  /// tout canal autre que la notification.
  final PaymentSession? session;

  /// Y a-t-il un code à montrer au client ?
  bool get showsQr =>
      delivery == PaymentDelivery.onSite && session?.qrPayload != null;

  ServiceFormula? get selectedFormula {
    for (final formula in formulas) {
      if (formula.code == formulaCode) return formula;
    }
    return null;
  }

  bool get hasDrying => selectedFormula?.includesDrying ?? false;

  /// Montant affiché, lu dans la grille. Purement indicatif : le serveur
  /// retarifie de son côté et c'est son prix qui fait foi.
  int? get total {
    final formula = selectedFormula;
    if (formula == null || sizeKg == null) return null;
    final base = formula.priceFor(sizeKg!);
    if (base == null) return null;
    return hasDrying ? base + dryingTier.price : base;
  }

  /// Capacités proposées pour la formule choisie.
  List<int> get availableSizes => selectedFormula?.sizes ?? const [];

  final SubmitStatus submitStatus;
  final String? error;
  final bool isPaid;

  // ── Validations ─────────────────────────────────────────────────────────────

  bool get isPhoneValid => _phoneRegex.hasMatch(contactPhone);
  bool get canLeaveClient => isPhoneValid && customerName.trim().isNotEmpty;
  bool get canLeaveLaundry => true;
  bool get canSubmit =>
      formulaCode != null &&
      sizeKg != null &&
      provider != null &&
      (total ?? 0) > 0;
  bool get isSubmitting => submitStatus == SubmitStatus.loading;

  NewDropOffState copyWith({
    int? step,
    String? contactPhone,
    String? customerName,
    int? pieces,
    Set<LaundryType>? types,
    String? instructions,
    List<ServiceFormula>? formulas,
    LoadStatus? formulasStatus,
    String? formulaCode,
    int? sizeKg,
    DryingDurationTier? dryingTier,
    PaymentProvider? provider,
    String? draftId,
    PaymentDelivery? delivery,
    PaymentSession? session,
    SubmitStatus? submitStatus,
    String? error,
    bool? isPaid,
    bool clearError = false,
    bool clearSize = false,
  }) {
    return NewDropOffState(
      step: step ?? this.step,
      contactPhone: contactPhone ?? this.contactPhone,
      customerName: customerName ?? this.customerName,
      pieces: pieces ?? this.pieces,
      types: types ?? this.types,
      instructions: instructions ?? this.instructions,
      formulas: formulas ?? this.formulas,
      formulasStatus: formulasStatus ?? this.formulasStatus,
      formulaCode: formulaCode ?? this.formulaCode,
      sizeKg: clearSize ? null : (sizeKg ?? this.sizeKg),
      dryingTier: dryingTier ?? this.dryingTier,
      provider: provider ?? this.provider,
      draftId: draftId ?? this.draftId,
      delivery: delivery ?? this.delivery,
      session: session ?? this.session,
      submitStatus: submitStatus ?? this.submitStatus,
      error: clearError ? null : (error ?? this.error),
      isPaid: isPaid ?? this.isPaid,
    );
  }

  @override
  List<Object?> get props => [
    step,
    contactPhone,
    customerName,
    pieces,
    types,
    instructions,
    formulas,
    formulasStatus,
    formulaCode,
    sizeKg,
    dryingTier,
    provider,
    draftId,
    delivery,
    session?.qrPayload,
    submitStatus,
    error,
    isPaid,
  ];
}
