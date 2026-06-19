import 'package:flutter/foundation.dart';

/// Configuración de la app. El acceso a datos y el correo se hacen a través
/// del backend (API REST), no directamente a MySQL/SMTP. Así funciona en web.
class AppConfig {
  // Entorno
  static const bool isDevelopment =
      bool.fromEnvironment('DEVELOPMENT', defaultValue: kDebugMode);
  static const bool isProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: !kDebugMode);

  /// URL base del backend (FastAPI). Configúrala al compilar:
  ///   flutter build web --dart-define=API_BASE=https://tu-backend.com
  /// En desarrollo, por defecto apunta a http://localhost:8000.
  static String apiBaseUrl = const String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:8000',
  );

  // Configuración de ubicación
  static const double locationToleranceMeters = 100.0;
  static const int locationTimeoutSeconds =
      int.fromEnvironment('LOCATION_TIMEOUT', defaultValue: 10);

  // Timeouts de red
  static const int connectionTimeoutSeconds =
      int.fromEnvironment('CONNECTION_TIMEOUT', defaultValue: 15);

  static const Duration connectionTimeout =
      Duration(seconds: connectionTimeoutSeconds);
  static const Duration locationTimeout =
      Duration(seconds: locationTimeoutSeconds);

  // ── Configuración por empresa (tenant) ────────────────────────────────
  // Cada despliegue se personaliza al compilar con --dart-define. Los valores
  // por defecto corresponden al despliegue actual, así nada se rompe si no se
  // pasan. Ejemplo:
  //   flutter build web --dart-define=COMPANY_RUC=20XXXXXXXXX \
  //     --dart-define=APP_NAME="ACME ACCESO" --dart-define=BRAND_ACTION=1D9E75
  //
  /// RUC de la empresa. El QR de la puerta debe coincidir con este RUC.
  static const String companyRuc =
      String.fromEnvironment('COMPANY_RUC', defaultValue: '20101162282');

  /// Texto de marca que se muestra en el encabezado del tablero.
  static const String wordmark =
      String.fromEnvironment('APP_NAME', defaultValue: 'SIAPP ACCESO');

  /// Nombre de la empresa/producto (título de la app, correos, etc.).
  static const String companyName =
      String.fromEnvironment('COMPANY_NAME', defaultValue: 'SIAPP-Acceso');

  /// Color de acento (hex sin '#'). Por defecto el azul Pulse.
  static const String brandAccentHex =
      String.fromEnvironment('BRAND_ACCENT', defaultValue: '3A86E0');

  /// Color de acción principal/botones (hex sin '#'). Por defecto el grana Pulse.
  static const String brandActionHex =
      String.fromEnvironment('BRAND_ACTION', defaultValue: 'A50044');

  static const String appName = '$companyName · Sistema de marcaciones';
  static const String appVersion = '1.2.0';

  static bool validateConfig() => apiBaseUrl.isNotEmpty;
}
