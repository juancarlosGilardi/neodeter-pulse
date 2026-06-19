// lib/src/services/qr_scanner_service.dart - SCANNER SIMPLIFICADO Y SIN ERRORES
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class QRScannerService {
  static final Logger _logger = Logger();

  static Future<String?> scanQRCode(BuildContext context) async {
    try {
      final cameraPermission = await _requestCameraPermission();
      if (!cameraPermission) {
        if (context.mounted) {
          _showPermissionDialog(context);
        }
        return null;
      }

      if (!context.mounted) return null;

      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(),
        ),
      );

      return result;
    } catch (e) {
      _logger.e('Error en scanner QR: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error abriendo scanner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  static Future<bool> _requestCameraPermission() async {
    // En web, el navegador solicita el permiso de cámara al iniciar el escaneo
    // (mobile_scanner llama a getUserMedia). permission_handler no aplica.
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        final result = await Permission.camera.request();
        return result.isGranted;
      }
      
      return false;
    } catch (e) {
      _logger.e('Error solicitando permisos: $e');
      return false;
    }
  }

  static void _showPermissionDialog(BuildContext context) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.orange),
              SizedBox(width: 10),
              Text('Permisos de Cámara'),
            ],
          ),
          content: const Text(
            'La aplicación necesita acceso a la cámara para escanear códigos QR.\n\n'
            'Por favor, habilita los permisos de cámara en la configuración.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Configuración'),
            ),
          ],
        );
      },
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _isScanning = true;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Escanear Código QR'),
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _handleQRScanned,
                ),
                // Overlay simple
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF4ECDC4),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (!_isScanning)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF4ECDC4)),
                          SizedBox(height: 16),
                          Text(
                            'Procesando código QR...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Color(0xFF4ECDC4),
                    size: 40,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Apunta la cámara al código QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'El código se escaneará automáticamente',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleQRScanned(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrCode = barcodes.first.rawValue;
    if (qrCode == null || qrCode.isEmpty) return;

    setState(() {
      _isScanning = false;
    });

    HapticFeedback.mediumImpact();
    controller.stop();

    if (_isValidQRFormat(qrCode)) {
      Navigator.of(context).pop(qrCode);
    } else {
      _showInvalidQRDialog(qrCode);
    }
  }

  bool _isValidQRFormat(String qrCode) {
    try {
      final parts = qrCode.split('|');
      if (parts.length < 6) return false;

      final ruc = parts[0].trim();
      if (!RegExp(r'^\d{11}$').hasMatch(ruc)) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  void _showInvalidQRDialog(String qrCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('Código QR Inválido'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('El código QR no tiene el formato esperado.'),
              const SizedBox(height: 16),
              Text(
                'Código: ${qrCode.length > 50 ? '${qrCode.substring(0, 50)}...' : qrCode}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartScanning();
              },
              child: const Text('Reintentar'),
            ),
          ],
        );
      },
    );
  }

  void _restartScanning() {
    setState(() {
      _isScanning = true;
    });
    controller.start();
  }

  void _toggleFlash() {
    controller.toggleTorch();
    setState(() {
      _flashOn = !_flashOn;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}