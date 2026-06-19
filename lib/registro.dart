// lib/registro.dart - REGISTRO DE USUARIO CON RUC
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dniController = TextEditingController();
  final _rucController = TextEditingController(text: '20101162282'); // ✅ NUEVO CAMPO RUC

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dniController.dispose();
    _rucController.dispose(); // ✅ DISPOSE DEL RUC
    super.dispose();
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text.trim());
      await prefs.setString('userEmail', _emailController.text.trim().toLowerCase());
      await prefs.setString('userDni', _dniController.text.trim());
      await prefs.setString('userRuc', _rucController.text.trim()); // ✅ GUARDAR RUC

      HapticFeedback.heavyImpact();
      widget.showSnackBar('✅ Datos guardados exitosamente');
      
      widget.onRegistrationComplete();

    } catch (e) {
      widget.showSnackBar('❌ Error guardando datos: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value.trim())) {
      return 'El nombre solo puede contener letras y espacios';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
      return 'Ingrese un email válido';
    }
    return null;
  }

  String? _validateDni(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El DNI es requerido';
    }
    if (!RegExp(r'^\d{8}$').hasMatch(value.trim())) {
      return 'El DNI debe tener exactamente 8 dígitos';
    }
    return null;
  }

  // ✅ NUEVA VALIDACIÓN PARA RUC
  String? _validateRuc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El RUC de la empresa es requerido';
    }
    if (!RegExp(r'^\d{11}$').hasMatch(value.trim())) {
      return 'El RUC debe tener exactamente 11 dígitos';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 20, right: 20, top: 40, bottom: bottomPadding > 0 ? bottomPadding + 20 : 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.person_add,
                      size: 50,
                      color: Colors.black87,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Registro de Usuario',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Ingresa tus datos para comenzar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Campo Nombre
              _buildTextField(
                controller: _nameController,
                label: 'Nombre Completo',
                icon: Icons.person,
                validator: _validateName,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 12),

              // Campo Email
              _buildTextField(
                controller: _emailController,
                label: 'Correo Electrónico',
                icon: Icons.email,
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 12),

              // Campo DNI
              _buildTextField(
                controller: _dniController,
                label: 'DNI (8 dígitos)',
                icon: Icons.badge,
                validator: _validateDni,
                keyboardType: TextInputType.number,
                maxLength: 8,
              ),

              const SizedBox(height: 12),

              // ✅ NUEVO CAMPO RUC
              Offstage(
                offstage: true, // Esto hace que el widget sea invisible
                child: _buildTextField(
                  controller: _rucController,
                  label: 'RUC de la Empresa (11 dígitos)',
                  icon: Icons.business,
                  validator: _validateRuc,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                ),
              ),

              const SizedBox(height: 25),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Guardar Datos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.black54),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        counterText: '',
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
        ),
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}