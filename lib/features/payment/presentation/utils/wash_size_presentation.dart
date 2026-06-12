import '../../domain/entities/wash_program.dart';

/// Libellés présentation des tailles de lavage.
extension WashSizeX on WashSize {
  String get label => switch (this) {
        WashSize.kg12 => 'Lavage 12 kg',
        WashSize.kg15 => 'Lavage 15 kg',
        WashSize.kg20 => 'Lavage 20 kg',
      };
}
