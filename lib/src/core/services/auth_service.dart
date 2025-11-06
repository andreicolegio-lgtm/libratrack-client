import 'dart:convert'; // Para codificar/decodificar JSON
import 'dart:async'; // Para operaciones asíncronas (Future)
import 'package:http/http.dart' as http; // El paquete HTTP que instalamos
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Importar almacenamiento seguro

/// Servicio de Autenticación (AuthService).
///
/// Gestiona toda la comunicación de autenticación con la API.
class AuthService {
  
  // --- 1. Almacenamiento Seguro ---
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token'; 

  // --- 2. Configuración de la API ---
  final String _baseUrl = 'http://10.0.2.2:8080/api/auth';

  // ===================================================================
  // MÉTODOS PÚBLICOS
  // ===================================================================

  /// Llama al endpoint de registro (RF01).
  ///
  /// Lanza una [Exception] si el registro falla (ej. 409 Conflict)
  /// para que la pantalla (UI) pueda mostrar un error.
  Future<void> register(String username, String email, String password) async {
    final Uri registerUrl = Uri.parse('$_baseUrl/register');
    
    final Map<String, String> body = {
      'username': username,
      'email': email,
      'password': password,
    };

    // Declaramos 'response' fuera del try
    http.Response response;

    // NUEVO: El bloque 'try...catch' AHORA SOLO envuelve la llamada de red.
    // Su única responsabilidad es capturar errores de CONEXIÓN (ej. servidor apagado).
    try {
      response = await http.post(
        registerUrl,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body), // Codifica el mapa de Dart a un string JSON
      );
    } catch (e) {
      // Si http.post falla (ej. SocketException), lanzamos el error de conexión.
      throw Exception('Fallo al conectar con el servidor.');
    }

    // NUEVO: La lógica de estado HTTP se mueve FUERA del try...catch.
    // Ahora podemos gestionar las respuestas de la API de forma segura.
    if (response.statusCode != 201) { // 201 = Created (Éxito)
      // Si la API devuelve un error (ej. 409 "El email ya existe"),
      // lanzamos una excepción con el MENSAJE REAL del servidor.
      // (En el futuro, podríamos decodificar el JSON del error aquí si quisiéramos)
      throw Exception('Error al registrar: ${response.body}');
    }
    
    // Si llegamos aquí, el registro fue exitoso (201).
  }

  /// Llama al endpoint de login (RF02) usando email y contraseña.
  ///
  /// Lanza una [Exception] si el login falla (ej. 401 Unauthorized).
  /// Devuelve el [String] del token JWT si es exitoso.
  Future<String> login(String email, String password) async {
    final Uri loginUrl = Uri.parse('$_baseUrl/login');
    
    final Map<String, String> body = {
      'email': email,
      'password': password,
    };

    // Declaramos 'response' fuera del try
    http.Response response;

    // NUEVO: El bloque 'try...catch' AHORA SOLO envuelve la llamada de red.
    try {
      response = await http.post(
        loginUrl,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body),
      );
    } catch (e) {
      // Si http.post falla (ej. SocketException), lanzamos el error de conexión.
      throw Exception('Fallo al conectar con el servidor.');
    }

    // NUEVO: La lógica de estado HTTP se mueve FUERA del try...catch.
    if (response.statusCode == 200) { // 200 = OK (Éxito)
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final String token = responseData['token'];

      // Guarda el token en el almacenamiento seguro
      await _saveToken(token);
      
      // Devuelve el token a la pantalla (login_screen)
      return token;
    } else {
      // Si la API devuelve 401 (Unauthorized) u otro error.
      // ¡Ahora SÍ lanzará el mensaje correcto!
      throw Exception('Usuario o contraseña incorrectos.');
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