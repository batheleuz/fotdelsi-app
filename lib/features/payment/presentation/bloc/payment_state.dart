import 'package:equatable/equatable.dart';

import '../../domain/entities/payment_provider.dart';
import '../../domain/entities/payment_session.dart';

enum PaymentStatus { idle, processing, success, failure }

/// État immuable de l'écran de paiement.
final class PaymentState extends Equatable {
  const PaymentState({
    this.status = PaymentStatus.idle,
    this.provider,
    this.phone = '',
    this.customerFullName = '',
    this.session,
    this.errorMessage,
  });

  final PaymentStatus status;
  final PaymentProvider? provider;
  final String phone;
  final String customerFullName;

  /// Renseigné après une initiation réussie.
  final PaymentSession? session;

  /// Renseigné en cas d'échec de l'appel API.
  final String? errorMessage;

  /// Numéro sénégalais : 9 chiffres (ex. 771234567).
  bool get isPhoneValid => RegExp(r'^\d{9}$').hasMatch(phone);

  bool get isNameValid => customerFullName.trim().isNotEmpty;

  bool get canPay =>
      provider != null &&
      isPhoneValid &&
      isNameValid &&
      status != PaymentStatus.processing;

  bool get isProcessing => status == PaymentStatus.processing;

  PaymentState copyWith({
    PaymentStatus? status,
    PaymentProvider? provider,
    String? phone,
    String? customerFullName,
    PaymentSession? session,
    String? errorMessage,
  }) {
    return PaymentState(
      status: status ?? this.status,
      provider: provider ?? this.provider,
      phone: phone ?? this.phone,
      customerFullName: customerFullName ?? this.customerFullName,
      session: session ?? this.session,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    provider,
    phone,
    customerFullName,
    session,
    errorMessage,
  ];
}
