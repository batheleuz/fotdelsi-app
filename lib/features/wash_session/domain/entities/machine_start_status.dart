/// Statut du démarrage de la machine, dérivé du `sessionStatus` backend.
///
/// Le backend expose le cycle via `sessionStatus`
/// (`PENDING | RUNNING | FAILED | DONE`) ; côté app on le ramène à l'axe
/// « la machine a-t-elle démarré ? » utilisé par l'UI (FAB démarrer / réessayer
/// / session en cours).
enum MachineStartStatus {
  /// Paiement reçu, démarrage pas encore tenté (`PENDING`).
  pending,

  /// Tentative de démarrage échouée (EQLink KO) — l'utilisateur peut réessayer (`FAILED`).
  startFailed,

  /// Machine démarrée / cycle en cours ou terminé (`RUNNING` / `DONE`).
  started;

  /// Mappe la valeur `sessionStatus` du backend.
  static MachineStartStatus fromSessionStatus(String value) => switch (value) {
        'RUNNING' => MachineStartStatus.started,
        'DONE' => MachineStartStatus.started,
        'FAILED' => MachineStartStatus.startFailed,
        _ => MachineStartStatus.pending,
      };
}
