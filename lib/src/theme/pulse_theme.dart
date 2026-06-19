// lib/src/theme/pulse_theme.dart
// Design tokens de la dirección visual "Pulse" (handoff design_handoff_pulse).
// Paleta azul + grana sobre fondo oscuro tipo command center.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_config.dart';

/// Colores del sistema Pulse.
class PulseColors {
  // Fondos oscuros
  static const bgDeep1 = Color(0xFF0C1A30);
  static const bgDeep2 = Color(0xFF0A1426);
  static const bgDeep3 = Color(0xFF080E1C);
  static const bgScanner = Color(0xFF070C16);

  // Paneles / superficies
  static const panel = Color(0xFF11213F);
  static const panelAlt = Color(0xFF13294B);
  static const panelLogoDark = Color(0xFF0B1A33);

  // Texto
  static const textWhite = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFF6E84A8);
  static const textMuted2 = Color(0xFF7E94B8);
  static const textMuted3 = Color(0xFF8FA3C4);
  static const textMuted4 = Color(0xFFA9B6CC);

  // Acentos azules
  static const accentBlue = Color(0xFF3A86E0);
  static const blue600 = Color(0xFF0A63C2);
  static const blue700 = Color(0xFF004D98);
  static const blueText = Color(0xFFBBD6F5);

  // Grana
  static const garnet = Color(0xFFA50044);
  static const garnetDark = Color(0xFF7A0033);
  static const garnetLight = Color(0xFFE86A95);

  // Ámbar (pendiente / sincronizando local)
  static const amber = Color(0xFFE8990C);
  static const amberLight = Color(0xFFF0B24A);
  static const amberText = Color(0xFFD29A4E);

  // Verde (en vivo / éxito / sincronizado)
  static const green = Color(0xFF37D27E);
  static const greenGrad1 = Color(0xFF2FCB76);
  static const greenGrad2 = Color(0xFF1FA85E);
  static const greenText = Color(0xFF8FE3B4);
  static const greenPanel = Color(0xFF10261C);

  // Rojo (error)
  static const red = Color(0xFFE5484D);
  static const redDark = Color(0xFFB5333A);
  static const redLight = Color(0xFFF0A0A2);
  static const redText = Color(0xFFFF8A8D);
  static const redPanel = Color(0xFF2A1417);

  // Deshabilitado / bloqueado
  static const locked = Color(0xFF5E7196);
  static const lockedText = Color(0xFF54688A);

  /// Borde azul sutil con opacidad variable (rgba(74,148,232, x)).
  static Color borderBlue([double opacity = 0.22]) =>
      const Color(0xFF4A94E8).withValues(alpha: opacity);
}

/// Gradientes del sistema Pulse.
class PulseGradients {
  /// Fondo oscuro de pantalla (180deg).
  static const screenBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PulseColors.bgDeep1, PulseColors.bgDeep2, PulseColors.bgDeep3],
    stops: [0.0, 0.58, 1.0],
  );

  /// Fondo de la pantalla Éxito (verdoso).
  static const successBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A2A1E), PulseColors.bgDeep2, PulseColors.bgDeep3],
    stops: [0.0, 0.55, 1.0],
  );

  /// Fondo de la pantalla Error (rojizo).
  static const errorBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A0E12), PulseColors.bgDeep2, PulseColors.bgDeep3],
    stops: [0.0, 0.55, 1.0],
  );

  /// Botón / acción grana (120deg).
  static const garnetAction = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PulseColors.garnet, PulseColors.garnetDark],
  );

  /// Acción azul (120deg).
  static const blueAction = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PulseColors.blue600, PulseColors.blue700],
  );

  /// Logo / monograma (145deg).
  static const logo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PulseColors.panelAlt, PulseColors.panelLogoDark],
  );

  /// Círculo de éxito (145deg).
  static const successCircle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PulseColors.greenGrad1, PulseColors.greenGrad2],
  );

  /// Círculo de error (145deg).
  static const errorCircle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PulseColors.red, PulseColors.redDark],
  );

  /// Glow radial azul superior.
  static const blueGlow = RadialGradient(
    colors: [Color(0x333A86E0), Color(0x003A86E0)],
  );
}

/// Colores de marca configurables por despliegue (--dart-define BRAND_ACCENT /
/// BRAND_ACTION). Con los valores por defecto reproduce exactamente la paleta
/// Pulse; si se sobreescriben, deriva los degradados a partir del color dado.
class PulseBrand {
  static final Color accent =
      _parse(AppConfig.brandAccentHex, PulseColors.accentBlue);
  static final Color action =
      _parse(AppConfig.brandActionHex, PulseColors.garnet);

  static final bool _accentDefault = accent == PulseColors.accentBlue;
  static final bool _actionDefault = action == PulseColors.garnet;

  /// Tono claro de la acción (hora de las marcas registradas).
  static final Color actionLight =
      _actionDefault ? PulseColors.garnetLight : _lighten(action, 0.22);

  /// Texto suave sobre la fila activa.
  static final Color accentSoft =
      _accentDefault ? PulseColors.blueText : _lighten(accent, 0.32);

  static final LinearGradient actionGradient = _actionDefault
      ? PulseGradients.garnetAction
      : _grad(action, _darken(action, 0.18));

  static final LinearGradient accentGradient = _accentDefault
      ? PulseGradients.blueAction
      : _grad(_darken(accent, 0.06), _darken(accent, 0.30));

  static final List<BoxShadow> actionShadow = _actionDefault
      ? PulseShadows.garnet
      : [
          BoxShadow(
              color: action.withValues(alpha: 0.45),
              blurRadius: 26,
              offset: const Offset(0, 12)),
        ];

  static LinearGradient _grad(Color a, Color b) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, b],
      );

  static Color _parse(String hex, Color fallback) {
    var s = hex.trim().replaceAll('#', '');
    if (s.length == 6) s = 'FF$s';
    final v = int.tryParse(s, radix: 16);
    return v == null ? fallback : Color(v);
  }

  static Color _darken(Color c, double amt) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - amt).clamp(0.0, 1.0)).toColor();
  }

  static Color _lighten(Color c, double amt) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + amt).clamp(0.0, 1.0)).toColor();
  }
}

/// Estilos de texto (Archivo para cifras/títulos, Nunito para cuerpo/labels).
class PulseText {
  static TextStyle archivo({
    double size = 14,
    FontWeight weight = FontWeight.w800,
    Color color = PulseColors.textWhite,
    double? spacing,
    double? height,
    bool tabular = false,
  }) {
    return GoogleFonts.archivo(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }

  static TextStyle nunito({
    double size = 13,
    FontWeight weight = FontWeight.w700,
    Color color = PulseColors.textWhite,
    double? spacing,
    double? height,
    bool tabular = false,
  }) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }
}

/// Sombras reutilizables.
class PulseShadows {
  static const garnet = [
    BoxShadow(color: Color(0x73A50044), blurRadius: 26, offset: Offset(0, 12)),
  ];
  static const blue = [
    BoxShadow(color: Color(0x73004D98), blurRadius: 20, offset: Offset(0, 8)),
  ];
  static const panel = [
    BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 12)),
  ];
}

/// Fondo de pantalla oscuro con glow azul superior (reutilizable).
class PulseBackground extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final Color glowColor;

  const PulseBackground({
    super.key,
    required this.child,
    this.gradient = PulseGradients.screenBg,
    this.glowColor = const Color(0x333A86E0),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 360,
                height: 220,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [glowColor, glowColor.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Logo / monograma de "pulso" (línea ECG) dentro de un cuadrado redondeado.
class PulseLogo extends StatelessWidget {
  final double size;
  final double radius;
  final double strokeWidth;

  const PulseLogo({
    super.key,
    this.size = 42,
    this.radius = 13,
    this.strokeWidth = 2.4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: PulseGradients.logo,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: PulseColors.borderBlue(0.3)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.62, size * 0.62),
          painter: _PulseLinePainter(strokeWidth: strokeWidth),
        ),
      ),
    );
  }
}

class _PulseLinePainter extends CustomPainter {
  final double strokeWidth;
  const _PulseLinePainter({required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    // Path original (viewBox 0 0 28 28): M2 14 h4.3 l2 -7 l3.6 14 L16 9 l2 5 h8
    const pts = <Offset>[
      Offset(2, 14),
      Offset(6.3, 14),
      Offset(8.3, 7),
      Offset(11.9, 21),
      Offset(16, 9),
      Offset(18, 14),
      Offset(26, 14),
    ];
    final sx = size.width / 28.0;
    final sy = size.height / 28.0;
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final p = Offset(pts[i].dx * sx, pts[i].dy * sy);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    final paint = Paint()
      ..color = PulseBrand.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * sx
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PulseLinePainter oldDelegate) => false;
}

/// Anillo de progreso de la jornada (pista + arco con degradado azul→grana).
class PulseProgressRing extends StatelessWidget {
  final double size;
  final double progress; // 0..1
  final Widget child;

  const PulseProgressRing({
    super.key,
    this.size = 210,
    required this.progress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(progress.clamp(0.0, 1.0)),
          ),
          child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * (16 / 210);
    final radius = (size.width / 2) - stroke / 2 - 2;

    // Pista
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    // Arco de progreso con degradado azul→grana
    final rect = Rect.fromCircle(center: center, radius: radius);
    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi,
      colors: [PulseBrand.accent, PulseBrand.action],
      stops: const [0.0, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    final arc = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
