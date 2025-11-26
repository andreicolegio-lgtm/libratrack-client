import 'dart:io';
import 'package:flutter/foundation.dart';

/// Clase centralizada para gestionar variables de entorno y configuración de red.
/// Permite cambiar fácilmente entre entornos de desarrollo y producción.
class EnvironmentConfig {
  /// Obtiene la URL base de la API dependiendo del entorno de ejecución.
  ///
  /// - **Producción (Release):** Usa el dominio real del servidor.
  /// - **Android (Emulador):** Usa `10.0.2.2` que es el alias especial de Android para "localhost" de la máquina anfitriona.
  /// - **iOS / Web / Desktop:** Usa `localhost` estándar.
  static String get apiUrl {
    if (kReleaseMode) {
      // TODO: Reemplazar con tu dominio real cuando despliegues en AWS/GCP/Heroku
      return 'https://api.libratrack.com/api';
    }

    // Configuración para Desarrollo (Debug/Profile)
    if (!kIsWeb && Platform.isAndroid) {
      // Si estás probando en un DISPOSITIVO FÍSICO Android, cambia esto por la IP local de tu PC
      // Ejemplo: return 'http://192.168.1.45:8080/api';
      return 'http://10.0.2.2:8080/api';
    }

    // Para simulador iOS, Web o Desktop, localhost funciona correctamente
    return 'http://localhost:8080/api';
  }

  /// Client ID para la autenticación con Google.
  ///
  /// Se utiliza `String.fromEnvironment` para permitir la inyección de este valor
  /// al momento de compilar usando: `flutter run --dart-define=GOOGLE_CLIENT_ID=tu_clave`.
  /// Si no se proporciona, usa el valor por defecto (útil para desarrollo rápido).
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '1078651925823-g53s0f6i4on4ugdc0t7pfg11vpu86rdp.apps.googleusercontent.com',
  );
}
