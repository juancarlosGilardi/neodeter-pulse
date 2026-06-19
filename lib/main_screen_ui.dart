// main_screen_ui.dart - UI CON RUC Y LOADING MEJORADO
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'registro.dart';

// Temas simplificados
enum AppTheme { energetic, corporate, minimal }

class ThemeColors {
  final LinearGradient backgroundGradient;
  final Color containerColor;
  final Color textColor;
  final Color accentColor;
  final Color primaryColor;
  final Color cardColor;
  final Color borderColor;
  final Color activeBorderColor;

  const ThemeColors({
    required this.backgroundGradient,
    required this.containerColor,
    required this.textColor,
    required this.accentColor,
    required this.primaryColor,
    required this.cardColor,
    required this.borderColor,
    required this.activeBorderColor,
  });

  static const energetic = ThemeColors(
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFF45B7D1)],
    ),
    containerColor: Colors.transparent,
    textColor: Colors.white,
    accentColor: Color(0xFFFFE66D),
    primaryColor: Color(0xFFFF6B6B),
    cardColor: Color(0x1AFFFFFF),
    borderColor: Color(0x3DFFFFFF),
    activeBorderColor: Color(0xFFFFE66D),
  );

  static const corporate = ThemeColors(
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2c3e50), Color(0xFF34495e)],
    ),
    containerColor: Colors.white,
    textColor: Color(0xFF333333),
    accentColor: Color(0xFF3498db),
    primaryColor: Color(0xFF2c3e50),
    cardColor: Color(0xFFF8F9FC),
    borderColor: Color(0xFFE3E6F0),
    activeBorderColor: Color(0xFF27ae60),
  );

  static const minimal = ThemeColors(
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
    ),
    containerColor: Colors.white,
    textColor: Color(0xFF333333),
    accentColor: Color(0xFF007bff),
    primaryColor: Color(0xFF333333),
    cardColor: Color(0xFFF8F9FA),
    borderColor: Color(0xFFDEE2E6),
    activeBorderColor: Color(0xFF28a745),
  );
}

// UI principal con RUC incluido
Widget buildMainUI(
  BuildContext context,
  AppTheme currentTheme,
  String? userName,
  String? userEmail,
  String? userDni,
  String? userRuc, // ✅ AGREGADO RUC
  Map<String, String?> todayMarkings,
  ValueNotifier<bool?> isDatabaseConnected,
  ValueNotifier<String?> connectionQuality, {
  required Function(String) onScanAndMark,
  required Function(AppTheme) onChangeTheme,
  required VoidCallback onCheckConnection,
  required VoidCallback onRegistrationComplete,
}) {
  final themeColors = _getThemeColors(currentTheme);

  return Scaffold(
    body: Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(gradient: themeColors.backgroundGradient),
      child: Container(
        decoration: currentTheme == AppTheme.energetic
            ? BoxDecoration(
                color: Colors.white.withAlpha((0.08 * 255).round()),
                border: Border.all(
                    color: Colors.white.withAlpha((0.15 * 255).round())),
              )
            : BoxDecoration(
                color: themeColors.containerColor,
                border: currentTheme == AppTheme.minimal
                    ? Border.all(color: Colors.grey.shade300, width: 2)
                    : null,
              ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(themeColors, currentTheme, onChangeTheme,
                  isDatabaseConnected, connectionQuality, onCheckConnection),
              // ✅ VERIFICAR DATOS COMPLETOS INCLUYENDO RUC
              if (_isUserDataIncomplete(userName, userEmail, userDni, userRuc))
                Expanded(
                  child: RegistrationScreen(
                    onRegistrationComplete: onRegistrationComplete,
                    showSnackBar: (msg) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );
                    },
                  ),
                )
              else ...[
                _buildUserInfo(themeColors, userName!, userEmail!, userDni!, userRuc!),
                Expanded(
                  child: _buildMarcationGrid(
                      themeColors, todayMarkings, onScanAndMark),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

// ✅ FUNCIÓN ACTUALIZADA: Verificar datos incluyendo RUC
bool _isUserDataIncomplete(String? userName, String? userEmail, String? userDni, String? userRuc) {
  return userName == null || 
         userEmail == null || 
         userDni == null || 
         userRuc == null || // ✅ VERIFICAR RUC
         userName.trim().isEmpty || 
         userEmail.trim().isEmpty || 
         userDni.trim().isEmpty ||
         userRuc.trim().isEmpty; // ✅ VERIFICAR RUC
}

// Header simplificado
Widget _buildHeader(
  ThemeColors themeColors,
  AppTheme currentTheme,
  Function(AppTheme) onChangeTheme,
  ValueNotifier<bool?> isDatabaseConnected,
  ValueNotifier<String?> connectionQuality,
  VoidCallback onCheckConnection,
) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: currentTheme == AppTheme.energetic
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF6B6B).withAlpha((0.15 * 255).round()),
                const Color(0xFF4ECDC4).withAlpha((0.1 * 255).round()),
              ],
            )
          : currentTheme == AppTheme.corporate
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2c3e50), Color(0xFF3498db)],
                )
              : null,
      color: currentTheme == AppTheme.minimal ? const Color(0xFFF8F9FA) : null,
    ),
    child: Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'NEO DETER ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: themeColors.textColor,
                ),
              ),
              TextSpan(
                text: 'PULSE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: themeColors.accentColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sistema de Marcaciones',
          style: TextStyle(
            fontSize: 12,
            color: themeColors.textColor.withAlpha((0.9 * 255).round()),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 15),
        _buildConnectionStatus(themeColors, isDatabaseConnected, connectionQuality, onCheckConnection),
      ],
    ),
  );
}

// Estado de conexión
Widget _buildConnectionStatus(
  ThemeColors themeColors,
  ValueNotifier<bool?> isDatabaseConnected,
  ValueNotifier<String?> connectionQuality,
  VoidCallback onCheckConnection,
) {
  return ValueListenableBuilder<bool?>(
    valueListenable: isDatabaseConnected,
    builder: (context, isConnected, child) {
      return ValueListenableBuilder<String?>(
        valueListenable: connectionQuality,
        builder: (context, quality, child) {
          IconData icon;
          Color color;
          String text;

          if (isConnected == null) {
            icon = Icons.cloud_sync;
            color = Colors.orange;
            text = 'Verificando...';
          } else if (isConnected) {
            icon = Icons.cloud_done;
            color = quality == 'Lenta' ? Colors.orange : Colors.green;
            text = 'Conectado';
          } else {
            icon = Icons.cloud_off;
            color = Colors.red;
            text = 'Sin conexión';
          }

          return GestureDetector(
            onTap: onCheckConnection,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (quality != null && isConnected == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: quality == 'Excelente'
                            ? Colors.green
                            : quality == 'Regular'
                                ? Colors.yellow[700]
                                : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        quality,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ✅ INFORMACIÓN DEL USUARIO CON RUC
Widget _buildUserInfo(ThemeColors themeColors, String userName, String userEmail, String userDni, String userRuc) {
  String initials = 'NN';
  if (userName.isNotEmpty) {
    if (userName.length >= 2) {
      initials = userName.substring(0, 2).toUpperCase();
    } else {
      initials = userName.toUpperCase().padRight(2, 'N');
    }
  }

  return Container(
    margin: const EdgeInsets.fromLTRB(20, 15, 20, 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: themeColors.cardColor,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: themeColors.borderColor),
    ),
    child: Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeColors.accentColor, themeColors.primaryColor],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: themeColors.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userEmail,
                style: TextStyle(
                  fontSize: 12,
                  color: themeColors.textColor.withAlpha((0.7 * 255).round()),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'DNI: $userDni',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeColors.textColor.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ✅ GRID DE MARCACIONES CON ICONO DE CÁMARA
// En main_screen_ui.dart, modifica la función _buildMarcationGrid

Widget _buildMarcationGrid(
  ThemeColors themeColors,
  Map<String, String?> todayMarkings,
  Function(String) onScanAndMark,
) {
  final marcationTypes = [
    {'key': 'ingreso', 'type': 'Ingreso', 'icon': Icons.login, 'title': 'Ingreso'},
    {'key': 'refrigerioInicio', 'type': 'Inicio de Refrigerio', 'icon': Icons.restaurant, 'title': 'Inicio\nRefrigerio'},
    {'key': 'refrigerioFin', 'type': 'Salida de Refrigerio', 'icon': Icons.work, 'title': 'Fin\nRefrigerio'},
    {'key': 'salida', 'type': 'Salida', 'icon': Icons.logout, 'title': 'Salida'},
  ];

  return Container(
    padding: const EdgeInsets.all(20),
    child: GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.0,
      ),
      itemCount: marcationTypes.length,
      itemBuilder: (context, index) {
        final marcation = marcationTypes[index];
        final key = marcation['key'] as String;
        final isCompleted = todayMarkings[key] != null;
        final time = todayMarkings[key];
        final isLocal = time?.contains('(local)') ?? false;
        final isAvailable = _canMarkType(key, todayMarkings);

        // NUEVOS COLORES PARA MARCACIONES COMPLETADAS
        Color getCompletedColor() {
          if (isLocal) return Colors.orange;
          return Colors.red; // NUEVO: Rojo para marcaciones completadas
        }

        Color getCompletedBackgroundColor() {
          if (isLocal) return Colors.orange.withAlpha((0.1 * 255).round());
          return Colors.red.withAlpha((0.1 * 255).round()); // NUEVO: Fondo rojo suave
        }

        return GestureDetector(
          onTap: isAvailable ? () {
            HapticFeedback.lightImpact();
            onScanAndMark(marcation['type'] as String);
          } : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isCompleted
                  ? getCompletedBackgroundColor() // NUEVO: Usa función para color de fondo
                  : isAvailable 
                      ? themeColors.cardColor
                      : themeColors.cardColor.withAlpha((0.5 * 255).round()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCompleted
                    ? getCompletedColor() // NUEVO: Usa función para color del borde
                    : isAvailable
                        ? themeColors.activeBorderColor
                        : themeColors.borderColor,
                width: isCompleted || isAvailable ? 2 : 1,
              ),
              boxShadow: isAvailable && !isCompleted
                  ? [
                      BoxShadow(
                        color: themeColors.primaryColor.withAlpha((0.2 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? getCompletedColor() // NUEVO: Check rojo para completadas
                        : isAvailable
                            ? themeColors.activeBorderColor
                            : themeColors.borderColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted
                        ? (isLocal ? Icons.storage : Icons.check) // NUEVO: Check rojo
                        : marcation['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  marcation['title'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isAvailable || isCompleted
                        ? themeColors.textColor
                        : themeColors.textColor.withAlpha((0.5 * 255).round()),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  isCompleted
                      ? (isLocal 
                          ? '${time!.replaceAll(' (local)', '')} (local)'
                          : time!)
                      : isAvailable
                          ? 'Escanear QR'
                          : 'No disponible',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isCompleted
                        ? getCompletedColor() // NUEVO: Texto rojo para completadas
                        : themeColors.textColor.withAlpha((0.7 * 255).round()),
                  ),
                  textAlign: TextAlign.center,
                ),
                // Icono de cámara para botones disponibles
                if (isAvailable && !isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: themeColors.activeBorderColor,
                    ),
                  ),
                if (isLocal)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Pendiente sincronizar',
                      style: TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// Lógica de marcación (simplificada para UI)
bool _canMarkType(String key, Map<String, String?> markings) {
  switch (key) {
    case 'ingreso':
      return markings['ingreso'] == null;
    case 'refrigerioInicio':
      return markings['ingreso'] != null && 
             markings['refrigerioInicio'] == null && 
             markings['salida'] == null;
    case 'refrigerioFin':
      return markings['refrigerioInicio'] != null && 
             markings['refrigerioFin'] == null && 
             markings['salida'] == null;
    case 'salida':
      return markings['ingreso'] != null && 
             markings['salida'] == null && 
             (markings['refrigerioInicio'] == null || 
              markings['refrigerioFin'] != null);
    default:
      return false;
  }
}

// Helper para obtener colores del tema
ThemeColors _getThemeColors(AppTheme theme) {
  switch (theme) {
    case AppTheme.energetic:
      return ThemeColors.energetic;
    case AppTheme.corporate:
      return ThemeColors.corporate;
    case AppTheme.minimal:
      return ThemeColors.minimal;
  }
}