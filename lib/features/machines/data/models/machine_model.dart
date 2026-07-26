import '../../domain/entities/machine.dart';

/// DTO de la couche data : mappe le JSON de `GET /machines` vers l'entité.
class MachineModel {
  const MachineModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.status,
    required this.price,
    this.size,
    required this.remainTime,
  });

  final String id;
  final String code;
  final String name;
  final MachineType type;
  final MachineStatus status;
  final int remainTime;
  final int price;
  final int? size;

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      id: json['id'].toString(),
      code: json['code'] as String,
      name: json['name'] as String,
      type: _type(json['type'] as String?),
      status: _status(json['status'] as String?),
      remainTime: (json['remain_time'] as num?)?.toInt() ?? 0,
      price: json['price'] as int,
      size: json['size'] as int?
    );
  }

  Machine toEntity() => Machine(
        id: id,
        code: code,
        name: name,
        type: type,
        status: status,
        remainTime: remainTime,
        price: price.toDouble(),
        size: size,
      );

  static MachineType _type(String? value) =>
      value == 'SECHEUSE' ? MachineType.dryer : MachineType.washer;

  static MachineStatus _status(String? value) => switch (value) {
        'AVAILABLE' => MachineStatus.available,
        'IN_USE' => MachineStatus.inUse,
        _ => MachineStatus.offline,
      };
}
