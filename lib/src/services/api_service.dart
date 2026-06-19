// lib/src/services/api_service.dart — Cliente HTTP del backend de marcaciones.
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Excepción de API con un mensaje listo para mostrar al usuario.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Estado de salud del backend/BD.
class HealthStatus {
  final bool canReachServer;
  final String message;
  final int latencyMs;
  HealthStatus({
    required this.canReachServer,
    required this.message,
    this.latencyMs = 0,
  });
}

class ApiService {
  static String get _base => AppConfig.apiBaseUrl;

  /// Registrar una marcación. Lanza [ApiException] con el mensaje del servidor
  /// (p. ej. "Ya ha marcado su ingreso...") si la regla de negocio falla.
  static Future<void> marcar({
    required String userName,
    required String userEmail,
    required String userDni,
    required String marcationType,
    required double latitude,
    required double longitude,
    required String deviceId,
    required String ruc,
    required String area,
    required int establecimientoId,
    String? fecha,
    String? hora,
  }) async {
    final uri = Uri.parse('$_base/marcar');
    final body = <String, dynamic>{
      'userName': userName,
      'userEmail': userEmail,
      'userDni': userDni,
      'marcationType': marcationType,
      'latitude': latitude,
      'longitude': longitude,
      'deviceId': deviceId,
      'ruc': ruc,
      'area': area,
      'establecimientoId': establecimientoId,
    };
    if (fecha != null) body['fecha'] = fecha;
    if (hora != null) body['hora'] = hora;

    http.Response resp;
    try {
      resp = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(AppConfig.connectionTimeout);
    } catch (_) {
      throw ApiException(
          'No se pudo conectar con el servidor. Verifica tu conexión a Internet.');
    }

    if (resp.statusCode == 200) return;

    throw ApiException(_extractDetail(resp), statusCode: resp.statusCode);
  }

  /// Marcaciones del día del usuario. Devuelve un mapa con
  /// horaentrada / horaRefrigerioInicio / horaRefrigerioFin / horasalida.
  static Future<Map<String, dynamic>> getTodayMarkings(String email) async {
    final uri = Uri.parse(
        '$_base/marcaciones-hoy?email=${Uri.encodeQueryComponent(email)}');
    final resp = await http.get(uri).timeout(AppConfig.connectionTimeout);
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    }
    throw ApiException(_extractDetail(resp), statusCode: resp.statusCode);
  }

  /// Verifica si el backend (y la BD) están accesibles.
  static Future<HealthStatus> health() async {
    final uri = Uri.parse('$_base/health');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final m = jsonDecode(resp.body) as Map<String, dynamic>;
        return HealthStatus(
          canReachServer: m['canReachServer'] == true,
          message: (m['message'] ?? '').toString(),
          latencyMs: m['latencyMs'] is int ? m['latencyMs'] as int : 0,
        );
      }
      return HealthStatus(
          canReachServer: false,
          message: 'Servidor no disponible (${resp.statusCode})');
    } catch (_) {
      return HealthStatus(
          canReachServer: false, message: 'Sin conexión con el servidor');
    }
  }

  static String _extractDetail(http.Response resp) {
    try {
      final m = jsonDecode(resp.body);
      if (m is Map && m['detail'] != null) return m['detail'].toString();
    } catch (_) {}
    return 'Error del servidor (${resp.statusCode})';
  }
}
