import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/failures.dart';
import '../entities/agent_queue.dart';
import '../entities/drop_off.dart';
import '../entities/laundry_type.dart';

/// Contrat domaine des dépôts (espace agent / admin).
abstract interface class DropOffRepository {
  /// `GET /drop-offs/queue?day=` — file d'attente groupée par statut.
  /// [day] au format `YYYY-MM-DD` ; par défaut, le jour courant côté backend.
  Future<Either<Failure, AgentQueue>> getQueue({String? day});

  /// `POST /drop-offs/draft` — crée le brouillon, retourne son `draftId`.
  Future<Either<Failure, String>> createDraft({
    required String contactPhone,
    required String customerName,
    required int amount,
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
