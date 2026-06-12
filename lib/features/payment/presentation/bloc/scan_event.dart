import 'package:equatable/equatable.dart';

sealed class ScanEvent extends Equatable {
  const ScanEvent();

  @override
  List<Object?> get props => [];
}

/// QR détecté par la caméra (contenu brut).
final class ScanQrDetected extends ScanEvent {
  const ScanQrDetected(this.raw);

  final String raw;

  @override
  List<Object?> get props => [raw];
}

/// Réinitialise le scanner après succès ou erreur.
final class ScanReset extends ScanEvent {
  const ScanReset();
}
