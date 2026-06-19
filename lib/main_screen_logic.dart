import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../src/connection/db.dart';
import '../src/services/qr_scanner_service.dart';
import 'package:logger/logger.dart';

import 'exito_screen.dart';
import 'error_screen.dart';
import 'src/theme/pulse_theme.dart';
import 'src/utils/pulse_format.dart';

class MainScreenLogic {
  final BuildContext context;
  final Function(String) onQrResult;
  final Function(bool) onLoading;
  final Function(String) onStatusMessage;
  final Function(List<Map<String, dynamic>>) onTodayMarkingsUpdated;
  final Function(String, String, String, String)
      onUserDataLoaded; // Nombre, Email, DNI, RUC
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final Logger _logger = Logger();

  // Datos del usuario
  String _userName = '';
  String _userEmail = '';
  String _userDni = '';
  String _userRuc = '';

  MainScreenLogic({
    required this.context,
    required this.onQrResult,
    required this.onLoading,
    required this.onStatusMessage,
    required this.onTodayMarkingsUpdated,
    required this.onUserDataLoaded,
  });

  void dispose() {
    // No hay recursos que liberar en esta versión
  }

  Future<void> loadUserData() async {
    onLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('userName') ?? '';
      _userEmail = prefs.getString('userEmail') ?? '';
      _userDni = prefs.getString('userDni') ?? '';
      _userRuc = prefs.getString('userRuc') ?? '';

      onUserDataLoaded(_userName, _userEmail, _userDni, _userRuc);
      _logger.i(
          'Datos de usuario cargados: $_userName, $_userEmail, $_userDni, $_userRuc');
    } catch (e) {
      _logger.e('Error cargando datos de usuario: $e');
      if (context.mounted) {
        _showSnackBar('Error cargando datos de usuario: $e', isError: true);
      }
    } finally {
      onLoading(false);
    }
  }

  Future<void> scanQRAndMark(String marcationType) async {
    try {
      onLoading(true);
      onStatusMessage('Abriendo cámara...');

      // Verificar datos de usuario
      if (_userEmail.isEmpty || _userDni.isEmpty || _userRuc.isEmpty) {
        _showErrorDialog(
            'Error', 'Por favor, complete su registro antes de marcar.');
        return;
      }

      // Escanear QR con cámara (subtítulo = tipo de marcación en curso)
      final qrCode = await QRScannerService.scanQRCode(context,
          subtitle: marcacionLabel(marcationType));

      if (qrCode == null) {
        onStatusMessage('Escaneo cancelado');
        return;
      }

      _logger.i('QR escaneado: $qrCode');
      onQrResult(qrCode);

      // Procesar marcación - SIN REINTENTOS AUTOMÁTICOS
      await processQRCode(qrCode, marcationType);
    } catch (e) {
      _logger.e('Error en scan y marcación: $e');
      if (context.mounted) {
        _showErrorDialog('Error', 'Error procesando QR: $e');
      }
    } finally {
      onLoading(false);
      onStatusMessage('');
    }
  }

  Future<void> processQRCode(String qrCode, String marcationType) async {
    if (_userEmail.isEmpty || _userDni.isEmpty || _userRuc.isEmpty) {
      if (context.mounted) {
        _showErrorDialog('Error', 'Por favor, complete su registro.');
      }
      return;
    }

    bool success = false;
    String? errMsg;

    onLoading(true);
    onStatusMessage('Procesando marcación...');
    try {
      // Validación de RUC: el QR debe pertenecer a la empresa del usuario.
      if (!_validateQRRuc(qrCode)) {
        throw Exception(
            'El código QR no pertenece a tu empresa (RUC: $_userRuc).');
      }

      onStatusMessage('Registrando marcación...');
      await DatabaseService.processMarking(
        userName: _userName,
        userEmail: _userEmail,
        userDni: _userDni,
        qrCode: qrCode,
        marcationType: marcationType,
        context: context,
      );
      success = true;
    } catch (e) {
      _logger.e('Error procesando QR: $e');
      errMsg = e.toString();
    } finally {
      onLoading(false);
      onStatusMessage('');
    }

    if (!context.mounted) return;

    if (success) {
      await _showExito(marcationType);
      await fetchTodayMarkings();
    } else {
      final retry = await _showError(errMsg ?? 'No se pudo registrar.');
      if (retry == true) {
        await scanQRAndMark(marcationType);
      }
    }
  }

  // Pantalla completa de Éxito.
  Future<void> _showExito(String marcationType) async {
    if (!context.mounted) return;
    final hora = formatHora(LimaTimeHelper.formatTimeForDB());
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExitoScreen(
          tipoLabel: marcacionLabel(marcationType),
          hora: hora,
          sincronizado: true,
        ),
      ),
    );
  }

  // Pantalla completa de Error. Devuelve true si el usuario pide reintentar.
  Future<bool?> _showError(String rawMessage) {
    final detalle = _cleanError(rawMessage);
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ErrorScreen(detalle: detalle),
      ),
    );
  }

  String _cleanError(String raw) {
    var m = raw.replaceFirst('Exception: ', '').trim();
    if (m.isEmpty) {
      m = 'El código no se reconoció o no corresponde a esta oficina. '
          'Vuelve a intentarlo.';
    }
    return m;
  }

  bool _validateQRRuc(String qrCode) {
    try {
      final parts = qrCode.split('|');
      if (parts.isEmpty) return false;

      final qrRuc = parts[0].trim();
      final userRuc = _userRuc.trim();

      if (userRuc.isEmpty) {
        _logger.w('Usuario sin RUC configurado');
        return false;
      }

      final matches = qrRuc == userRuc;
      if (!matches) {
        _logger.w('RUC no coincide. QR: $qrRuc, Usuario: $userRuc');
      }

      return matches;
    } catch (e) {
      _logger.e('Error validando RUC del QR: $e');
      return false;
    }
  }

  Future<void> fetchTodayMarkings() async {
    if (_userEmail.isEmpty) {
      onTodayMarkingsUpdated([]);
      return;
    }

    onLoading(true);
    onStatusMessage('Cargando marcaciones del día...');
    try {
      final todayMarkings = await DatabaseService.getTodayMarkings(_userEmail);
      onTodayMarkingsUpdated(todayMarkings);
      _logger.i('Marcaciones del día actualizadas: $todayMarkings');
    } catch (e) {
      _logger.e('Error al obtener marcaciones del día: $e');
      if (context.mounted) {
        _showSnackBar('Error al cargar marcaciones del día: $e', isError: true);
      }
      onTodayMarkingsUpdated([]);
    } finally {
      onLoading(false);
      onStatusMessage('');
    }
  }

  Future<void> checkConnectivityAndSyncOffline() async {
    onStatusMessage('Verificando conectividad...');
    onLoading(true);
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        onStatusMessage('Sin conexión a Internet.');
        return;
      }

      final status = await DatabaseService.checkConnectivity();
      if (context.mounted) {
        _showSnackBar(status.message, isError: !status.canReachServer);
      }

      if (status.canReachServer) {
        onStatusMessage('Sincronización completada.');
        await fetchTodayMarkings();
      }
    } catch (e) {
      _logger.e('Error en checkConnectivityAndSyncOffline: $e');
      if (context.mounted) {
        _showSnackBar('Error de conectividad o sincronización: $e',
            isError: true);
      }
    } finally {
      onLoading(false);
      onStatusMessage('');
    }
  }

  // Métodos de UI
  void _showSnackBar(String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? PulseColors.red : PulseColors.greenGrad2,
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PulseColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: PulseText.archivo(size: 17, weight: FontWeight.w800)),
        content: Text(message,
            style: PulseText.nunito(
                size: 14,
                weight: FontWeight.w600,
                color: PulseColors.textMuted3)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Ok',
                style: PulseText.nunito(
                    size: 14,
                    weight: FontWeight.w800,
                    color: PulseColors.accentBlue)),
          )
        ],
      ),
    );
  }

  void pauseCamera() {
    // No implementado en esta versión
  }

  void resumeCamera() {
    // No implementado en esta versión
  }
}