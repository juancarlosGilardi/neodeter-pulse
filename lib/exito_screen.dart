// lib/exito_screen.dart — Pantalla de Éxito (dirección Pulse)
import 'package:flutter/material.dart';

import 'registro.dart' show PulseButton;
import 'src/theme/pulse_theme.dart';

class ExitoScreen extends StatefulWidget {
  final String tipoLabel; // "Fin de refrigerio"
  final String hora; // "14:05"
  final bool sincronizado;

  const ExitoScreen({
    super.key,
    required this.tipoLabel,
    required this.hora,
    required this.sincronizado,
  });

  @override
  State<ExitoScreen> createState() => _ExitoScreenState();
}

class _ExitoScreenState extends State<ExitoScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pop;
  late final AnimationController _halo;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..forward();
    _halo = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
  }

  @override
  void dispose() {
    _pop.dispose();
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor =
        widget.sincronizado ? PulseColors.green : PulseColors.amberLight;
    final estadoText = widget.sincronizado ? 'Sincronizado' : 'Guardado local';
    return Scaffold(
      backgroundColor: PulseColors.bgDeep2,
      body: PulseBackground(
        gradient: PulseGradients.successBg,
        glowColor: const Color(0x3837D27E),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              children: [
                const Spacer(),
                _heroCheck(),
                const SizedBox(height: 30),
                Text('¡Marcación registrada!',
                    textAlign: TextAlign.center,
                    style: PulseText.archivo(
                        size: 26, weight: FontWeight.w900, spacing: -0.4)),
                const SizedBox(height: 6),
                Text('${widget.tipoLabel} confirmado',
                    textAlign: TextAlign.center,
                    style: PulseText.nunito(
                        size: 14,
                        weight: FontWeight.w700,
                        color: PulseColors.greenText)),
                const SizedBox(height: 28),
                _resumen(estadoColor, estadoText),
                const Spacer(),
                PulseButton(
                  label: 'VOLVER AL INICIO',
                  color: Colors.white,
                  textColor: PulseColors.bgDeep2,
                  shadow: const [
                    BoxShadow(
                        color: Color(0x59000000),
                        blurRadius: 26,
                        offset: Offset(0, 12)),
                  ],
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroCheck() {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _haloRing(0.0),
          _haloRing(0.5),
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _pop,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
            ),
            child: Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                gradient: PulseGradients.successCircle,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x732FCB76),
                      blurRadius: 36,
                      offset: Offset(0, 16)),
                ],
              ),
              child: AnimatedBuilder(
                animation: _pop,
                builder: (context, _) {
                  final t = ((_pop.value - 0.4) / 0.6).clamp(0.0, 1.0);
                  return CustomPaint(
                    size: const Size(60, 60),
                    painter: _CheckPainter(t),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _haloRing(double delay) {
    return AnimatedBuilder(
      animation: _halo,
      builder: (context, _) {
        var t = _halo.value + delay;
        if (t > 1) t -= 1;
        return Container(
          width: 112 * (0.85 + 0.65 * t),
          height: 112 * (0.85 + 0.65 * t),
          decoration: BoxDecoration(
            color: PulseColors.green.withValues(alpha: 0.3 * (1 - t)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _resumen(Color estadoColor, String estadoText) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PulseColors.greenPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PulseColors.green.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        children: [
          _fila('Tipo',
              Text(widget.tipoLabel,
                  style: PulseText.nunito(
                      size: 14, weight: FontWeight.w800))),
          _hairline(),
          _fila('Hora',
              Text(widget.hora,
                  style: PulseText.archivo(
                      size: 16, weight: FontWeight.w900, tabular: true))),
          _hairline(),
          _fila(
            'Estado',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: estadoColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(estadoText,
                    style: PulseText.nunito(
                        size: 13,
                        weight: FontWeight.w800,
                        color: estadoColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: PulseText.nunito(
                  size: 13,
                  weight: FontWeight.w700,
                  color: const Color(0xFF7FB69C))),
          value,
        ],
      ),
    );
  }

  Widget _hairline() =>
      Container(height: 1, color: Colors.white.withValues(alpha: 0.07));
}

class _CheckPainter extends CustomPainter {
  final double progress; // 0..1
  const _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 48x48, path M12 25 l9 9 L37 6 (puntos 12,25 / 21,34 / 37,15)
    const pts = [Offset(12, 25), Offset(21, 34), Offset(37, 15)];
    final sx = size.width / 48.0;
    final sy = size.height / 48.0;
    final scaled =
        pts.map((p) => Offset(p.dx * sx, p.dy * sy)).toList(growable: false);

    final seg1 = (scaled[1] - scaled[0]).distance;
    final seg2 = (scaled[2] - scaled[1]).distance;
    final total = seg1 + seg2;
    final drawn = total * progress;

    final path = Path()..moveTo(scaled[0].dx, scaled[0].dy);
    if (drawn <= seg1) {
      final f = seg1 == 0 ? 0 : drawn / seg1;
      final p = Offset.lerp(scaled[0], scaled[1], f.toDouble())!;
      path.lineTo(p.dx, p.dy);
    } else {
      path.lineTo(scaled[1].dx, scaled[1].dy);
      final f = seg2 == 0 ? 0 : (drawn - seg1) / seg2;
      final p = Offset.lerp(scaled[1], scaled[2], f.toDouble())!;
      path.lineTo(p.dx, p.dy);
    }

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * sx
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
