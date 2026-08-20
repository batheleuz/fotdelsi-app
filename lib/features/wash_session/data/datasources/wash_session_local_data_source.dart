import 'package:shared_preferences/shared_preferences.dart';

import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import '../../domain/entities/machine_start_status.dart';
import '../../domain/entities/pending_wash_session.dart';
import '../../domain/entities/session_payment_status.dart';

/// Clés de stockage SharedPreferences.
///
/// Les liens de paiement (`redirectUrl`, `maxitUrl`, `omUrl`, `qrCodeUrl`) ne
/// sont volontairement PAS conservés. Ils ne servent qu'une fois, juste après
/// l'initiation, pour ouvrir Wave ou Orange Money — `PaymentLauncher` les lit
/// dans la session en mémoire. Les persister revenait à garder sur l'appareil
/// des URLs de transaction qui ne seraient jamais relues.
abstract final class _Keys {
  static const token = 'wash_session_token';
  static const machineId = 'wash_session_machine_id';
  static const provider = 'wash_session_provider';
  static const sessionPaymentStatus = 'wash_session_payment_status';
  static const machineStartStatus = 'wash_session_machine_start_status';
}

/// Persiste le strict nécessaire au suivi d'un paiement en cours.
///
/// L'état du CYCLE — statut, temps restant, fin — ne vit plus ici : il vient
/// du serveur via `GET /me/cycles`, rattaché au numéro lié. Ce qui reste sert
/// uniquement à retrouver le paiement en attente au retour de l'application
/// mobile money, avant que le webhook ne soit arrivé.
class WashSessionLocalDataSource {
  const WashSessionLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  Future<void> save(PendingWashSession session) async {
    await Future.wait([
      _prefs.setString(_Keys.token, session.washSessionToken),
      _prefs.setString(_Keys.machineId, session.machineId),
      _prefs.setString(_Keys.provider, session.provider.apiValue),
      _prefs.setString(
        _Keys.sessionPaymentStatus,
        session.sessionPaymentStatus.name,
      ),
      _prefs.setString(
        _Keys.machineStartStatus,
        session.machineStartStatus.name,
      ),
    ]);
  }

  PendingWashSession? load() {
    final token = _prefs.getString(_Keys.token);
    if (token == null) return null;

    final providerStr = _prefs.getString(_Keys.provider) ?? '';
    final provider = switch (providerStr) {
      'WAVE' => PaymentProvider.wave,
      'ORANGE_MONEY' => PaymentProvider.orangeMoney,
      _ => null,
    };
    if (provider == null) return null;

    final paymentStatusStr =
        _prefs.getString(_Keys.sessionPaymentStatus) ?? 'pendingPayment';
    final sessionPaymentStatus = SessionPaymentStatus.values.firstWhere(
      (e) => e.name == paymentStatusStr,
      orElse: () => SessionPaymentStatus.pendingPayment,
    );

    final startStatusStr =
        _prefs.getString(_Keys.machineStartStatus) ?? 'pending';
    final machineStartStatus = MachineStartStatus.values.firstWhere(
      (e) => e.name == startStatusStr,
      orElse: () => MachineStartStatus.pending,
    );

    // Les liens de paiement sont absents d'une session RESTAURÉE : elle ne
    // sert qu'au suivi, jamais à relancer une redirection.
    return PendingWashSession(
      washSessionToken: token,
      machineId: _prefs.getString(_Keys.machineId) ?? '',
      provider: provider,
      sessionPaymentStatus: sessionPaymentStatus,
      machineStartStatus: machineStartStatus,
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _prefs.remove(_Keys.token),
      _prefs.remove(_Keys.machineId),
      _prefs.remove(_Keys.provider),
      _prefs.remove(_Keys.sessionPaymentStatus),
      _prefs.remove(_Keys.machineStartStatus),
      // Purge des clés d'une version antérieure, qui stockait aussi les liens
      // de paiement. Sans ça, elles resteraient indéfiniment sur les appareils
      // déjà installés.
      _prefs.remove('wash_session_redirect_url'),
      _prefs.remove('wash_session_maxit_url'),
      _prefs.remove('wash_session_om_url'),
      _prefs.remove('wash_session_qr_code_url'),
    ]);
  }
}
