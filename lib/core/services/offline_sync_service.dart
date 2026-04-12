import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';

/// Cola de operaciones offline — garantiza que fichajes se registran sin conexión.
/// Almacena en flutter_secure_storage y sincroniza cuando hay red.
class OfflineSyncService {
  OfflineSyncService._();

  static const _storage = FlutterSecureStorage();
  static const _queueKey = 'cosecha_offline_queue';
  static StreamSubscription? _connectivitySub;

  /// Inicializar — escuchar cambios de conectividad.
  static void initialize() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        processQueue();
      }
    });
  }

  /// Dispose.
  static void dispose() {
    _connectivitySub?.cancel();
  }

  /// Verificar si hay conexión.
  static Future<bool> hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  /// Añadir operación a la cola offline.
  static Future<void> enqueue(OfflineOperation operation) async {
    final queue = await _getQueue();
    queue.add(operation.toJson());
    await _saveQueue(queue);
    debugPrint('[OfflineSync] Operación encolada: ${operation.table}/${operation.type}');
  }

  /// Procesar cola — enviar operaciones pendientes.
  static Future<void> processQueue() async {
    final queue = await _getQueue();
    if (queue.isEmpty) return;

    debugPrint('[OfflineSync] Procesando ${queue.length} operaciones pendientes...');

    final failed = <Map<String, dynamic>>[];

    for (final opJson in queue) {
      final op = OfflineOperation.fromJson(opJson);
      try {
        switch (op.type) {
          case 'insert':
            await SupabaseService.client.from(op.table).insert(op.data);
            break;
          case 'update':
            if (op.id != null) {
              await SupabaseService.client
                  .from(op.table)
                  .update(op.data)
                  .eq('id', op.id!);
            }
            break;
        }
        debugPrint('[OfflineSync] OK: ${op.table}/${op.type}');
      } catch (e) {
        debugPrint('[OfflineSync] Error: $e — reintentará');
        final retries = (opJson['retries'] as int?) ?? 0;
        if (retries < AppConstants.syncRetryMaxAttempts) {
          opJson['retries'] = retries + 1;
          failed.add(opJson);
        } else {
          debugPrint('[OfflineSync] Máximo de reintentos alcanzado, descartando');
        }
      }
    }

    await _saveQueue(failed);
    if (failed.isEmpty) {
      debugPrint('[OfflineSync] Cola vacía — todo sincronizado');
    }
  }

  /// Obtener número de operaciones pendientes.
  static Future<int> pendingCount() async {
    final queue = await _getQueue();
    return queue.length;
  }

  static Future<List<Map<String, dynamic>>> _getQueue() async {
    final raw = await _storage.read(key: _queueKey);
    if (raw == null || raw.isEmpty) return [];
    return (json.decode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    await _storage.write(key: _queueKey, value: json.encode(queue));
  }
}

/// Operación individual offline.
class OfflineOperation {
  final String table;
  final String type; // 'insert' | 'update'
  final Map<String, dynamic> data;
  final String? id;
  final DateTime createdAt;

  OfflineOperation({
    required this.table,
    required this.type,
    required this.data,
    this.id,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'table': table,
        'type': type,
        'data': data,
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'retries': 0,
      };

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      table: json['table'] as String,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      id: json['id'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
