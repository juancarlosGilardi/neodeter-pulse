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

  // Información de la aplicación
  static const String appName = 'Neo Deter SAC - Sistema de Marcaciones';
  static const String appVersion = '1.2.0';
  static const String companyName = 'Neo Deter SAC';

  static bool validateConfig() => apiBaseUrl.isNotEmpty;
}
