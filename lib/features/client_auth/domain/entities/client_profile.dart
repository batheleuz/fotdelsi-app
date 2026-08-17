import 'package:equatable/equatable.dart';

/// Identité du client, rattachée à son numéro côté serveur.
///
/// Le nom ne vit plus dans le stockage du téléphone : il appartient au client,
/// pas à l'appareil. Il le retrouve donc après une réinstallation, et sur
/// n'importe quel appareil où il lie son numéro.
class ClientProfile extends Equatable {
  const ClientProfile({required this.phone, this.fullName});

  /// Clé fonctionnelle, vérifiée par OTP. Non modifiable : en changer
  /// reviendrait à devenir quelqu'un d'autre, ce qui passe par une nouvelle
  /// liaison.
  final String phone;

  /// `null` tant que le client ne s'est pas nommé.
  final String? fullName;

  @override
  List<Object?> get props => [phone, fullName];
}
