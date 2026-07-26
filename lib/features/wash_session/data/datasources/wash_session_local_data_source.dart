import 'package:shared_preferences/shared_preferences.dart';

import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import '../../domain/entities/machine_start_status.dart';
import '../../domain/entities/pending_wash_session.dart';
import '../../domain/entities/session_payment_status.dart';

/// Clés de stockage SharedPreferences.
abstract final class _Keys {
  static const token = 'wash_session_token';
  static const machineId = 'wash_session_machine_id';
  static const provider = 'wash_session_provider';
  static const sessionPaymentStatus = 'wash_session_payment_status';
  static const machineStartStatus = 'wash_session_machine_start_status';
  static const redirectUrl = 'wash_session_redirect_url';
  static const maxitUrl = 'wash_session_maxit_url';
  static const omUrl = 'wash_session_om_url';
  static const qrCodeUrl = 'wash_session_qr_code_url';
}

/// Persiste la session de lavage en attente sur le device.
class WashSessionLocalDataSource {
  const WashSessionLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  Future<void> save(PendingWashSession session) async {
    await Future.wait([
      _prefs.setString(_Keys.token, session.washSessionToken),
      _prefs.setString(_Keys.machineId, session.machineId),
      _prefs.setString(_Keys.provider, session.provider.apiValue),
      _prefs.setString(
          _Keys.sessionPaymentStatus, session.sessionPaymentStatus.name),
      _prefs.setString(
          _Keys.machineStartStatus, session.machineStartStatus.name),
      if (session.redirectUrl != null)
        _prefs.setString(_Keys.redirectUrl, session.redirectUrl!)
      else
        _prefs.remove(_Keys.redirectUrl),
      if (session.maxitUrl != null)
        _prefs.setString(_Keys.maxitUrl, session.maxitUrl!)
      else
        _prefs.remove(_Keys.maxitUrl),
      if (session.omUrl != null)
        _prefs.setString(_Keys.omUrl, session.omUrl!)
      else
        _prefs.remove(_Keys.omUrl),
      if (session.qrCodeUrl != null)
        _prefs.setString(_Keys.qrCodeUrl, session.qrCodeUrl!)
      else
        _prefs.remove(_Keys.qrCodeUrl),
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

    return PendingWashSession(
      washSessionToken: token,
      machineId: _prefs.getString(_Keys.machineId) ?? '',
      provider: provider,
      sessionPaymentStatus: sessionPaymentStatus,
      machineStartStatus: machineStartStatus,
      redirectUrl: _prefs.getString(_Keys.redirectUrl),
      maxitUrl: _prefs.getString(_Keys.maxitUrl),
      omUrl: _prefs.getString(_Keys.omUrl),
      qrCodeUrl: _prefs.getString(_Keys.qrCodeUrl),
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _prefs.remove(_Keys.token),
      _prefs.remove(_Keys.machineId),
      _prefs.remove(_Keys.provider),
      _prefs.remove(_Keys.sessionPaymentStatus),
      _prefs.remove(_Keys.machineStartStatus),
      _prefs.remove(_Keys.redirectUrl),
      _prefs.remove(_Keys.maxitUrl),
      _prefs.remove(_Keys.omUrl),
      _prefs.remove(_Keys.qrCodeUrl),
    ]);
  }
}
