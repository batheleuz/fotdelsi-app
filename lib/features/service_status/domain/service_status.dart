import 'package:equatable/equatable.dart';

/// Un service critique momentanément indisponible + son message utilisateur.
class ServiceWarning extends Equatable {
  const ServiceWarning({required this.key, required this.message});

  /// MACHINES | WAVE | ORANGE_MONEY
  final String key;
  final String message;

  @override
  List<Object?> get props => [key, message];
}

/// État de disponibilité renvoyé par `GET /status`.
class ServiceStatus {
  const ServiceStatus(this.warnings);

  final List<ServiceWarning> warnings;

  static const Map<String, String> _defaults = {
    'MACHINES':
        'Les machines sont momentanément injoignables. Réessayez dans un instant.',
    'WAVE': 'Le paiement par Wave est temporairement indisponible.',
    'ORANGE_MONEY':
        'Le paiement par Orange Money est temporairement indisponible.',
  };

  /// Parse `{ services: { MACHINES: {available, message}, ... } }` en ne
  /// retenant que les services indisponibles.
  factory ServiceStatus.fromJson(Map<String, dynamic> data) {
    final services = data['services'];
    final warnings = <ServiceWarning>[];
    if (services is Map) {
      services.forEach((key, value) {
        if (value is Map && value['available'] == false) {
          final k = key.toString();
          final message = (value['message'] as String?) ??
              _defaults[k] ??
              'Service temporairement indisponible.';
          warnings.add(ServiceWarning(key: k, message: message));
        }
      });
    }
    return ServiceStatus(warnings);
  }
}
