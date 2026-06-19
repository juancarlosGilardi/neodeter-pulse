// lib/src/services/qr_scanner_service.dart — Escáner QR (dirección visual "Pulse")
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

import '../theme/pulse_theme.dart';

class QRScannerService {
  static final Logger _logger = Logger();

  /// Abre la cámara y devuelve el texto del QR (o null si se cancela).
  /// [subtitle] muestra el tipo de marcación en curso (p. ej. "Fin de refrigerio").
  static Future<String?> scanQRCode(BuildContext context,
      {String? subtitle}) async {
    try {
      final cameraPermission = await _requestCameraPermission();
      if (!cameraPermission) {
        if (context.mounted) _showPermissionDialog(context);
        return null;
      }

      if (!context.mounted) return null;

      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => QRScannerScreen(subtitle: subtitle),
        ),
      );

      return result;
    } catch (e) {
      _logger.e('Error en scanner QR: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error abriendo scanner: $e'),
            backgroundColor: PulseColors.red,
          ),
        );
      }
      return null;
    }
  }

  static Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) return true;
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
          backgroundColor: PulseColors.panel,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.photo_camera_outlined,
                  color: PulseColors.amber),
              const SizedBox(width: 10),
              Text('Permisos de cámara',
                  style: PulseText.archivo(size: 17, weight: FontWeight.w800)),
            ],
          ),
          content: Text(
            'La app necesita la cámara para escanear códigos QR.\n\n'
            'Habilita los permisos de cámara en la configuración.',
            style: PulseText.nunito(
                size: 14,
                weight: FontWeight.w600,
                color: PulseColors.textMuted3),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar',
                  style: PulseText.nunito(
                      size: 14,
                      weight: FontWeight.w800,
                      color: PulseColors.textMuted3)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.blue600),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Configuración',
                  style: PulseText.nunito(
                      size: 14, weight: FontWeight.w800, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  final String? subtitle;
  const QRScannerScreen({super.key, this.subtitle});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController controller;
  late final AnimationController _scan;
  bool _isScanning = true;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    _scan = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scan.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.bgScanner,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          child: Column(
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Escanea el QR',
                            style: PulseText.archivo(
                                size: 20,
                                weight: FontWeight.w900,
                                spacing: -0.2)),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(widget.subtitle!,
                              style: PulseText.nunito(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: PulseColors.textMuted)),
                        ],
                      ],
                    ),
                  ),
                  _iconButton(
                    icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                    onTap: _toggleFlash,
                  ),
                  const SizedBox(width: 10),
                  _iconButton(icon: Icons.close, onTap: () => Navigator.pop(context)),
                ],
              ),
              const Spacer(),
              // Visor
              _viewfinder(),
              const SizedBox(height: 34),
              Text('Apunta la cámara al QR',
                  style:
                      PulseText.archivo(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text('Se escanea automáticamente, sin tocar nada.',
                  textAlign: TextAlign.center,
                  style: PulseText.nunito(
                      size: 13,
                      weight: FontWeight.w700,
                      height: 1.4,
                      color: PulseColors.textMuted)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PulseColors.borderBlue(0.25)),
        ),
        child: Icon(icon, size: 19, color: PulseColors.textMuted3),
      ),
    );
  }

  Widget _viewfinder() {
    const box = 252.0;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Feed de cámara recortado
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: box,
              height: box,
              child: MobileScanner(
                controller: controller,
                onDetect: _handleQRScanned,
              ),
            ),
          ),
          // Línea de escaneo
          if (_isScanning)
            AnimatedBuilder(
              animation: _scan,
              builder: (context, _) {
                final dy = (_scan.value * 2 - 1) * 84;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Container(
                    width: box - 44,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(colors: [
                        Color(0x003A86E0),
                        PulseColors.accentBlue,
                        Color(0x003A86E0),
                      ]),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0xB33A86E0),
                            blurRadius: 14,
                            spreadRadius: 2),
                      ],
                    ),
                  ),
                );
              },
            ),
          // Brackets en las esquinas
          ..._brackets(box),
          // Overlay de procesando
          if (!_isScanning)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: box,
                height: box,
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: PulseColors.accentBlue),
                      SizedBox(height: 16),
                      Text('Procesando…',
                          style: TextStyle(color: Colors.white, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _brackets(double box) {
    const len = 46.0;
    const w = 4.0;
    const color = PulseColors.accentBlue;
    BorderSide side() => const BorderSide(color: color, width: w);
    return [
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: len,
          height: len,
          decoration: BoxDecoration(
            border: Border(top: side(), left: side()),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: len,
          height: len,
          decoration: BoxDecoration(
            border: Border(top: side(), right: side()),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(24)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: len,
          height: len,
          decoration: BoxDecoration(
            border: Border(bottom: side(), left: side()),
            borderRadius:
                const BorderRadius.only(bottomLeft: Radius.circular(24)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: len,
          height: len,
          decoration: BoxDecoration(
            border: Border(bottom: side(), right: side()),
            borderRadius:
                const BorderRadius.only(bottomRight: Radius.circular(24)),
          ),
        ),
      ),
    ];
  }

  void _handleQRScanned(BarcodeCapture capture) {
    if (!_isScanning) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final qrCode = barcodes.first.rawValue;
    if (qrCode == null || qrCode.isEmpty) return;

    setState(() => _isScanning = false);
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
          backgroundColor: PulseColors.panel,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: PulseColors.red),
              const SizedBox(width: 10),
              Text('QR inválido',
                  style: PulseText.archivo(size: 17, weight: FontWeight.w800)),
            ],
          ),
          content: Text(
            'El código QR no tiene el formato esperado.',
            style: PulseText.nunito(
                size: 14,
                weight: FontWeight.w600,
                color: PulseColors.textMuted3),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Cancelar',
                  style: PulseText.nunito(
                      size: 14,
                      weight: FontWeight.w800,
                      color: PulseColors.textMuted3)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.blue600),
              onPressed: () {
                Navigator.of(context).pop();
                _restartScanning();
              },
              child: Text('Reintentar',
                  style: PulseText.nunito(
                      size: 14, weight: FontWeight.w800, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _restartScanning() {
    setState(() => _isScanning = true);
    controller.start();
  }

  void _toggleFlash() {
    controller.toggleTorch();
    setState(() => _flashOn = !_flashOn);
  }
}
