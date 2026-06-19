// main_screen.dart - CON RUC Y QR SCANNER REAL
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../src/connection/db.dart';
import 'main_screen_ui.dart';
import 'main_screen_logic.dart';

var logger = Logger();

class IntegratedMainScreen extends StatefulWidget {
  const IntegratedMainScreen({super.key});

  @override
  IntegratedMainScreenState createState() => IntegratedMainScreenState();
}

class IntegratedMainScreenState extends State<IntegratedMainScreen> {
  // Instancia de MainScreenLogic
  late MainScreenLogic _mainScreenLogic;

  // Estado básico
  String? userName;
  String? userEmail;
  String? userDni;
  String? userRuc; // ✅ AGREGADO RUC
  AppTheme currentTheme = AppTheme.energetic;
  bool _isLoading = false; // ✅ ESTADO DE LOADING GLOBAL
  String _statusMessage = ''; // ✅ MENSAJE DE ESTADO
  
  Map<String, String?> todayMarkings = {
    'ingreso': null,
    'refrigerioInicio': null,
    'refrigerioFin': null,
    'salida': null,
  };

  // ValueNotifiers para la conexión
  final ValueNotifier<bool?> _isDatabaseConnected = ValueNotifier<bool?>(null);
  final ValueNotifier<String?> _connectionQuality = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _mainScreenLogic = MainScreenLogic(
      context: context,
      onQrResult: (qrCode) {
        logger.i('QR escaneado: $qrCode');
      },
      onLoading: (isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
        logger.i('Loading: $isLoading');
      },
      onStatusMessage: (message) {
        setState(() {
          _statusMessage = message;
        });
        logger.i('Status: $message');
      },
      onTodayMarkingsUpdated: (markings) {
        setState(() {
          todayMarkings = {
            'ingreso': markings.isNotEmpty ? markings[0]['horaentrada'] : null,
            'refrigerioInicio': markings.isNotEmpty ? markings[0]['horaRefrigerioInicio'] : null,
            'refrigerioFin': markings.isNotEmpty ? markings[0]['horaRefrigerioFin'] : null,
            'salida': markings.isNotEmpty ? markings[0]['horasalida'] : null,
          };
        });
        logger.i('Marcaciones del día actualizadas: $markings');
      },
      onUserDataLoaded: (name, email, dni, ruc) { // ✅ AGREGADO RUC
        setState(() {
          userName = name;
          userEmail = email;
          userDni = dni;
          userRuc = ruc; // ✅ ASIGNAR RUC
        });
        logger.i('Datos de usuario cargados: $name, $email, $dni, $ruc');
        _mainScreenLogic.fetchTodayMarkings();
      },
    );

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _mainScreenLogic.loadUserData();
    await _loadTheme();
    await _checkDatabaseConnection();
  }

  @override
  void dispose() {
    _isDatabaseConnected.dispose();
    _connectionQuality.dispose();
    _mainScreenLogic.dispose();
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('appTheme') ?? 'energetic';
    setState(() {
      currentTheme = AppTheme.values.firstWhere(
        (e) => e.toString() == 'AppTheme.$themeName',
        orElse: () => AppTheme.energetic,
      );
    });
  }

  Future<void> _checkDatabaseConnection() async {
    final status = await DatabaseService.checkConnectivity();
    _isDatabaseConnected.value = status.canReachServer;
    _connectionQuality.value = status.message;
  }

  // ✅ MÉTODO ACTUALIZADO: Usar scanner QR real
  Future<void> _scanAndMark(String marcationType) async {
    await _mainScreenLogic.scanQRAndMark(marcationType);
  }

  // Método para recargar datos del usuario después del registro
  Future<void> _reloadUserData() async {
    logger.i('🔄 Recargando datos del usuario después del registro...');
    await _mainScreenLogic.loadUserData();
  }

  // Callback de registro completado
  void _onRegistrationComplete() async {
    logger.i('✅ Registro completado, recargando datos...');
    
    // Mostrar mensaje de éxito
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Datos guardados exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    // Recargar datos para cambiar a la pantalla de marcaciones
    await _reloadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pantalla principal
        buildMainUI(
          context,
          currentTheme,
          userName,
          userEmail,
          userDni,
          userRuc, // ✅ PASAR RUC
          todayMarkings,
          _isDatabaseConnected,
          _connectionQuality,
          onScanAndMark: _scanAndMark,
          onChangeTheme: (theme) => setState(() => currentTheme = theme),
          onCheckConnection: _checkDatabaseConnection,
          onRegistrationComplete: _onRegistrationComplete,
        ),
        
        // ✅ OVERLAY DE LOADING MINIMALISTA
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF4ECDC4),
                    ),
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}