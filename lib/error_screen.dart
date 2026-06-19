// lib/error_screen.dart — Pantalla de Error (dirección Pulse)
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'registro.dart' show PulseButton;
import 'src/theme/pulse_theme.dart';

class ErrorScreen extends StatefulWidget {
  final String titulo;
  final String detalle;

  const ErrorScreen({
    super.key,
    this.titulo = 'No pudimos leer el QR',
    required this.detalle,
  });

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.bgDeep2,
      body: PulseBackground(
        gradient: PulseGradients.errorBg,
        glowColor: const Color(0x33E5484D),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              children: [
                const Spacer(),
                _heroCross(),
                const SizedBox(height: 30),
                Text(widget.titulo,
                    textAlign: TextAlign.center,
                    style: PulseText.archivo(
                        size: 26, weight: FontWeight.w900, spacing: -0.4)),
                const SizedBox(height: 6),
                Text(widget.detalle,
                    textAlign: TextAlign.center,
                    style: PulseText.nunito(
                        size: 14,
                        weight: FontWeight.w700,
                        height: 1.45,
                        color: PulseColors.redLight)),
                const SizedBox(height: 26),
                _aviso(),
                const Spacer(),
                PulseButton(
                  label: 'REINTENTAR',
                  gradient: PulseBrand.actionGradient,
                  shadow: PulseBrand.actionShadow,
                  leading: const Icon(Icons.refresh, size: 19, color: Colors.white),
                  onTap: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 11),
                PulseButton(
                  label: 'Volver al inicio',
                  color: Colors.transparent,
                  textColor: PulseColors.textMuted4,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroCross() {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        // zig-zag amortiguado
        final dx = math.sin(t * math.pi * 5) * 8 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Container(
        width: 112,
        height: 112,
        decoration: const BoxDecoration(
          gradient: PulseGradients.errorCircle,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Color(0x66E5484D),
                blurRadius: 36,
                offset: Offset(0, 16)),
          ],
        ),
        child: const Icon(Icons.close, size: 56, color: Colors.white),
      ),
    );
  }

  Widget _aviso() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PulseColors.redPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PulseColors.red.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: PulseColors.redLight),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Acerca la cámara y evita reflejos. Si el problema sigue, avisa a tu supervisor.',
              style: PulseText.nunito(
                  size: 12.5,
                  weight: FontWeight.w700,
                  height: 1.45,
                  color: const Color(0xFFD9A6A8)),
            ),
          ),
        ],
      ),
    );
  }
}
