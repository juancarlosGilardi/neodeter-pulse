// lib/src/services/sync_service.dart — Sincroniza marcaciones offline vía backend.
import 'dart:async';

import 'package:logger/logger.dart';

import 'api_service.dart';
import 'offline_service.dart';

/// 🔄 SERVICIO DE SINCRONIZACIÓN AUTOMÁTICA
class SyncService {
  static final Logger _logger = Logger();
  static bool _isSyncing = false;
  static Timer? _syncTimer;
  static const Duration _syncInterval = Duration(minutes: 15);

  static Future<void> initialize() async {
    try {
      final stats = await OfflineService.getStats();
      if ((stats['pending'] ?? 0) > 0) {
        await syncPendingMarcations();
        _startPeriodicSync();
      }
    } catch (e) {
      _logger.e('Error inicializando sincronización: $e');
    }
  }

  static void _startPeriodicSync() {
    _stopPeriodicSync();
    _syncTimer = Timer.periodic(_syncInterval, (timer) async {
      final stats = await OfflineService.getStats();
      if ((stats['pending'] ?? 0) > 0) {
        final result = await syncPendingMarcations();
        if (result.success && result.syncedCount > 0) {
          final newStats = await OfflineService.getStats();
          if ((newStats['pending'] ?? 0) == 0) _stopPeriodicSync();
        }
      } else {
        _stopPeriodicSync();
      }
    });
  }

  static void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  static Future<SyncResult> syncPendingMarcations() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sincronización en progreso');
    }
    _isSyncing = true;
    final result = SyncResult();

    try {
      final health = await ApiService.health();
      if (!health.canReachServer) {
        result.success = false;
        result.message = 'Sin conexión con el servidor';
        return result;
      }

      final pending = await OfflineService.getPendingMarcations();
      if (pending.isEmpty) {
        result.success = true;
        result.message = 'No hay marcaciones pendientes';
        return result;
      }

      _logger.i('Sincronizando ${pending.length} marcaciones...');

      for (final m in pending) {
        final id = m['id'] as String;
        try {
          await ApiService.marcar(
            userName: (m['fullname'] as String?) ?? '',
            userEmail: (m['email'] as String?) ?? '',
            userDni: (m['dni'] as String?) ?? '',
            marcationType: (m['marcation_type'] as String?) ?? '',
            latitude: (m['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (m['longitude'] as num?)?.toDouble() ?? 0.0,
            deviceId: (m['device_id'] as String?) ?? '',
            ruc: (m['ruc'] as String?) ?? '',
            area: (m['area'] as String?) ?? '',
            establecimientoId: (m['establecimiento_id'] as num?)?.toInt() ?? 1,
            fecha: m['fecha_marcacion'] as String?,
            hora: m['hora_marcacion'] as String?,
          );
          await OfflineService.markAsSynced(id);
          result.syncedCount++;
        } on ApiException catch (e) {
          // 409 = el servidor indica que ya existe -> darla por sincronizada.
          if (e.statusCode == 409) {
            await OfflineService.markAsSynced(id);
            result.syncedCount++;
          } else {
            await OfflineService.incrementSyncAttempts(id, e.toString());
            result.failedCount++;
          }
        } catch (e) {
          await OfflineService.incrementSyncAttempts(id, e.toString());
          result.failedCount++;
        }
      }

      result.success = true;
      result.message =
          'Sincronización: ${result.syncedCount} exitosas, ${result.failedCount} fallidas';

      if (result.syncedCount > 0) {
        await OfflineService.cleanSyncedMarcations();
      }
    } catch (e) {
      result.success = false;
      result.message = 'Error general en sincronización: $e';
      _logger.e(result.message);
    } finally {
      _isSyncing = false;
    }

    return result;
  }

  static Future<Map<String, dynamic>> getSyncStats() async {
    final offlineStats = await OfflineService.getStats();
    return {
      'totalOffline': offlineStats['total'],
      'pending': offlineStats['pending'],
      'synced': offlineStats['synced'],
      'isSyncing': _isSyncing,
      'autoSyncActive': _syncTimer != null,
      'platform': OfflineService.getPlatformInfo(),
    };
  }

  static Future<SyncResult> forceSyncNow() async {
    final result = await syncPendingMarcations();
    if (result.success) {
      final stats = await OfflineService.getStats();
      if ((stats['pending'] ?? 0) > 0) _startPeriodicSync();
    }
    return result;
  }

  static void dispose() => _stopPeriodicSync();
}

class SyncResult {
  bool success;
  String message;
  int syncedCount = 0;
  int failedCount = 0;

  SyncResult({this.success = false, this.message = ''});

  @override
  String toString() =>
      'SyncResult(success: $success, synced: $syncedCount, failed: $failedCount, message: "$message")';
}
