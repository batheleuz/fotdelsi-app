/// Statut d'un dépôt — miroir de la machine à états backend.
///
/// `RECEIVED → IN_PROGRESS → READY → COLLECTED` (flux nominal),
/// `LOST` / `REFUNDED` étant des états terminaux d'exception.
enum DropOffStatus {
  received,
  inProgress,
  ready,
  collected,
  lost,
  refunded;

  static DropOffStatus fromApi(String value) => switch (value) {
        'RECEIVED' => received,
        'IN_PROGRESS' => inProgress,
        'READY' => ready,
        'COLLECTED' => collected,
        'LOST' => lost,
        'REFUNDED' => refunded,
        _ => received,
      };

  bool get isTerminal =>
      this == collected || this == lost || this == refunded;
}
