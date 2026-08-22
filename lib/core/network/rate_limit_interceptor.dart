import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';

/// Réessaie une fois, en silence, une requête refusée pour cause de débit.
///
/// Le serveur compte désormais par agent connecté et non plus par adresse, ce
/// qui a supprimé la cause des refus en série. Reste le pic ponctuel : l'écran
/// d'accueil agent charge cinq listes d'un coup, et chaque signal temps réel
/// les recharge toutes. Un `429` isolé y est un accident de synchronisation,
/// pas un abus — le faire remonter en « Trop de requêtes » ferait passer pour
/// une panne ce qu'une pause de deux secondes résout.
///
/// Une seule tentative, volontairement. Réessayer en boucle ajouterait de la
/// charge à un serveur qui vient justement de dire qu'il en a trop ; si la
/// seconde tentative échoue, le message doit remonter à l'utilisateur.
///
/// Les écritures ne sont PAS reprises : rejouer un démarrage de machine ou une
/// initiation de paiement pourrait lancer un cycle en double. Seules les
/// lectures — celles qui n'ont aucun effet — sont rejouées.
class RateLimitInterceptor extends Interceptor {
  RateLimitInterceptor(this._dio, {Future<void> Function(Duration)? delay})
    : _delay = delay ?? Future<void>.delayed;

  final Dio _dio;

  /// Injectable pour les tests, qui ne doivent pas attendre réellement.
  final Future<void> Function(Duration) _delay;

  /// Marque une requête déjà rejouée, pour ne pas boucler.
  static const _retriedFlag = 'x-fotdelsi-retry';

  /// Plafond de patience. Au-delà, mieux vaut rendre la main à l'utilisateur
  /// que de laisser un écran tourner sans fin.
  static const _maxWait = Duration(seconds: 5);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;

    if (err.response?.statusCode != 429 ||
        !_isRead(request) ||
        request.extra[_retriedFlag] == true) {
      return handler.next(err);
    }

    final wait = _announcedDelay(err.response) ?? const Duration(seconds: 2);
    if (wait > _maxWait) return handler.next(err);

    await _delay(wait);

    try {
      final response = await _dio.fetch<dynamic>(
        request..extra[_retriedFlag] = true,
      );
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Rejouable seulement si la requête ne change rien côté serveur.
  bool _isRead(RequestOptions options) =>
      options.method.toUpperCase() == 'GET';

  /// Combien de temps le serveur demande d'attendre.
  ///
  /// `Retry-After` est la réponse standard ; `RateLimit-Reset` (draft-7, que
  /// pose `express-rate-limit`) le complète. Les deux sont en secondes.
  Duration? _announcedDelay(Response<dynamic>? response) {
    final headers = response?.headers;
    if (headers == null) return null;

    for (final name in const ['retry-after', 'ratelimit-reset']) {
      final raw = headers.value(name);
      final seconds = raw == null ? null : int.tryParse(raw.trim());
      // `0` arrive quand la fenêtre expire dans la seconde : on attend quand
      // même un instant, sinon on retombe sur le même refus.
      if (seconds != null) {
        return Duration(seconds: math.max(seconds, 1));
      }
    }
    return null;
  }
}
