// main_screen_ui.dart — Pantalla principal "Inicio" (command center, dirección Pulse)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'registro.dart';
import 'src/config/app_config.dart';
import 'src/connection/db.dart' show LimaTimeHelper;
import 'src/theme/pulse_theme.dart';
import 'src/utils/pulse_format.dart';

/// Punto de entrada de la UI principal: muestra Registro si faltan datos,
/// o el command center "Inicio" si el perfil está completo.
Widget buildMainUI(
  BuildContext context, {
  required String? userName,
  required String? userEmail,
  required String? userDni,
  required String? userRuc,
  required Map<String, String?> todayMarkings,
  required ValueNotifier<bool?> isDatabaseConnected,
  required ValueNotifier<String?> connectionQuality,
  required Function(String) onScanAndMark,
  required VoidCallback onCheckConnection,
  required VoidCallback onRegistrationComplete,
}) {
  if (_isUserDataIncomplete(userName, userEmail, userDni, userRuc)) {
    return RegistrationScreen(
      onRegistrationComplete: onRegistrationComplete,
      showSnackBar: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }
  return PulseHomeScreen(
    userName: userName!,
    todayMarkings: todayMarkings,
    isDatabaseConnected: isDatabaseConnected,
    onScanAndMark: onScanAndMark,
    onCheckConnection: onCheckConnection,
  );
}

bool _isUserDataIncomplete(
    String? userName, String? userEmail, String? userDni, String? userRuc) {
  return userName == null ||
      userEmail == null ||
      userDni == null ||
      userRuc == null ||
      userName.trim().isEmpty ||
      userEmail.trim().isEmpty ||
      userDni.trim().isEmpty ||
      userRuc.trim().isEmpty;
}

/// Definición de un hito del cronograma.
class _Step {
  final String key;
  final String type; // tipo que entiende el backend
  final String title;
  const _Step(this.key, this.type, this.title);
}

const _steps = <_Step>[
  _Step('ingreso', 'Ingreso', 'Ingreso'),
  _Step('refrigerioInicio', 'Inicio de Refrigerio', 'Inicio refrigerio'),
  _Step('refrigerioFin', 'Salida de Refrigerio', 'Fin de refrigerio'),
  _Step('salida', 'Salida', 'Salida'),
];

enum _StepState { done, local, active, locked }

class PulseHomeScreen extends StatefulWidget {
  final String userName;
  final Map<String, String?> todayMarkings;
  final ValueNotifier<bool?> isDatabaseConnected;
  final Function(String) onScanAndMark;
  final VoidCallback onCheckConnection;

  const PulseHomeScreen({
    super.key,
    required this.userName,
    required this.todayMarkings,
    required this.isDatabaseConnected,
    required this.onScanAndMark,
    required this.onCheckConnection,
  });

  @override
  State<PulseHomeScreen> createState() => _PulseHomeScreenState();
}

class _PulseHomeScreenState extends State<PulseHomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flick; // punto EN VIVO
  late final AnimationController _halo; // halo de la fila activa
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _flick = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _halo = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    // Recalcular el tiempo trabajado periódicamente.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _flick.dispose();
    _halo.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  // ---- Lógica de disponibilidad (réplica del orden de marcación) ----
  bool _canMarkType(String key) {
    final m = widget.todayMarkings;
    switch (key) {
      case 'ingreso':
        return m['ingreso'] == null;
      case 'refrigerioInicio':
        return m['ingreso'] != null &&
            m['refrigerioInicio'] == null &&
            m['salida'] == null;
      case 'refrigerioFin':
        return m['refrigerioInicio'] != null &&
            m['refrigerioFin'] == null &&
            m['salida'] == null;
      case 'salida':
        return m['ingreso'] != null &&
            m['salida'] == null &&
            (m['refrigerioInicio'] == null || m['refrigerioFin'] != null);
      default:
        return false;
    }
  }

  int? get _activeIndex {
    for (var i = 0; i < _steps.length; i++) {
      final raw = widget.todayMarkings[_steps[i].key];
      final marked = raw != null; // incluye los locales (no nulos)
      if (!marked && _canMarkType(_steps[i].key)) return i;
    }
    return null;
  }

  _StepState _stateOf(int i) {
    final raw = widget.todayMarkings[_steps[i].key];
    if (raw != null) return isLocalMark(raw) ? _StepState.local : _StepState.done;
    if (_activeIndex == i) return _StepState.active;
    return _StepState.locked;
  }

  // ---- Cálculo del anillo (tiempo trabajado) ----
  static const int _journeyMin = 480; // 8 h

  int get _workedMinutes {
    final m = widget.todayMarkings;
    final ing = minutesOfDay(m['ingreso']);
    if (ing == null) return 0;
    final now = LimaTimeHelper.getLimaTime();
    final nowMin = now.hour * 60 + now.minute;
    final salida = minutesOfDay(m['salida']);
    final end = salida ?? nowMin;
    var worked = end - ing;

    final refIni = minutesOfDay(m['refrigerioInicio']);
    final refFin = minutesOfDay(m['refrigerioFin']);
    if (refIni != null) {
      final refEnd = refFin ?? (salida == null ? nowMin : refIni);
      worked -= (refEnd - refIni).clamp(0, worked);
    }
    return worked.clamp(0, 24 * 60);
  }

  @override
  Widget build(BuildContext context) {
    final worked = _workedMinutes;
    final hasIngreso = widget.todayMarkings['ingreso'] != null;
    final progress = (worked / _journeyMin).clamp(0.0, 1.0);
    final remaining = (_journeyMin - worked).clamp(0, _journeyMin);
    final pct = (progress * 100).round();
    final activeIdx = _activeIndex;

    return Scaffold(
      backgroundColor: PulseColors.bgDeep2,
      body: PulseBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 22),
                _ring(worked, progress, pct, remaining, hasIngreso),
                const SizedBox(height: 24),
                Text('CRONOGRAMA',
                    style: PulseText.nunito(
                        size: 11,
                        weight: FontWeight.w800,
                        color: PulseColors.textMuted,
                        spacing: 2)),
                const SizedBox(height: 12),
                _timeline(),
                const SizedBox(height: 20),
                _ficharButton(activeIdx),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Header ----------
  Widget _header() {
    return Row(
      children: [
        const PulseLogo(size: 42, radius: 13),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppConfig.wordmark,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PulseText.archivo(
                      size: 13.5, weight: FontWeight.w900, spacing: 0.4)),
              const SizedBox(height: 2),
              Text('${widget.userName} · ${fechaCorta(LimaTimeHelper.getLimaTime())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PulseText.nunito(
                      size: 11,
                      weight: FontWeight.w600,
                      color: PulseColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _connectionChip(),
      ],
    );
  }

  Widget _connectionChip() {
    return ValueListenableBuilder<bool?>(
      valueListenable: widget.isDatabaseConnected,
      builder: (context, connected, _) {
        Color color;
        String text;
        bool flick;
        if (connected == null) {
          color = PulseColors.amber;
          text = 'VERIFICANDO';
          flick = false;
        } else if (connected) {
          color = PulseColors.green;
          text = 'EN VIVO';
          flick = true;
        } else {
          color = PulseColors.red;
          text = 'SIN RED';
          flick = false;
        }
        return GestureDetector(
          onTap: widget.onCheckConnection,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                flick
                    ? FadeTransition(
                        opacity: Tween(begin: 1.0, end: 0.4).animate(_flick),
                        child: _dot(color))
                    : _dot(color),
                const SizedBox(width: 6),
                Text(text,
                    style: PulseText.nunito(
                        size: 10.5,
                        weight: FontWeight.w800,
                        color: color,
                        spacing: 1)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dot(Color color) => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  // ---------- Anillo ----------
  Widget _ring(int worked, double progress, int pct, int remaining, bool hasIngreso) {
    final hh = (worked ~/ 60).toString().padLeft(2, '0');
    final mm = (worked % 60).toString().padLeft(2, '0');
    final rh = remaining ~/ 60;
    final rm = remaining % 60;
    return Center(
      child: PulseProgressRing(
        size: 210,
        progress: progress,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('TRABAJADO',
                style: PulseText.nunito(
                    size: 11,
                    weight: FontWeight.w700,
                    color: PulseColors.textMuted,
                    spacing: 2)),
            Text('$hh:$mm',
                style: PulseText.archivo(
                    size: 46,
                    weight: FontWeight.w900,
                    spacing: -1,
                    height: 1.05,
                    tabular: true)),
            const SizedBox(height: 2),
            Text(
                hasIngreso
                    ? '$pct% · faltan ${rh}h ${rm}m'
                    : 'Marca tu ingreso',
                style: PulseText.nunito(
                    size: 12,
                    weight: FontWeight.w800,
                    color: PulseBrand.accent,
                    tabular: true)),
          ],
        ),
      ),
    );
  }

  // ---------- Cronograma ----------
  Widget _timeline() {
    return Stack(
      children: [
        Positioned(
          left: 15,
          top: 16,
          bottom: 46,
          child: Container(
            width: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  PulseColors.garnet,
                  PulseColors.accentBlue,
                  Color(0x14FFFFFF),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        Column(
          children: [
            for (var i = 0; i < _steps.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == _steps.length - 1 ? 0 : 10),
                child: _stepRow(i),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stepRow(int i) {
    final step = _steps[i];
    final state = _stateOf(i);
    final raw = widget.todayMarkings[step.key];
    final hora = formatHora(raw);

    final circle = _stepCircle(state);

    Widget content;
    switch (state) {
      case _StepState.active:
        content = _activeContent(step);
        break;
      case _StepState.done:
        content = _infoContent(
          title: step.title,
          subtitle: 'Registrado',
          subtitleColor: PulseColors.textMuted,
          hora: hora,
          horaColor: PulseBrand.actionLight,
        );
        break;
      case _StepState.local:
        content = _infoContent(
          title: step.title,
          subtitle: 'Sincronizando · local',
          subtitleColor: PulseColors.amberText,
          hora: hora,
          horaColor: PulseColors.amberLight,
        );
        break;
      case _StepState.locked:
        content = _infoContent(
          title: step.title,
          subtitle: 'Aún no disponible',
          subtitleColor: PulseColors.lockedText,
          titleColor: PulseColors.textMuted3,
          hora: '--:--',
          horaColor: PulseColors.lockedText,
        );
        break;
    }

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        circle,
        const SizedBox(width: 13),
        Expanded(child: content),
      ],
    );

    return state == _StepState.locked
        ? Opacity(opacity: 0.55, child: row)
        : row;
  }

  Widget _stepCircle(_StepState state) {
    Widget inner;
    Color bg;
    switch (state) {
      case _StepState.done:
        bg = PulseBrand.action;
        inner = const Icon(Icons.check, size: 17, color: Colors.white);
        break;
      case _StepState.local:
        bg = PulseColors.amber;
        inner = RotationTransition(
          turns: _halo,
          child: const Icon(Icons.sync, size: 16, color: Colors.white),
        );
        break;
      case _StepState.active:
        bg = PulseBrand.accent;
        inner = const Icon(Icons.photo_camera_outlined,
            size: 17, color: Colors.white);
        break;
      case _StepState.locked:
        bg = Colors.white.withValues(alpha: 0.08);
        inner = const Icon(Icons.lock_outline, size: 14, color: PulseColors.locked);
        break;
    }

    final base = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: PulseColors.bgDeep2, blurRadius: 0, spreadRadius: 4),
        ],
      ),
      child: Center(child: inner),
    );

    if (state != _StepState.active) return base;

    // Halo pulsante para la fila activa.
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _halo,
            builder: (context, _) {
              final t = _halo.value;
              return Container(
                width: 32 * (0.85 + 0.65 * t),
                height: 32 * (0.85 + 0.65 * t),
                decoration: BoxDecoration(
                  color: PulseBrand.accent.withValues(alpha: 0.5 * (1 - t)),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          base,
        ],
      ),
    );
  }

  Widget _activeContent(_Step step) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onScanAndMark(step.type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          gradient: PulseBrand.accentGradient,
          borderRadius: BorderRadius.circular(13),
          boxShadow: PulseShadows.blue,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: PulseText.archivo(
                          size: 14.5, weight: FontWeight.w900)),
                  const SizedBox(height: 1),
                  Text('Tu turno · escanea el QR',
                      style: PulseText.nunito(
                          size: 11,
                          weight: FontWeight.w800,
                          color: PulseBrand.accentSoft)),
                ],
              ),
            ),
            Text('NOW',
                style: PulseText.archivo(
                    size: 11,
                    weight: FontWeight.w900,
                    color: PulseBrand.accentSoft,
                    spacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _infoContent({
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required String hora,
    required Color horaColor,
    Color titleColor = PulseColors.textWhite,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: PulseText.nunito(
                      size: 14.5, weight: FontWeight.w800, color: titleColor)),
              const SizedBox(height: 1),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PulseText.nunito(
                      size: 11,
                      weight: FontWeight.w700,
                      color: subtitleColor)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(hora,
            style: PulseText.archivo(
                size: 13,
                weight: FontWeight.w900,
                color: horaColor,
                tabular: true)),
      ],
    );
  }

  // ---------- Botón FICHAR ----------
  Widget _ficharButton(int? activeIdx) {
    if (activeIdx == null) {
      return const PulseButton(
        label: 'JORNADA COMPLETA',
        color: PulseColors.panel,
        textColor: PulseColors.textMuted3,
        onTap: null,
        leading: Icon(Icons.check_circle_outline,
            size: 20, color: PulseColors.green),
      );
    }
    final step = _steps[activeIdx];
    return PulseButton(
      label: 'FICHAR AHORA',
      gradient: PulseBrand.actionGradient,
      shadow: PulseBrand.actionShadow,
      leading: const Icon(Icons.qr_code_2, size: 22, color: Colors.white),
      onTap: () => widget.onScanAndMark(step.type),
    );
  }
}
