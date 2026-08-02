import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/failures.dart';

/// Contrat domaine de l'identité client (liaison du numéro par OTP SMS).
abstract interface class ClientAuthRepository {
  /// `POST /me/link-phone/start` — démarre la liaison. Selon la config serveur :
  ///  - OTP requis → renvoie `null` (l'app demande le code) ;
  ///  - liaison directe → session persistée localement, renvoie le numéro lié.
  Future<Either<Failure, String?>> startLink(String phone);

  /// `POST /me/link-phone/request-otp` — envoie un code OTP par SMS (renvoi).
  Future<Either<Failure, void>> requestOtp(String phone);

  /// `POST /me/link-phone/verify-otp` — vérifie le code, persiste la session
  /// client localement, et retourne le numéro lié.
  Future<Either<Failure, String>> verifyOtp({
    required String phone,
    required String code,
  });

  /// Numéro lié stocké localement (`null` si non lié).
  Future<String?> linkedPhone();

  /// Délie le numéro : révoque côté backend (best-effort) et purge le stockage.
  Future<void> unlink();
}
