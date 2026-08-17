import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_session.dart';

/// URLs réellement renvoyées par PayDunya (relevé du 2026-08-04, mode test).
/// Servent de référence : si la forme change, ce test casse.
const _waveRedirect =
    'https://pay.wave.com/c/cos-26fe3na981h5t?a=4000&c=XOF&m=Fotdelsi';
const _omDirect = 'https://sugu.orange-sonatel.com/mp/dme7uh7x1B1dytw2kwEU';

/// Malgré son nom, c'est une PAGE HTML qui affiche un QR : le PNG y est encodé
/// en base64 dans la query string. L'encoder en QR mènerait à cette page, pas
/// au paiement.
const _omPagePayDunya =
    'https://app.paydunya.com/orange-money?data%5Bqrcode%5D=iVBORw0KGgoAAAANSUhEUg';

PaymentSession _session({
  required PaymentProvider provider,
  String? redirectUrl,
  String? omUrl,
  String? maxitUrl,
  String? qrCodeUrl,
}) => PaymentSession(
  provider: provider,
  machineId: 'm-1',
  paymentId: 'p-1',
  externalRef: 'FOT-1',
  amount: 4000,
  reservedUntil: '2026-08-04T17:00:00.000Z',
  washSessionToken: 'tok',
  redirectUrl: redirectUrl,
  omUrl: omUrl,
  maxitUrl: maxitUrl,
  qrCodeUrl: qrCodeUrl,
);

void main() {
  group('PaymentSession.qrPayload', () {
    test('encode le lien de paiement Wave', () {
      final s = _session(
        provider: PaymentProvider.wave,
        redirectUrl: _waveRedirect,
      );

      expect(s.qrPayload, _waveRedirect);
      expect(s.qrPayload!.startsWith('https://'), isTrue);
    });

    test('encode le lien direct Orange Money, pas la page PayDunya', () {
      final s = _session(
        provider: PaymentProvider.orangeMoney,
        omUrl: _omDirect,
        maxitUrl: _omDirect,
        qrCodeUrl: _omPagePayDunya,
      );

      expect(s.qrPayload, _omDirect);
      // Le piège : `qrCodeUrl` ne doit jamais être choisi.
      expect(s.qrPayload, isNot(_omPagePayDunya));
    });

    test('retombe sur Maxit si le lien OM manque', () {
      final s = _session(
        provider: PaymentProvider.orangeMoney,
        maxitUrl: _omDirect,
        qrCodeUrl: _omPagePayDunya,
      );

      expect(s.qrPayload, _omDirect);
    });

    test('vaut null si aucun lien exploitable', () {
      // Mieux vaut ne rien afficher qu'un QR menant nulle part.
      expect(
        _session(
          provider: PaymentProvider.orangeMoney,
          qrCodeUrl: _omPagePayDunya,
        ).qrPayload,
        isNull,
      );
      expect(_session(provider: PaymentProvider.wave).qrPayload, isNull);
    });
  });
}
