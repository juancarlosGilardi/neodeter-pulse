// lib/src/services/offline_service.dart - VERSIÓN COMPATIBLE WEB/MOBILE
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

/// 🗃️ SERVICIO DE ALMACENAMIENTO OFFLINE UNIVERSAL
class OfflineService {
  static const String _storageKey = 'neodeter_offline_markings';
  static final Logger _logger = Logger();

  /// ✅ FUNCIÓN PRINCIPAL: Guardar marcación offline (compatible web/mobile)
  static Future<void> saveOffline({
    required String userName,
    required String userEmail,
    required String userDni,
    required String qrCode,
    required String marcationType,
    required double latitude,
    required double longitude,
    required String deviceId,
  }) async {
    try {
      // Usar zona horaria de Lima (UTC-5)
      final limaTime = _getLimaTime();
      final fechaMarcacion = _formatDateLima(limaTime);
      final horaMarcacion = _formatTimeLima(limaTime);

      // Parsear datos del QR
      final qrData = _parseQR(qrCode);

      final marcation = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'fullname': userName,
        'email': userEmail,
        'dni': userDni,
        'marcation_type': marcationType,
        'qr_code': qrCode,
        'latitude': latitude,
        'longitude': longitude,
        'device_id': deviceId,
        'establecimiento_id': qrData?['establecimientoId'] ?? 1,
        'ruc': qrData?['ruc'] ?? '',
        'area': qrData?['area'] ?? '',
        'fecha_marcacion': fechaMarcacion,
        'hora_marcacion': horaMarcacion,
        'created_at': DateTime.now().toIso8601String(),
        'is_synced': false,
        'sync_attempts': 0,
        'error_message': null,
      };

      // Obtener marcaciones existentes
      final existingMarkings = await _getStoredMarkings();
      existingMarkings.add(marcation);

      // Guardar en SharedPreferences (funciona en web y mobile)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(existingMarkings));

      _logger.i('💾 Marcación offline guardada con ID: ${marcation['id']}');
      _logger.i('   📧 Email: $userEmail');
      _logger.i('   🕐 Hora Lima: $horaMarcacion');
    } catch (e) {
      _logger.e('❌ Error guardando offline: $e');
      rethrow;
    }
  }

  /// Obtener marcaciones pendientes de sincronizar
  static Future<List<Map<String, dynamic>>> getPendingMarcations() async {
    try {
      final markings = await _getStoredMarkings();
      final pending = markings.where((marking) => 
        marking['is_synced'] == false && 
        (marking['sync_attempts'] ?? 0) < 3
      ).toList();

      _logger.i('📊 Marcaciones pendientes: ${pending.length}');
      return pending;
    } catch (e) {
      _logger.e('❌ Error obteniendo pendientes: $e');
      return [];
    }
  }

  /// Marcar marcación como sincronizada
  static Future<void> markAsSynced(String id) async {
    try {
      final markings = await _getStoredMarkings();
      final index = markings.indexWhere((m) => m['id'] == id);
      
      if (index != -1) {
        markings[index]['is_synced'] = true;
        await _saveMarkings(markings);
        _logger.i('✅ Marcación $id marcada como sincronizada');
      }
    } catch (e) {
      _logger.e('❌ Error marcando como sincronizada: $e');
    }
  }

  /// Incrementar intentos de sincronización
  static Future<void> incrementSyncAttempts(String id, String errorMessage) async {
    try {
      final markings = await _getStoredMarkings();
      final index = markings.indexWhere((m) => m['id'] == id);
      
      if (index != -1) {
        markings[index]['sync_attempts'] = (markings[index]['sync_attempts'] ?? 0) + 1;
        markings[index]['error_message'] = errorMessage;
        await _saveMarkings(markings);
        _logger.w('⚠️ Incrementados intentos para marcación $id: $errorMessage');
      }
    } catch (e) {
      _logger.e('❌ Error incrementando intentos: $e');
    }
  }

  /// Obtener estadísticas de marcaciones offline
  static Future<Map<String, int>> getStats() async {
    try {
      final markings = await _getStoredMarkings();
      
      final total = markings.length;
      final pending = markings.where((m) => m['is_synced'] == false).length;
      final synced = markings.where((m) => m['is_synced'] == true).length;

      return {
        'total': total,
        'pending': pending,
        'synced': synced,
      };
    } catch (e) {
      _logger.e('❌ Error obteniendo estadísticas: $e');
      return {'total': 0, 'pending': 0, 'synced': 0};
    }
  }

  /// ✅ FUNCIÓN DE UTILIDAD: Reintento de MySQL
  static Future<bool> retryMySQL({
    required String userName,
    required String userEmail,
    required String userDni,
    required String qrCode,
    required String marcationType,
    required double latitude,
    required double longitude,
    required String deviceId,
    required Future<void> Function() mysqlSaveFunction,
  }) async {
    try {
      _logger.i('🔄 Reintentando guardar en MySQL en 10 segundos...');
      await Future.delayed(const Duration(seconds: 10));

      await mysqlSaveFunction();
      _logger.i('✅ Reintento de MySQL exitoso');
      return true;
    } catch (e) {
      _logger.e('❌ Reintento de MySQL falló: $e');

      // Guardar offline como último recurso
      await saveOffline(
        userName: userName,
        userEmail: userEmail,
        userDni: userDni,
        qrCode: qrCode,
        marcationType: marcationType,
        latitude: latitude,
        longitude: longitude,
        deviceId: deviceId,
      );

      return false;
    }
  }

  /// Limpiar marcaciones ya sincronizadas (mantenimiento)
  static Future<void> cleanSyncedMarcations() async {
    try {
      final markings = await _getStoredMarkings();
      
      // Mantener solo las últimas 50 marcaciones sincronizadas
      final syncedMarkings = markings.where((m) => m['is_synced'] == true).toList();
      final pendingMarkings = markings.where((m) => m['is_synced'] == false).toList();
      
      // Ordenar por fecha y mantener solo las más recientes
      syncedMarkings.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
      final recentSynced = syncedMarkings.take(50).toList();
      
      // Combinar pendientes con las sincronizadas recientes
      final cleanedMarkings = [...pendingMarkings, ...recentSynced];
      
      await _saveMarkings(cleanedMarkings);
      _logger.i('🧹 Limpieza de marcaciones sincronizadas completada');
    } catch (e) {
      _logger.e('❌ Error en limpieza: $e');
    }
  }

  // ===================================================================
  // MÉTODOS PRIVADOS DE ALMACENAMIENTO
  // ===================================================================

  static Future<List<Map<String, dynamic>>> _getStoredMarkings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('❌ Error leyendo marcaciones: $e');
      return [];
    }
  }

  static Future<void> _saveMarkings(List<Map<String, dynamic>> markings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(markings));
    } catch (e) {
      _logger.e('❌ Error guardando marcaciones: $e');
      rethrow;
    }
  }

  // ===================================================================
  // FUNCIONES DE UTILIDAD PARA ZONA HORARIA DE LIMA
  // ===================================================================

  /// Obtener hora actual de Lima (UTC-5)
  static DateTime _getLimaTime() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.subtract(const Duration(hours: 5));
  }

  /// Formatear fecha para base de datos (DD/MM/YYYY)
  static String _formatDateLima(DateTime limaTime) {
    return "${limaTime.day.toString().padLeft(2, '0')}/${limaTime.month.toString().padLeft(2, '0')}/${limaTime.year}";
  }

  /// Formatear hora para base de datos (HH:MM:SS)
  static String _formatTimeLima(DateTime limaTime) {
    return "${limaTime.hour.toString().padLeft(2, '0')}:${limaTime.minute.toString().padLeft(2, '0')}:${limaTime.second.toString().padLeft(2, '0')}";
  }

  /// Parsear datos del QR
  static Map<String, dynamic>? _parseQR(String qrCode) {
    try {
      final parts = qrCode.split('|');
      if (parts.length < 7) return null;

      return {
        'ruc': parts[0].trim(),
        'area': parts[1].trim(),
        'establecimientoId': int.tryParse(parts[4].trim()) ?? 1,
      };
    } catch (e) {
      return null;
    }
  }

  /// Test de funcionalidad
  static Future<void> runTest() async {
    try {
      _logger.i('🧪 Iniciando test de OfflineService...');

      // Test guardar offline
      await saveOffline(
        userName: 'Test Usuario',
        userEmail: 'test@neodeter.com',
        userDni: '12345678',
        qrCode: '20123456789|Test Area|-12.0464,-77.0428|-12.0464,-77.0428|1|activo|Admin',
        marcationType: 'Ingreso',
        latitude: -12.0464,
        longitude: -77.0428,
        deviceId: 'test_device',
      );

      // Test estadísticas
      final stats = await getStats();
      _logger.i('📊 Estadísticas de test:');
      _logger.i('   Total: ${stats['total']}');
      _logger.i('   Pendientes: ${stats['pending']}');
      _logger.i('   Sincronizadas: ${stats['synced']}');

      // Test obtener pendientes
      final pending = await getPendingMarcations();
      _logger.i('📋 Marcaciones pendientes: ${pending.length}');

      _logger.i('✅ Test completado exitosamente');
    } catch (e) {
      _logger.e('❌ Error en test: $e');
    }
  }

  /// Limpiar todos los datos (para testing)
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _logger.i('🧹 Todos los datos offline eliminados');
    } catch (e) {
      _logger.e('❌ Error limpiando datos: $e');
    }
  }

  /// Información de la plataforma actual
  static String getPlatformInfo() {
    if (kIsWeb) {
      return 'Web - usando SharedPreferences con almacenamiento del navegador';
    } else {
      return 'Mobile/Desktop - usando SharedPreferences con almacenamiento local';
    }
  }
}