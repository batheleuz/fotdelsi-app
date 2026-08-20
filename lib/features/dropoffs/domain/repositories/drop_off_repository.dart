import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/failures.dart';
import '../entities/agent_queue.dart';
import '../entities/drop_off.dart';
import '../entities/drop_off_history_page.dart';
import '../entities/pending_drop_off_payment.dart';
import '../entities/laundry_type.dart';

/// Contrat domaine des dépôts (espace agent / admin).
abstract interface class DropOffRepository {
  /// `GET /drop-offs/queue?day=` — file d'attente groupée par statut.
  /// [day] au format `YYYY-MM-DD` ; par défaut, le jour courant côté backend.
  Future<Either<Failure, AgentQueue>> getQueue({String? day});

  /// `GET /drop-offs/handoffs` — remises payées en attente du linge.
  Future<Either<Failure, List<DropOff>>> getHandoffs();

  /// Historique complet, paginé — tous les jours, tous les statuts.
  ///
  /// Distinct de [getQueue], qui ne montre que le jour courant et les statuts
  /// actifs : un dépôt rendu la veille en disparaît, et avec lui le numéro du
  /// client qu'un agent peut vouloir rappeler.
  Future<Either<Failure, DropOffHistoryPage>> getHistory({
    int? limit,
    int? offset,
  });

  /// `GET /drop-offs/pending-payment` — dépôts saisis, pas encore encaissés.
  Future<Either<Failure, List<PendingDropOffPayment>>> getPendingPayments();

  /// `POST /drop-offs/draft` — crée le brouillon, retourne son `draftId`.
  /// Crée le brouillon de dépôt. Aucun montant n'est transmis : le serveur le
  /// calcule depuis la grille à partir de (formule, capacité).
  Future<Either<Failure, String>> createDraft({
    required String contactPhone,
    required String customerName,
    required String formulaCode,
    required int sizeKg,
    required int pieces,
    required List<LaundryType> types,
    String? instructions,
  });

  /// `GET /me/dropoffs` — historique des dépôts du client lié.
  Future<Either<Failure, List<DropOff>>> getMyDropOffs();

  /// `GET /me/dropoffs/:id` — détail d'un dépôt du client lié
  /// ([NotFoundFailure] si introuvable ou n'appartenant pas au client).
  Future<Either<Failure, DropOff>> getMyDropOffById(String id);

  /// `GET /drop-offs/:id`.
  Future<Either<Failure, DropOff>> getById(String id);

  /// `GET /drop-offs/by-code/:code?day=` — recherche par code court.
  /// Renvoie [NotFoundFailure] si introuvable pour ce jour.
  Future<Either<Failure, DropOff>> getByCode(String code, {String? day});

  /// `POST /drop-offs/:id/assign-machine` — lance le lavage sur [machineId].
  Future<Either<Failure, void>> assignMachine(String id, String machineId);

  /// `POST /drop-offs/:id/start-drying` — lance le séchage sur une sécheuse.
  Future<Either<Failure, void>> startDrying(String id, String dryerMachineId);

  /// `POST /drop-offs/:id/receive` — le client apporte son linge déjà lavé.
  Future<Either<Failure, void>> receiveHandoff(String id);

  /// `POST /drop-offs/:id/mark-ready` — marque prêt (fallback manuel).
  Future<Either<Failure, void>> markReady(String id);

  /// `POST /drop-offs/:id/mark-collected` — remise au client.
  Future<Either<Failure, void>> markCollected(String id);

  /// `PUT /drop-offs/:id/laundry` — modifie la description du linge.
  Future<Either<Failure, void>> updateLaundry(
    String id, {
    required int pieces,
    required List<LaundryType> types,
    String? instructions,
  });
}
