// lib/src/core/services/user_service.dart
import 'package:libratrack_client/src/core/utils/api_client.dart'; 
import 'package:libratrack_client/src/model/perfil_usuario.dart'; 

/// --- ¡ACTUALIZADO (Sprint 3)! ---
class UserService {
  
  final String _basePath = '/usuarios'; 

  /// Obtiene los datos del perfil del usuario (RF04).
  Future<PerfilUsuario> getMiPerfil() async {
    final dynamic responseData = await api.get('$_basePath/me');
    return PerfilUsuario.fromJson(responseData as Map<String, dynamic>);
  }

  /// Actualiza el 'username' del usuario (RF04).
  Future<PerfilUsuario> updateMiPerfil(String nuevoUsername) async {
    final Map<String, String> body = {
      'username': nuevoUsername,
    };
    final dynamic responseData = await api.put(
      '$_basePath/me',
      body: body,
    );
    return PerfilUsuario.fromJson(responseData as Map<String, dynamic>);
  }

  /// Cambia la contraseña del usuario (RF04).
  Future<void> changePassword(String contrasenaActual, String nuevaContrasena) async {
    final Map<String, String> body = {
      'contraseñaActual': contrasenaActual,
      'nuevaContraseña': nuevaContrasena,
    };
    await api.put(
      '$_basePath/me/password',
      body: body,
    );
  }
  
  /// --- ¡NUEVO MÉTODO! (Petición 6) ---
  /// Envía la URL de la imagen (subida a GCS) a la API
  /// para guardarla en el perfil del usuario.
  Future<PerfilUsuario> updateFotoPerfil(String fotoUrl) async {
    final Map<String, String> body = {
      'url': fotoUrl,
    };
    
    final dynamic responseData = await api.put(
      '$_basePath/me/foto',
      body: body,
    );
    
    return PerfilUsuario.fromJson(responseData as Map<String, dynamic>);
  }
}