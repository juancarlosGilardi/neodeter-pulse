// main_screen.dart — Estado y orquestación de la pantalla principal (Pulse)
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'src/connection/db.dart';
import 'src/theme/pulse_theme.dart';
import 'main_screen_ui.dart';
import 'main_screen_logic.dart';

var logger = Logger();

class IntegratedMainScreen extends StatefulWidget {
  const IntegratedMainScreen({super.key});

  @override
  IntegratedMainScreenState createState() => IntegratedMainScreenState();
}

class IntegratedMainScreenState extends State<IntegratedMainScreen> {
  late MainScreenLogic _mainScreenLogic;

  String? userName;
  String? userEmail;
  String? userDni;
  String? userRuc;
  bool _isLoading = false;
  String _statusMessage = '';

  Map<String, String?> todayMarkings = {
    'ingreso': null,
    'refrigerioInicio': null,
    'refrigerioFin': null,
    'salida': null,
  };

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
        setState(() => _isLoading = isLoading);
      },
      onStatusMessage: (message) {
        setState(() => _statusMessage = message);
      },
      onTodayMarkingsUpdated: (markings) {
        setState(() {
          todayMarkings = {
            'ingreso': markings.isNotEmpty ? markings[0]['horaentrada'] : null,
            'refrigerioInicio':
                markings.isNotEmpty ? markings[0]['horaRefrigerioInicio'] : null,
            'refrigerioFin':
                markings.isNotEmpty ? markings[0]['horaRefrigerioFin'] : null,
            'salida': markings.isNotEmpty ? markings[0]['horasalida'] : null,
          };
        });
      },
      onUserDataLoaded: (name, email, dni, ruc) {
        setState(() {
          userName = name;
          userEmail = email;
          userDni = dni;
          userRuc = ruc;
        });
        _mainScreenLogic.fetchTodayMarkings();
      },
    );

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _mainScreenLogic.loadUserData();
    await _checkDatabaseConnection();
  }

  @override
  void dispose() {
    _isDatabaseConnected.dispose();
    _connectionQuality.dispose();
    _mainScreenLogic.dispose();
    super.dispose();
  }

  Future<void> _checkDatabaseConnection() async {
    _isDatabaseConnected.value = null;
    final status = await DatabaseService.checkConnectivity();
    _isDatabaseConnected.value = status.canReachServer;
    _connectionQuality.value = status.quality;
  }

  Future<void> _scanAndMark(String marcationType) async {
    await _mainScreenLogic.scanQRAndMark(marcationType);
  }

  Future<void> _reloadUserData() async {
    await _mainScreenLogic.loadUserData();
  }

  void _onRegistrationComplete() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil creado'),
          backgroundColor: PulseColors.greenGrad2,
          duration: Duration(seconds: 2),
        ),
      );
    }
    await _reloadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildMainUI(
          context,
          userName: userName,
          userEmail: userEmail,
          userDni: userDni,
          userRuc: userRuc,
          todayMarkings: todayMarkings,
          isDatabaseConnected: _isDatabaseConnected,
          connectionQuality: _connectionQuality,
          onScanAndMark: _scanAndMark,
          onCheckConnection: _checkDatabaseConnection,
          onRegistrationComplete: _onRegistrationComplete,
        ),
        if (_isLoading) _loadingOverlay(),
      ],
    );
  }

  Widget _loadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PulseColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PulseColors.borderBlue(0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: PulseColors.accentBlue),
              if (_statusMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: PulseText.nunito(
                      size: 15,
                      weight: FontWeight.w700,
                      color: PulseColors.textWhite),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
