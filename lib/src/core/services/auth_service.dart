// Archivo: lib/src/core/services/auth_service.dart
// import 'package:http/http.dart' as http; // <--- ELIMINADO
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Importar almacenamiento seguro
import 'package:libratrack_client/src/core/utils/api_client.dart'; // Importar el nuevo ApiClient

/// Servicio de Autenticación (AuthService).
///
/// REFACTORIZADO: Utiliza ApiClient para el registro y reusa su lógica de errores para el login.
class AuthService {
  
  // --- 1. Almacenamiento Seguro ---
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token'; 

  // --- 2. Configuración de la API ---
  // Esta es ahora la ruta relativa al ApiClient.baseUrl
  final String _authPath = '/auth';

  // ===================================================================
  // MÉTODOS PÚBLICOS
  // ===================================================================

  /// Llama al endpoint de registro (RF01).
  ///
  /// Lanza una [Exception] si el registro falla (ej. 409 Conflict)
  /// para que la pantalla (UI) pueda mostrar un error.
  Future<void> register(String username, String email, String password) async {
    
    final Map<String, String> body = {
      'username': username,
      'email': email,
      'password': password,
    };

    // Usar ApiClient.post. La ruta de registro es pública, ¡usamos protected: false!
    await api.post(
      '$_authPath/register',
      body: body,
      protected: false, // Acceso público
    );
    // Errores (409 Conflict, conexión) gestionados por api.post()
  }

  /// Llama al endpoint de login (RF02) usando email y contraseña.
  ///
  /// Lanza una [Exception] si el login falla (ej. 401 Unauthorized).
  /// Devuelve el [String] del token JWT si es exitoso.
  Future<String> login(String email, String password) async {
    final Map<String, String> body = {
      'email': email,
      'password': password,
    };
    
    // --- INICIO DE LA CORRECCIÓN ---
    try {
      // 1. REFACTORIZADO: Usamos api.post() en lugar de http.post()
      final dynamic responseData = await api.post(
        '$_authPath/login',
        body: body,
        protected: false, // El login es una ruta pública
      );
      
      final String token = responseData['token'];

      // 2. Guarda el token en el almacenamiento seguro
      await _saveToken(token);
      
      return token;

    } on Exception catch (e) {
      // 3. REFACTORIZADO: Si la excepción que viene de handleResponse es 401
      // la convertimos en un mensaje amigable.
      if (e.toString().contains('401') || e.toString().contains('Usuario o contraseña incorrectos')) {
          throw Exception('Usuario o contraseña incorrectos.');
      }
      // Si es "Fallo al conectar con el servidor", la relanza tal cual.
      rethrow;
    }
    // --- FIN DE LA CORRECCIÓN ---
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