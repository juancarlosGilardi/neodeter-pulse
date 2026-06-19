import 'package:logger/logger.dart';

/// Resultado de validación de horario
class ScheduleValidationResult {
  final bool isValid;
  final String message;
  final bool hasSchedule;

  const ScheduleValidationResult({
    required this.isValid,
    required this.message,
    this.hasSchedule = false,
  });

  factory ScheduleValidationResult.success(String message) {
    return ScheduleValidationResult(
      isValid: true,
      message: message,
      hasSchedule: false,
    );
  }

  factory ScheduleValidationResult.error(String message) {
    return ScheduleValidationResult(
      isValid: false,
      message: message,
      hasSchedule: false,
    );
  }
}

/// Servicio de validación de horarios - DESHABILITADO
class ScheduleValidationService {
  static final Logger _logger = Logger();

  /// VALIDACIÓN DESHABILITADA - Siempre permite marcación libre
  static Future<ScheduleValidationResult> validateMarcation({
    required String email,
    required String marcationType,
    required DateTime marcationTime,
  }) async {
    _logger.i('Validación de horario DESHABILITADA - permitiendo marcación libre');
    _logger.i('Email: ${email.mask()}, Tipo: $marcationType');
    
    return ScheduleValidationResult.success(
      'Marcación permitida - validación de horario deshabilitada'
    );
  }

  /// Método para obtener información del horario asignado (deshabilitado)
  static Future<Map<String, dynamic>?> getHorarioInfo(int horarioId) async {
    _logger.i('getHorarioInfo deshabilitado - ID: $horarioId');
    return null;
  }

  /// Verificar si tabla 'horarios' existe (deshabilitado) 
  static Future<bool> checkHorariosTableExists() async {
    _logger.i('Verificación de tabla horarios deshabilitada');
    return false;
  }

  /// Verificar si el servicio está habilitado
  static bool get isEnabled => false;

  /// Obtener estado del servicio
  static Map<String, dynamic> getServiceStatus() {
    return {
      'enabled': false,
      'reason': 'Validación de horario deshabilitada por configuración',
      'allows_all_marcations': true,
      'validation_mode': 'disabled',
    };
  }

  /// Método para habilitar validación en el futuro (placeholder)
  static Future<void> enableValidation() async {
    _logger.w('enableValidation llamado pero no implementado');
    throw UnimplementedError('Validación de horario no implementada');
  }

  /// Método para deshabilitar validación (placeholder)
  static Future<void> disableValidation() async {
    _logger.i('Validación de horario ya está deshabilitada');
  }
}

/// Extensión para enmascarar datos sensibles en logs
extension StringMask on String {
  String mask() {
    if (length <= 4) return '***';
    return '${substring(0, 2)}***${substring(length - 2)}';
  }
}