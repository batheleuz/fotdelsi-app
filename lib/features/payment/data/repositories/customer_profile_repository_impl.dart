import 'package:fotdelsi/features/client_auth/presentation/cubit/client_session_cubit.dart';
import '../../domain/entities/customer_profile.dart';
import '../../domain/repositories/customer_profile_repository.dart';
import '../datasources/customer_profile_local_data_source.dart';

/// Pré-remplissage des champs du paiement.
///
/// La source de vérité est le PROFIL SERVEUR, rattaché au numéro lié : nom et
/// numéro appartiennent au client, pas à l'appareil. Il les retrouve donc
/// après une réinstallation, ou sur un autre téléphone.
///
/// Le stockage local ne sert plus que de repli, pour le tout premier rendu
/// avant que le profil ne soit chargé. Il reste alimenté par [save] afin que
/// ce repli dise quelque chose d'utile.
class CustomerProfileRepositoryImpl implements CustomerProfileRepository {
  const CustomerProfileRepositoryImpl(this._local, this._session);

  final CustomerProfileLocalDataSource _local;
  final ClientSessionCubit _session;

  @override
  CustomerProfile load() {
    final local = _local.load();
    final state = _session.state;

    // Champ par champ, et non « profil serveur OU profil local » : le nom
    // peut être absent côté serveur alors que le numéro est lié. Basculer en
    // bloc effacerait un nom déjà saisi pour cette seule raison.
    return CustomerProfile(
      fullName: state.fullName ?? local.fullName,
      phone: state.phone ?? local.phone,
    );
  }

  /// Mémorise localement ce que le client vient de saisir.
  ///
  /// N'écrit PAS le profil serveur : au paiement, le client peut vouloir un
  /// autre nom ou un autre numéro mobile money pour cette transaction sans
  /// que cela redéfinisse son identité. Se renommer durablement se fait depuis
  /// son compte.
  @override
  Future<void> save(CustomerProfile profile) => _local.save(profile);
}
