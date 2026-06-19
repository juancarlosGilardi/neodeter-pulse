// lib/registro.dart — REGISTRO DE USUARIO (dirección visual "Pulse")
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/config/app_config.dart';
import 'src/theme/pulse_theme.dart';

class RegistrationScreen extends StatefulWidget {
  final VoidCallback onRegistrationComplete;
  final void Function(String) showSnackBar;

  const RegistrationScreen({
    super.key,
    required this.onRegistrationComplete,
    required this.showSnackBar,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dniController = TextEditingController();
  // RUC de la empresa: oculto, viene de la config del despliegue (COMPANY_RUC).
  final _rucController = TextEditingController(text: AppConfig.companyRuc);

  bool _isLoading = false;
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bob.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _dniController.dispose();
    _rucController.dispose();
    super.dispose();
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text.trim());
      await prefs.setString(
          'userEmail', _emailController.text.trim().toLowerCase());
      await prefs.setString('userDni', _dniController.text.trim());
      await prefs.setString('userRuc', _rucController.text.trim());

      HapticFeedback.heavyImpact();
      widget.showSnackBar('Datos guardados exitosamente');
      widget.onRegistrationComplete();
    } catch (e) {
      widget.showSnackBar('Error guardando datos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'El nombre es requerido';
    if (value.trim().length < 2) return 'Mínimo 2 caracteres';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value.trim())) {
      return 'Solo letras y espacios';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es requerido';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validateDni(String? value) {
    if (value == null || value.trim().isEmpty) return 'El DNI es requerido';
    if (!RegExp(r'^\d{8}$').hasMatch(value.trim())) {
      return 'Debe tener 8 dígitos';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: PulseColors.bgDeep2,
      resizeToAvoidBottomInset: true,
      body: PulseBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                22, 24, 22, bottomInset > 0 ? bottomInset + 20 : 36),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Logo de pulso (flota suave)
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 14),
                    child: AnimatedBuilder(
                      animation: _bob,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, -7 * _bob.value),
                        child: child,
                      ),
                      child: const PulseLogo(
                          size: 84, radius: 24, strokeWidth: 2.2),
                    ),
                  ),
                  // Títulos
                  Text('Crea tu perfil',
                      style: PulseText.archivo(
                          size: 23, weight: FontWeight.w900, spacing: -0.3)),
                  const SizedBox(height: 3),
                  Text('Solo una vez en este teléfono',
                      style: PulseText.nunito(
                          size: 13.5,
                          weight: FontWeight.w700,
                          color: PulseColors.textMuted)),
                  const SizedBox(height: 26),

                  _field(
                    label: 'NOMBRE COMPLETO',
                    icon: Icons.person_outline,
                    controller: _nameController,
                    hint: 'Juan Carlos Gilardi',
                    validator: _validateName,
                    capitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 15),
                  _field(
                    label: 'CORREO ELECTRÓNICO',
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    hint: 'juancarlos@correo.com',
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  _field(
                    label: 'DNI · 8 DÍGITOS',
                    icon: Icons.badge_outlined,
                    controller: _dniController,
                    hint: '12345678',
                    validator: _validateDni,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    letterSpacing: 2,
                  ),

                  const SizedBox(height: 26),

                  // Botón grana
                  PulseButton(
                    label: 'CREAR PERFIL',
                    gradient: PulseBrand.actionGradient,
                    shadow: PulseBrand.actionShadow,
                    loading: _isLoading,
                    onTap: _isLoading ? null : _saveUserData,
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 14, color: PulseColors.locked),
                      const SizedBox(width: 7),
                      Text('Tus datos se guardan solo en este equipo',
                          style: PulseText.nunito(
                              size: 11.5,
                              weight: FontWeight.w700,
                              color: PulseColors.locked)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    int? maxLength,
    double? letterSpacing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(label,
              style: PulseText.nunito(
                  size: 12,
                  weight: FontWeight.w800,
                  color: PulseColors.textMuted2,
                  spacing: 0.3)),
        ),
        Container(
          decoration: BoxDecoration(
            color: PulseColors.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PulseColors.borderBlue(0.22)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 10),
                child: Icon(icon, size: 20, color: PulseBrand.accent),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  validator: validator,
                  keyboardType: keyboardType,
                  textCapitalization: capitalization,
                  maxLength: maxLength,
                  cursorColor: PulseColors.accentBlue,
                  style: PulseText.nunito(
                      size: 15,
                      weight: FontWeight.w700,
                      color: PulseColors.textWhite,
                      spacing: letterSpacing),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: PulseText.nunito(
                        size: 15,
                        weight: FontWeight.w700,
                        color: PulseColors.textMuted.withValues(alpha: 0.6)),
                    isDense: true,
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    errorStyle: PulseText.nunito(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: PulseColors.redLight),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }
}

/// Botón Pulse reutilizable expuesto para otras pantallas.
class PulseButton extends StatelessWidget {
  final String label;
  final Gradient? gradient;
  final Color? color;
  final Color textColor;
  final List<BoxShadow> shadow;
  final VoidCallback? onTap;
  final bool loading;
  final Widget? leading;
  final BoxBorder? border;

  const PulseButton({
    super.key,
    required this.label,
    this.gradient,
    this.color,
    this.textColor = Colors.white,
    this.shadow = const [],
    required this.onTap,
    this.loading = false,
    this.leading,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return _PulseButtonFlexible(
      label: label,
      gradient: gradient,
      color: color,
      textColor: textColor,
      shadow: shadow,
      onTap: onTap,
      loading: loading,
      leading: leading,
      border: border,
    );
  }
}

class _PulseButtonFlexible extends StatefulWidget {
  final String label;
  final Gradient? gradient;
  final Color? color;
  final Color textColor;
  final List<BoxShadow> shadow;
  final VoidCallback? onTap;
  final bool loading;
  final Widget? leading;
  final BoxBorder? border;

  const _PulseButtonFlexible({
    required this.label,
    required this.gradient,
    required this.color,
    required this.textColor,
    required this.shadow,
    required this.onTap,
    required this.loading,
    required this.leading,
    required this.border,
  });

  @override
  State<_PulseButtonFlexible> createState() => _PulseButtonFlexibleState();
}

class _PulseButtonFlexibleState extends State<_PulseButtonFlexible> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.loading;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!.call();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.shadow,
            border: widget.border,
          ),
          child: widget.loading
              ? Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: widget.textColor),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: 10),
                    ],
                    Text(widget.label,
                        style: PulseText.archivo(
                            size: 16,
                            weight: FontWeight.w900,
                            spacing: 1,
                            color: widget.textColor)),
                  ],
                ),
        ),
      ),
    );
  }
}
