import 'dart:io';
import 'package:flutter/foundation.dart';

class EnvironmentConfig {
  // URL base para el Backend
  static String get apiUrl {
    if (kReleaseMode) {
      // URL de producción real
      return 'https://api.libratrack.com/api';
    }

    // En desarrollo, detectamos si es Emulador Android o dispositivo físico/iOS
    if (Platform.isAndroid) {
      // 10.0.2.2 es localhost desde el emulador de Android
      // Si usas un dispositivo físico Android, cambia esto por tu IP local (ej: 192.168.1.X)
      return 'http://10.0.2.2:8080/api';
    }

    // Para iOS simulador o localhost web/desktop
    return 'http://localhost:8080/api';
  }

  // Google Sign-In Client ID
  // Se recomienda pasar esto via --dart-define en build time para mayor seguridad,
  // pero centralizarlo aquí es el primer paso correcto.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '1078651925823-g53s0f6i4on4ugdc0t7pfg11vpu86rdp.apps.googleusercontent.com',
  );
}
