// lib/src/services/platform_service.dart - SERVICIO UNIVERSAL DE PLATAFORMA
import 'package:flutter/foundation.dart';

/// Servicio para manejar diferencias entre plataformas
class PlatformService {
  
  /// Inicializar servicios específicos de la plataforma
  static Future<void> initialize() async {
    if (kIsWeb) {
      await _initializeWeb();
    } else {
      await _initializeMobile();
    }
  }

  /// Inicialización para web
  static Future<void> _initializeWeb() async {
    try {
      print('Inicializando servicios para Web...');
      // En web usamos SharedPreferences que funciona con localStorage
      print('Web: Usando SharedPreferences con localStorage del navegador');
    } catch (e) {
      print('Error inicializando servicios web: $e');
    }
  }

  /// Inicialización para mobile/desktop
  static Future<void> _initializeMobile() async {
    try {
      print('Inicializando servicios para Mobile/Desktop...');
      
      // Solo importar sqflite_ffi en mobile/desktop
      if (!kIsWeb) {
        try {
          // Importación dinámica para evitar errores en web
          final sqfliteFfi = await import('package:sqflite_common_ffi/sqflite_ffi.dart');
          sqfliteFfi.sqfliteFfiInit();
          sqfliteFfi.databaseFactory = sqfliteFfi.databaseFactoryFfi;
          print('Mobile: SQLite FFI inicializado correctamente');
        } catch (e) {
          print('Advertencia: No se pudo inicializar SQLite FFI: $e');
          print('Usando SharedPreferences como alternativa');
        }
      }
    } catch (e) {
      print('Error inicializando servicios mobile: $e');
    }
  }

  /// Verificar si estamos en web
  static bool get isWeb => kIsWeb;
  
  /// Verificar si estamos en mobile
  static bool get isMobile => !kIsWeb;
  
  /// Obtener descripción de la plataforma
  static String get platformDescription {
    if (kIsWeb) {
      return 'Web (${_getBrowserInfo()})';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'iOS';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'Windows Desktop';
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      return 'macOS Desktop';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      return 'Linux Desktop';
    } else {
      return 'Plataforma desconocida';
    }
  }

  /// Obtener información del navegador (solo web)
  static String _getBrowserInfo() {
    if (!kIsWeb) return 'N/A';
    
    // En web, podemos detectar el navegador básico
    if (kDebugMode) {
      return 'Navegador de desarrollo';
    } else {
      return 'Navegador de producción';
    }
  }

  /// Verificar si el almacenamiento offline está disponible
  static bool get isOfflineStorageAvailable {
    // SharedPreferences funciona en todas las plataformas
    return true;
  }

  /// Verificar si SQLite está disponible
  static bool get isSQLiteAvailable {
    return !kIsWeb; // SQLite solo en mobile/desktop
  }

  /// Obtener capacidades de la plataforma
  static Map<String, bool> get platformCapabilities {
    return {
      'offline_storage': isOfflineStorageAvailable,
      'sqlite_database': isSQLiteAvailable,
      'location_services': true, // location package funciona en todas
      'push_notifications': !kIsWeb, // Solo mobile
      'file_system': !kIsWeb, // Solo mobile/desktop
      'background_sync': !kIsWeb, // Solo mobile/desktop
    };
  }

  /// Log de información de la plataforma
  static void logPlatformInfo() {
    print('=== INFORMACIÓN DE PLATAFORMA ===');
    print('Plataforma: $platformDescription');
    print('Es Web: $isWeb');
    print('Es Mobile/Desktop: $isMobile');
    print('Capacidades:');
    platformCapabilities.forEach((key, value) {
      print('  $key: ${value ? "✓" : "✗"}');
    });
    print('================================');
  }
}

/// Importación dinámica segura para sqflite_ffi
dynamic import(String library) {
  throw UnsupportedError('Importación dinámica no soportada en esta plataforma');
}