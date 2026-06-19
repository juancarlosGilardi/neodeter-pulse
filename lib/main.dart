// lib/main.dart - VERSIÓN CORREGIDA PARA WEB Y MOBILE

import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'src/services/platform_service.dart';
import 'src/services/sync_service.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar servicios de plataforma
    await PlatformService.initialize();
    PlatformService.logPlatformInfo();
    
    // Ejecutar la aplicación
    runApp(const MyApp());
    
    // Inicializar sincronización automática después de que la app esté corriendo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SyncService.initialize();
    });
    
  } catch (e) {
    print('Error durante la inicialización: $e');
    // Ejecutar la app de todos modos
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neo Deter - Marcaciones',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const IntegratedMainScreen(),
    );
  }
}