// Archivo: lib/src/core/services/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import 'package:libratrack_client/src/core/utils/api_client.dart'; 
import 'package:libratrack_client/src/model/perfil_usuario.dart'; 

/// Servicio de Autenticación (AuthService).
/// --- ¡ACTUALIZADO Y CORREGIDO (Sprint 4)! ---
class AuthService {
  
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token'; 
  final String _authPath = '/auth';

  // ===================================================================
  // MÉTODOS PÚBLICOS
  // ===================================================================

  /// Llama al endpoint de registro (RF01).
  ///
  /// --- ¡CORREGIDO! ---
  /// 1. Ahora devuelve 'PerfilUsuario' para coincidir con la API.
  /// 2. Ahora tiene un try-catch para manejar los errores 409 (Conflicto).
  Future<PerfilUsuario> register(String username, String email, String password) async {
    
    final Map<String, String> body = {
      'username': username,
      'email': email,
      'password': password,
    };

    try {
      // ApiClient.post ahora devolverá un Map<String, dynamic>
      final dynamic responseData = await api.post(
        '$_authPath/register',
        body: body,
        protected: false, 
      );
      
      // Mapeamos la respuesta al modelo de Flutter
      return PerfilUsuario.fromJson(responseData as Map<String, dynamic>);

    } catch (e) {
      // Si api.post() lanza un 409, lo relanzamos para que la UI lo atrape
      rethrow; 
    }
  }

  /// Llama al endpoint de login (RF02) usando email y contraseña.
  ///
  /// --- ¡REFACTORIZADO! ---
  /// Ahora usa api.post() en lugar de http.post() manual.
  Future<String> login(String email, String password) async {
    final Map<String, String> body = {
      'email': email,
      'password': password,
    };
    
    try {
      // 1. Usamos api.post()
      final dynamic responseData = await api.post(
        '$_authPath/login',
        body: body,
        protected: false, 
      );
      
      final String token = responseData['token'];

      // 2. Guarda el token en el almacenamiento seguro
      await _saveToken(token);
      
      return token;

    } on Exception catch (e) {
      // 3. Convertimos el error 401 en un mensaje amigable
      if (e.toString().contains('401') || e.toString().contains('Usuario o contraseña incorrectos')) {
          throw Exception('Usuario o contraseña incorrectos.');
      }
      rethrow;
    }
  }

  /// Lee el token JWT guardado en el almacenamiento seguro.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Borra el token JWT del almacenamiento seguro (para Logout).
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  // ===================================================================
  // MÉTODOS PRIVADOS (Auxiliares)
  // ===================================================================

  /// Método auxiliar privado para guardar el token JWT
  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }
}