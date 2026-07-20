import 'package:bloc/bloc.dart';

import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/domain/repositories/machine_repository.dart';
import '../utils/qr_payload_parser.dart';
import 'scan_event.dart';
import 'scan_state.dart';

/// Bloc du scanner QR.
///
/// Reçoit le contenu brut d'un QR (ou une saisie manuelle), extrait le
/// `deviceName` via [QrPayloadParser], puis résout la machine via
/// [MachineRepository.getMachineByDeviceName].
class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc(this._repository) : super(const ScanState()) {
    on<ScanQrDetected>(_onQrDetected);
    on<ScanReset>(_onReset);
  }

  final MachineRepository _repository;

  Future<void> _onQrDetected(
    ScanQrDetected event,
    Emitter<ScanState> emit,
  ) async {
    final result = QrPayloadParser.parse(event.raw);
    if (result == null) {
      emit(state.copyWith(
        status: ScanStatus.error,
        error: 'Code QR invalide.',
      ));
      return;
    }

    emit(state.copyWith(status: ScanStatus.processing));

    final either = await _repository.getMachineByDeviceName(result.deviceName);
    either.fold(
      (failure) => emit(state.copyWith(
        status: ScanStatus.error,
        // Un 404 remonte le libellé générique « Ressource introuvable » : sans
        // valeur ici. Dans le contexte du scan, on dit ce que ça signifie.
        error: failure is NotFoundFailure
            ? 'QR code non reconnu : il ne correspond à aucune machine FOTDELSI. '
                'Vérifiez que vous scannez bien le code collé sur la machine.'
            : failure.message,
      )),
      (machine) {
        // Vérification disponibilité avant de laisser passer vers le paiement.
        final availabilityError = _checkAvailability(machine);
        if (availabilityError != null) {
          emit(state.copyWith(
            status: ScanStatus.error,
            error: availabilityError,
          ));
        } else {
          emit(state.copyWith(
            status: ScanStatus.success,
            machine: machine,
          ));
        }
      },
    );
  }

  void _onReset(ScanReset event, Emitter<ScanState> emit) {
    emit(const ScanState());
  }

  /// Retourne un message d'erreur si la machine n'est pas disponible,
  /// `null` si tout est bon.
  String? _checkAvailability(Machine machine) => switch (machine.status) {
        MachineStatus.available => null,
        MachineStatus.inUse => 'Cette machine est déjà en cours d\'utilisation.',
        MachineStatus.offline => 'Cette machine est hors ligne.',
      };
}
