// lib/src/core/services/user_service.dart
// Se eliminan imports innecesarios: dart:convert, dart:async, http, flutter_secure_storage
import 'package:libratrack_client/src/core/utils/api_client.dart'; // Importar el nuevo ApiClient
import 'package:libratrack_client/src/model/perfil_usuario.dart'; 

/// Servicio de Usuario (UserService).
/// REFACTORIZADO: Utiliza ApiClient para manejo de JWT y errores.
class UserService {
  
  final String _basePath = '/usuarios'; // Ruta base relativa

  /// Obtiene los datos del perfil del usuario (RF04).
  Future<PerfilUsuario> getMiPerfil() async {
    // 1. Usar el ApiClient (GET protegido)
    final dynamic responseData = await api.get('$_basePath/me');

    // 2. Mapear el JSON de respuesta
    return PerfilUsuario.fromJson(responseData as Map<String, dynamic>);
  }

  /// Actualiza el 'username' del usuario (RF04).
  Future<PerfilUsuario> updateMiPerfil(String nuevoUsername) async {
    
    final Map<String, String> body = {
      'username': nuevoUsername,
    };
    
    // 1. Usar el ApiClient (PUT protegido)
    final dynamic responseData = await api.put(
      '$_basePath/me',
      body: body,
    );

    // 2. Mapear el JSON de respuesta
    return PerfilUsuario.fromJson(responseData as Map<String, dynamic>);
  }

  /// Cambia la contraseña del usuario (RF04 - Cambio de Contraseña).
  Future<void> changePassword(String contrasenaActual, String nuevaContrasena) async {
    
    final Map<String, String> body = {
      'contraseñaActual': contrasenaActual,
      'nuevaContraseña': nuevaContrasena,
    };
    
    // 1. Usar el ApiClient (PUT protegido). No devuelve nada.
    await api.put(
      '$_basePath/me/password',
      body: body,
    );
  }
}