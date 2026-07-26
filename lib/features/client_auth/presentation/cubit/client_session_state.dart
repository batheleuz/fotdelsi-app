part of 'client_session_cubit.dart';

final class ClientSessionState extends Equatable {
  const ClientSessionState({this.phone});

  /// Numéro lié, `null` si aucun numéro n'est lié sur cet appareil.
  final String? phone;

  bool get isLinked => phone != null;

  @override
  List<Object?> get props => [phone];
}
