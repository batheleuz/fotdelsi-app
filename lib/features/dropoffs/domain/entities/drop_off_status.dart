/// Statut d'un dépôt — miroir de la machine à états backend.
///
/// `RECEIVED → IN_PROGRESS → READY → COLLECTED` (flux nominal),
/// `LOST` / `REFUNDED` étant des états terminaux d'exception.
enum DropOffStatus {
  /// Payé, mais le linge est encore chez le client (libre-service).
  awaitingHandoff,
  received,
  inProgress,
  ready,
  collected,
  lost,
  refunded;

  static DropOffStatus fromApi(String value) => switch (value) {
    'AWAITING_HANDOFF' => awaitingHandoff,
    'RECEIVED' => received,
    'IN_PROGRESS' => inProgress,
    'READY' => ready,
    'COLLECTED' => collected,
    'LOST' => lost,
    'REFUNDED' => refunded,
    _ => received,
  };

  bool get isTerminal => this == collected || this == lost || this == refunded;

  /// Une machine tourne en ce moment pour ce dépôt.
  ///
  /// Le seul statut réellement actif : c'est lui qui fait respirer la pastille
  /// du badge, et lui seul — un statut d'attente qui clignoterait se lirait
  /// comme une alerte.
  bool get isInProgress => this == inProgress;
}
