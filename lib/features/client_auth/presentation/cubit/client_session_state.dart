part of 'client_session_cubit.dart';

final class ClientSessionState extends Equatable {
  const ClientSessionState({this.phone, this.fullName, this.saving = false});

  /// Numéro lié, `null` si aucun numéro n'est lié sur cet appareil.
  ///
  /// Vient du stockage local — c'est lui qui dit si une session existe. Le
  /// serveur renvoie le même numéro dans le profil, mais on ne peut pas le
  /// demander avant de savoir qu'on est authentifié.
  final String? phone;

  /// Nom du client, tel qu'il l'a enregistré côté serveur. `null` tant qu'il
  /// ne s'est pas nommé, ou tant que le profil n'a pas été chargé.
  final String? fullName;

  /// Un enregistrement de nom est en cours.
  final bool saving;

  bool get isLinked => phone != null;

  ClientSessionState copyWith({
    String? phone,
    String? fullName,
    bool? saving,
    bool clearName = false,
  }) {
    return ClientSessionState(
      phone: phone ?? this.phone,
      fullName: clearName ? null : (fullName ?? this.fullName),
      saving: saving ?? this.saving,
    );
  }

  @override
  List<Object?> get props => [phone, fullName, saving];
}
