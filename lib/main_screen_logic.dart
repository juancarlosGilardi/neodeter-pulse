import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../src/connection/db.dart';
import '../src/services/qr_scanner_service.dart';
import 'package:logger/logger.dart';

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

      // Escanear QR con cámara
      final qrCode = await QRScannerService.scanQRCode(context);

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
    onLoading(true);
    onStatusMessage('Procesando marcación...');

    if (_userEmail.isEmpty || _userDni.isEmpty || _userRuc.isEmpty) {
      if (context.mounted) {
        _showErrorDialog('Error', 'Por favor, complete su registro.');
      }
      onLoading(false);
      return;
    }

    try {
      // Validación de RUC: Verificar que el QR pertenezca a la empresa del usuario
      if (!_validateQRRuc(qrCode)) {
        throw Exception(
            'El código QR no pertenece a su empresa (RUC: $_userRuc)');
      }

      onStatusMessage('Registrando marcación...');

      // LLAMADA DIRECTA SIN REINTENTOS AUTOMÁTICOS
      await DatabaseService.processMarking(
        userName: _userName,
        userEmail: _userEmail,
        userDni: _userDni,
        qrCode: qrCode,
        marcationType: marcationType,
        context: context,
      );

      if (context.mounted) {
        _showSuccessDialog(
            'Éxito', 'Marcación de $marcationType registrada correctamente.');
      }
      await fetchTodayMarkings();
    } catch (e) {
      _logger.e('Error procesando QR: $e');
      if (context.mounted) {
        // MOSTRAR DIÁLOGO DE REINTENTO MANUAL
        await _showRetryDialog(e.toString(), marcationType, qrCode);
      }
    } finally {
      onLoading(false);
      onStatusMessage('');
    }
  }

  // NUEVO: Diálogo de reintento manual
  Future<void> _showRetryDialog(String error, String marcationType, String qrCode) async {
    if (!context.mounted) return;

    final shouldRetry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('Grabación Falló'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              const Text('¿Desea reintentar la marcación?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Reintentar'),
            ),
          ],
        );
      },
    );

    if (shouldRetry == true) {
      // Reintentar manualmente
      await processQRCode(qrCode, marcationType);
    }
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
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
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