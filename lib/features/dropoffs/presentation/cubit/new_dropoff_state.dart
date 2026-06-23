part of 'new_dropoff_cubit.dart';

enum LoadStatus { initial, loading, success, failure }

enum SubmitStatus { idle, loading, success, failure }

final _phoneRegex = RegExp(r'^(70|71|75|76|77|78)\d{7}$');

final class NewDropOffState extends Equatable {
  const NewDropOffState({
    this.step = 0,
    this.contactPhone = '',
    this.customerName = '',
    this.pieces = 1,
    this.types = const {},
    this.instructions = '',
    this.prestations = const [],
    this.prestationsStatus = LoadStatus.initial,
    this.amount,
    this.provider,
    this.submitStatus = SubmitStatus.idle,
    this.error,
  });

  final int step;

  final String contactPhone;
  final String customerName;

  final int pieces;
  final Set<LaundryType> types;
  final String instructions;

  final List<Prestation> prestations;
  final LoadStatus prestationsStatus;

  final int? amount;
  final PaymentProvider? provider;

  final SubmitStatus submitStatus;
  final String? error;

  // ── Validations ─────────────────────────────────────────────────────────────

  bool get isPhoneValid => _phoneRegex.hasMatch(contactPhone);
  bool get canLeaveClient => isPhoneValid && customerName.trim().isNotEmpty;
  bool get canLeaveLaundry => pieces >= 1 && types.isNotEmpty;
  bool get canSubmit => amount != null && provider != null;
  bool get isSubmitting => submitStatus == SubmitStatus.loading;

  NewDropOffState copyWith({
    int? step,
    String? contactPhone,
    String? customerName,
    int? pieces,
    Set<LaundryType>? types,
    String? instructions,
    List<Prestation>? prestations,
    LoadStatus? prestationsStatus,
    int? amount,
    PaymentProvider? provider,
    SubmitStatus? submitStatus,
    String? error,
    bool clearError = false,
  }) {
    return NewDropOffState(
      step: step ?? this.step,
      contactPhone: contactPhone ?? this.contactPhone,
      customerName: customerName ?? this.customerName,
      pieces: pieces ?? this.pieces,
      types: types ?? this.types,
      instructions: instructions ?? this.instructions,
      prestations: prestations ?? this.prestations,
      prestationsStatus: prestationsStatus ?? this.prestationsStatus,
      amount: amount ?? this.amount,
      provider: provider ?? this.provider,
      submitStatus: submitStatus ?? this.submitStatus,
      error: clearError ? null : (error ?? this.error),
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
    prestations,
    prestationsStatus,
    amount,
    provider,
    submitStatus,
    error,
  ];
}
