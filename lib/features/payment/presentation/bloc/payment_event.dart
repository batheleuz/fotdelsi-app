import 'package:equatable/equatable.dart';

import '../../domain/entities/payment_provider.dart';

sealed class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

/// L'utilisateur choisit un moyen de paiement.
final class PaymentProviderSelected extends PaymentEvent {
  const PaymentProviderSelected(this.provider);

  final PaymentProvider provider;

  @override
  List<Object?> get props => [provider];
}

/// Le nom complet du client est saisi.
final class PaymentNameChanged extends PaymentEvent {
  const PaymentNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

/// Le numéro de téléphone mobile money est saisi.
final class PaymentPhoneChanged extends PaymentEvent {
  const PaymentPhoneChanged(this.phone);

  final String phone;

  @override
  List<Object?> get props => [phone];
}

/// Lancement du paiement SOFTPAY.
///
/// Porte le [machineId] car le bloc ne connaît pas la machine —
/// seule la page la détient via le paramètre de navigation.
final class PaymentSubmitted extends PaymentEvent {
  const PaymentSubmitted({required this.machineId});

  final String machineId;

  @override
  List<Object?> get props => [machineId];
}
