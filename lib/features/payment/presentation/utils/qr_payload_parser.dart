/// Résultat du parsing d'un QR code machine.
final class QrParseResult {
  const QrParseResult({required this.deviceName});

  /// Identifiant physique de la machine (paramètre `sn` de l'URL eqlinker,
  /// ou valeur brute saisie manuellement).
  final String deviceName;
}

/// Extrait le [QrParseResult] depuis le contenu brut d'un QR.
///
/// Formats acceptés :
/// - URL eqlinker : `https://www.eqlinker.com/...?sn=NYJ312007A100225455`
///   → extrait le query param `sn`
/// - Deeplink interne : `fotdelsi://machine/<deviceName>`
///   → extrait le dernier segment du path
/// - Valeur brute (saisie manuelle) : `WASH_02`
///   → utilisée directement
abstract final class QrPayloadParser {
  const QrPayloadParser._();

  static QrParseResult? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);

    if (uri != null && uri.hasScheme) {
      // Priorité 1 : query param `sn` (URL eqlinker)
      final sn = uri.queryParameters['sn'];
      if (sn != null && sn.isNotEmpty) {
        return QrParseResult(deviceName: sn);
      }

      // Priorité 2 : dernier segment du path (deeplink interne)
      if (uri.pathSegments.isNotEmpty) {
        final segment = uri.pathSegments.last;
        if (segment.isNotEmpty) return QrParseResult(deviceName: segment);
      }

      return null;
    }

    // Valeur brute (saisie manuelle ou QR simple)
    return QrParseResult(deviceName: trimmed);
  }
}
