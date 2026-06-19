// lib/src/connection/db.dart — Capa de datos vía backend HTTP (compatible web).
// El navegador no puede usar MySQL ni SMTP: toda la persistencia y el correo
// pasan por el backend (ver lib/src/services/api_service.dart y /backend).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../services/api_service.dart';

/// HELPER PARA ZONA HORARIA DE LIMA
class LimaTimeHelper {
  static DateTime getLimaTime() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.subtract(const Duration(hours: 5));
  }

  static String formatDateForDB() {
    final t = getLimaTime();
    return "${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}";
  }

  static String formatTimeForDB() {
    final t = getLimaTime();
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}";
  }

  static String formatDateTime() => "${formatDateForDB()} ${formatTimeForDB()}";
}

/// ESTADO DE CONECTIVIDAD
class ConnectivityStatus {
  final bool hasInternet;
  final bool canReachServer;
  final String message;
  final DateTime timestamp;
  final int latencyMs;
  final String quality;

  ConnectivityStatus({
    required this.hasInternet,
    required this.canReachServer,
    required this.message,
    required this.timestamp,
    this.latencyMs = 0,
  }) : quality = _calculateQuality(latencyMs);

  static String _calculateQuality(int latencyMs) {
    if (latencyMs == 0) return 'Unknown';
    if (latencyMs < 1000) return 'Excelente';
    if (latencyMs < 2000) return 'Buena';
    if (latencyMs < 5000) return 'Regular';
    return 'Lenta';
  }
}

/// DATOS DEL QR
class QRData {
  final String ruc;
  final String area;
  final int establecimientoId;
  final double? latitude;
  final double? longitude;
  final String? additionalInfo;

  const QRData({
    required this.ruc,
    required this.area,
    required this.establecimientoId,
    this.latitude,
    this.longitude,
    this.additionalInfo,
  });
}

/// EXCEPCIONES
class ValidationException implements Exception {
  final String message;
  final String? field;
  ValidationException(this.message, {this.field});
  @override
  String toString() => message;
}

class BusinessLogicException implements Exception {
  final String message;
  final String? context;
  BusinessLogicException(this.message, {this.context});
  @override
  String toString() => message;
}

/// SERVICIO PRINCIPAL DE DATOS (ahora vía backend)
class DatabaseService {
  static final Logger _logger = Logger();

  static String? _deviceIdCache;
  static DateTime? _deviceIdCacheTime;
  static const Duration _cacheValidDuration = Duration(hours: 24);

  /// VERIFICAR CONECTIVIDAD (al backend/BD)
  static Future<ConnectivityStatus> checkConnectivity() async {
    final h = await ApiService.health();
    return ConnectivityStatus(
      hasInternet: h.canReachServer,
      canReachServer: h.canReachServer,
      message: h.message,
      timestamp: DateTime.now(),
      latencyMs: h.latencyMs,
    );
  }

  /// ID único del dispositivo (cacheado)
  static Future<String> getDeviceId() async {
    if (_deviceIdCache != null &&
        _deviceIdCacheTime != null &&
        DateTime.now().difference(_deviceIdCacheTime!) < _cacheValidDuration) {
      return _deviceIdCache!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString('deviceId');
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = const Uuid().v4();
        await prefs.setString('deviceId', deviceId);
      }
      _deviceIdCache = deviceId;
      _deviceIdCacheTime = DateTime.now();
      return deviceId;
    } catch (e) {
      return 'temp_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Ubicación actual (best-effort; en web requiere HTTPS y permiso del navegador)
  static Future<loc.LocationData?> getCurrentLocation() async {
    final location = loc.Location();
    try {
      bool serviceEnabled =
          await location.serviceEnabled().timeout(const Duration(seconds: 2));
      if (!serviceEnabled) {
        serviceEnabled =
            await location.requestService().timeout(const Duration(seconds: 5));
        if (!serviceEnabled) return null;
      }

      loc.PermissionStatus permission =
          await location.hasPermission().timeout(const Duration(seconds: 2));
      if (permission == loc.PermissionStatus.denied) {
        permission = await location
            .requestPermission()
            .timeout(const Duration(seconds: 8));
        if (permission != loc.PermissionStatus.granted) return null;
      }

      // changeSettings puede no estar soportado en web: no debe ser fatal.
      try {
        await location.changeSettings(
          accuracy: loc.LocationAccuracy.high,
          interval: 1000,
          distanceFilter: 0,
        );
      } catch (_) {}

      final data = await location.getLocation().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Timeout ubicación'),
          );

      if (data.latitude == null || data.longitude == null) return null;
      if (data.latitude == 0.0 && data.longitude == 0.0) return null;
      return data;
    } catch (e) {
      _logger.w('No se pudo obtener ubicación: $e');
      return null;
    }
  }

  /// PROCESO PRINCIPAL DE MARCACIÓN (vía backend)
  static Future<void> processMarking({
    required String userName,
    required String userEmail,
    required String userDni,
    required String qrCode,
    required String marcationType,
    BuildContext? context,
  }) async {
    _validateInputParameters(userName, userEmail, userDni, qrCode, marcationType);

    // Ubicación (con valor por defecto: Lima centro)
    double latitude = -12.046374;
    double longitude = -77.042793;
    final locationData = await getCurrentLocation();
    if (locationData != null) {
      latitude = locationData.latitude!;
      longitude = locationData.longitude!;
    }

    final qrData = _parseAndValidateQR(qrCode);
    final deviceId = await getDeviceId();

    await ApiService.marcar(
      userName: userName,
      userEmail: userEmail,
      userDni: userDni,
      marcationType: marcationType,
      latitude: latitude,
      longitude: longitude,
      deviceId: deviceId,
      ruc: qrData.ruc,
      area: qrData.area,
      establecimientoId: qrData.establecimientoId,
    );
  }

  /// Marcaciones del día (devuelve 0 o 1 fila con las 4 horas)
  static Future<List<Map<String, dynamic>>> getTodayMarkings(
      String email) async {
    try {
      final m = await ApiService.getTodayMarkings(email);
      return [m];
    } catch (e) {
      _logger.e('Error obteniendo marcaciones del día: $e');
      return [];
    }
  }

  static Future<bool> checkDatabaseHealth() async {
    final h = await ApiService.health();
    return h.canReachServer;
  }

  static Future<void> dispose() async {
    _deviceIdCache = null;
    _deviceIdCacheTime = null;
  }

  // ---- Validaciones (lógica pura) ----

  static void _validateInputParameters(
    String userName,
    String userEmail,
    String userDni,
    String qrCode,
    String marcationType,
  ) {
    final trimmedName = userName.trim();
    if (trimmedName.isEmpty) {
      throw ValidationException('El nombre de usuario no puede estar vacío',
          field: 'userName');
    }
    if (trimmedName.length < 2) {
      throw ValidationException('El nombre debe tener al menos 2 caracteres',
          field: 'userName');
    }

    final trimmedEmail = userEmail.trim().toLowerCase();
    final emailRegex = RegExp(r'^[\w.+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      throw ValidationException('Email no válido', field: 'userEmail');
    }

    final trimmedDni = userDni.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(trimmedDni)) {
      throw ValidationException(
          'DNI debe contener exactamente 8 dígitos numéricos',
          field: 'userDni');
    }
    const invalidDnis = ['00000000', '11111111', '12345678', '87654321'];
    if (invalidDnis.contains(trimmedDni)) {
      throw ValidationException('DNI no válido', field: 'userDni');
    }

    final trimmedQr = qrCode.trim();
    if (trimmedQr.isEmpty || trimmedQr.length < 10) {
      throw ValidationException('Código QR no válido', field: 'qrCode');
    }

    const validTypes = [
      'Ingreso',
      'Inicio de Refrigerio',
      'Salida de Refrigerio',
      'Salida'
    ];
    if (!validTypes.contains(marcationType)) {
      throw ValidationException('Tipo de marcación no válido: $marcationType',
          field: 'marcationType');
    }
  }

  static QRData _parseAndValidateQR(String qrCode) {
    final parts = qrCode.trim().split('|');
    if (parts.length < 7) {
      throw ValidationException(
          'Código QR no tiene el formato esperado (faltan campos)',
          field: 'qrCode');
    }

    final ruc = parts[0].trim();
    final area = parts[1].trim();
    final establecimientoIdStr = parts[4].trim();

    if (ruc.isEmpty || !RegExp(r'^\d{11}$').hasMatch(ruc)) {
      throw ValidationException('RUC en código QR no válido', field: 'ruc');
    }
    if (area.isEmpty || area.length > 50) {
      throw ValidationException('Área en código QR no válida', field: 'area');
    }

    final establecimientoId = int.tryParse(establecimientoIdStr);
    if (establecimientoId == null || establecimientoId <= 0) {
      throw ValidationException(
          'ID de establecimiento en código QR no válido',
          field: 'establecimientoId');
    }

    double? latitude, longitude;
    final geoParts = parts[3].trim().split(',');
    if (geoParts.length >= 2) {
      latitude = double.tryParse(geoParts[0].trim());
      longitude = double.tryParse(geoParts[1].trim());
    }

    return QRData(
      ruc: ruc,
      area: area,
      establecimientoId: establecimientoId,
      latitude: latitude,
      longitude: longitude,
      additionalInfo: parts.length > 7 ? parts.sublist(7).join('|') : null,
    );
  }
}
