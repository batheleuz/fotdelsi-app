import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import '../../domain/entities/agent_queue.dart';
import '../../domain/entities/drop_off.dart';
import '../../domain/entities/laundry_type.dart';
import '../models/drop_off_model.dart';

/// Source distante REST des dépôts (espace agent / admin).
class DropOffApiDataSource {
  const DropOffApiDataSource(this._dio);

  final Dio _dio;

  Future<AgentQueue> getQueue({String? day}) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.dropOffQueue,
      queryParameters: day != null ? {'day': day} : null,
    );
    final data = (resp.data?['data'] as Map<String, dynamic>?) ?? const {};

    List<DropOff> parse(String key) => ((data[key] as List?) ?? const [])
        .map((e) => DropOffModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return AgentQueue(
      received: parse('received'),
      inProgress: parse('inProgress'),
      ready: parse('ready'),
    );
  }

  /// `POST /drop-offs/draft` — crée le brouillon (linge + client + montant) et
  /// retourne son `draftId`. L'agentId est déduit du JWT côté backend.
  Future<String> createDraft({
    required String contactPhone,
    required String customerName,
    required int amount,
    required int pieces,
    required List<LaundryType> types,
    String? instructions,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.dropOffDraft,
      data: {
        'contactPhone': contactPhone,
        'customerName': customerName,
        'amount': amount,
        'laundry': {
          'pieces': pieces,
          'types': types.map((t) => t.apiValue).toList(),
          if (instructions != null && instructions.isNotEmpty)
            'instructions': instructions,
        },
      },
    );
    final data = (resp.data?['data'] as Map<String, dynamic>?) ?? const {};
    return data['draftId'] as String;
  }

  /// `GET /me/dropoffs` — historique des dépôts du client lié.
  Future<List<DropOff>> getMyDropOffs() async {
    final resp = await _dio.get<Map<String, dynamic>>(ApiEndpoints.myDropOffs);
    final data = (resp.data?['data'] as List?) ?? const [];
    return data
        .map((e) => DropOffModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DropOff> getById(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>(ApiEndpoints.dropOff(id));
    return DropOffModel.fromJson(
      (resp.data?['data'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Future<DropOff> getByCode(String code, {String? day}) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.dropOffByCode(code),
      queryParameters: day != null ? {'day': day} : null,
    );
    return DropOffModel.fromJson(
      (resp.data?['data'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Future<void> assignMachine(String id, String machineId) async {
    await _dio.post<dynamic>(
      ApiEndpoints.dropOffAssignMachine(id),
      data: {'machineId': machineId},
    );
  }

  Future<void> markReady(String id) async {
    await _dio.post<dynamic>(ApiEndpoints.dropOffMarkReady(id));
  }

  Future<void> markCollected(String id) async {
    await _dio.post<dynamic>(ApiEndpoints.dropOffMarkCollected(id));
  }

  Future<void> updateLaundry(
    String id, {
    required int pieces,
    required List<LaundryType> types,
    String? instructions,
  }) async {
    await _dio.put<dynamic>(
      ApiEndpoints.dropOffLaundry(id),
      data: {
        'laundry': {
          'pieces': pieces,
          'types': types.map((t) => t.apiValue).toList(),
          if (instructions != null && instructions.isNotEmpty)
            'instructions': instructions,
        },
      },
    );
  }
}
