import 'package:equatable/equatable.dart';

import 'notification_kind.dart';

/// Données structurées d'une notification push (champ `data` FCM).
///
/// Les valeurs FCM arrivent toujours en `String` — on les lit telles quelles.
/// Le backend joint toujours `notificationId` (et parfois `smsFallbackId`),
/// utilisés pour l'acquittement (qui annule le SMS de repli).
class NotificationPayload extends Equatable {
  const NotificationPayload({
    required this.kind,
    this.notificationId,
    this.smsFallbackId,
    this.primaryUrl,
    this.fallbackUrl,
    this.dropOffId,
  });

  final NotificationKind kind;
  final String? notificationId;
  final String? smsFallbackId;

  /// PAYMENT_REQUEST : URL Wave/OM à ouvrir (Maxit pour OM).
  final String? primaryUrl;

  /// PAYMENT_REQUEST : repli (URL Orange Money classique).
  final String? fallbackUrl;

  /// DROPOFF_REGISTERED / WASH_READY : dépôt concerné.
  final String? dropOffId;

  factory NotificationPayload.fromData(Map<String, dynamic> data) {
    String? read(String key) => data[key]?.toString();

    return NotificationPayload(
      kind: NotificationKind.fromApi(read('kind')),
      notificationId: read('notificationId'),
      smsFallbackId: read('smsFallbackId'),
      primaryUrl: read('primaryUrl'),
      fallbackUrl: read('fallbackUrl'),
      dropOffId: read('dropOffId'),
    );
  }

  @override
  List<Object?> get props => [
    kind,
    notificationId,
    smsFallbackId,
    primaryUrl,
    fallbackUrl,
    dropOffId,
  ];
}
