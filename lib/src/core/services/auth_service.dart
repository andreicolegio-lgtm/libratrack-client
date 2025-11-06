import 'dart:convert'; // Para codificar/decodificar JSON
import 'dart:async'; // Para operaciones asíncronas (Future)
import 'package:http/http.dart' as http; // El paquete HTTP que instalamos
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Importar almacenamiento seguro

/// Servicio de Autenticación (AuthService).
///
/// Esta clase es una "mejor práctica" llamada "Principio de Responsabilidad Única".
/// Su *única* responsabilidad es manejar toda la comunicación
/// relacionada con la autenticación (Registro, Login, guardado de Token)
/// con la API de Spring Boot.
///
/// Las pantallas (Widgets) llamarán a estos métodos en lugar de llamar a 'http' directamente,
/// manteniendo el código de la UI limpio.
class AuthService {
  
  // --- 1. Almacenamiento Seguro (flutter_secure_storage) ---

  // Crea una instancia privada y constante del almacenamiento seguro.
  // Usará Keystore en Android y Keychain en iOS.
  final _storage = const FlutterSecureStorage();
  
  // Define una "llave" (key) constante para guardar nuestro token.
  // Es como el nombre de un archivo en el almacenamiento seguro.
  final String _tokenKey = 'jwt_token'; 

  // --- 2. Configuración de la API ---

  // La dirección IP especial '10.0.2.2' es un alias que el emulador
  // de Android usa para "ver" el 'localhost' (127.0.0.1) de tu PC.
  // Tu API de Spring Boot (que corre en 'localhost:8080')
  // será accesible desde el emulador a través de esta dirección.
  final String _baseUrl = 'http://10.0.2.2:8080/api/auth';

  // ===================================================================
  // MÉTODOS PÚBLICOS (Llamados por las Pantallas)
  // ===================================================================

  /// Llama al endpoint de registro (RF01).
  ///
  /// Envía los datos del usuario a la API.
  /// Lanza una [Exception] si el registro falla (ej. 409 Conflict)
  /// para que la pantalla (UI) pueda mostrar un error.
  Future<void> register(String username, String email, String password) async {
    final Uri registerUrl = Uri.parse('$_baseUrl/register');
    
    // 1. Prepara el cuerpo (Body) de la petición en formato JSON
    final Map<String, String> body = {
      'username': username,
      'email': email,
      'password': password,
    };

    try {
      // 2. Ejecuta la petición POST a la API
      final response = await http.post(
        registerUrl,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body), // Codifica el mapa de Dart a un string JSON
      );

      // 3. Comprueba el código de estado de la respuesta
      if (response.statusCode != 201) { // 201 = Created (Éxito)
        // Si la API devuelve un error (ej. 409 "El email ya existe"),
        // lanza una excepción con el mensaje de error del servidor.
        throw Exception('Error al registrar: ${response.body}');
      }
      
      // Si llegamos aquí, el registro fue exitoso (201).
      
    } catch (e) {
      // Captura errores de red (ej. el servidor está apagado)
      // o la excepción que lanzamos arriba.
      throw Exception('Fallo al conectar con el servidor.');
    }
  }

  /// Llama al endpoint de login (RF02) usando email y contraseña.
  ///
  /// Lanza una [Exception] si el login falla (ej. 401 Unauthorized).
  /// Devuelve el [String] del token JWT si es exitoso.
  Future<String> login(String email, String password) async {
    final Uri loginUrl = Uri.parse('$_baseUrl/login');
    
    // 1. Prepara el cuerpo (Body) de la petición
    final Map<String, String> body = {
      'email': email, // (Corregido para usar email, como solicitaste)
      'password': password,
    };

    try {
      // 2. Ejecuta la petición POST
      final response = await http.post(
        loginUrl,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body),
      );

      // 3. Comprueba el código de estado
      if (response.statusCode == 200) { // 200 = OK (Éxito)
        // Decodifica la respuesta JSON (ej. {"token": "...", "tipo": "Bearer"})
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String token = responseData['token'];

        // 4. ¡MEJOR PRÁCTICA! Guarda el token en el almacenamiento seguro
        await _saveToken(token);
        
        // 5. Devuelve el token a la pantalla (login_screen)
        return token;
      } else {
        // Si la API devuelve 401 (Unauthorized)
        throw Exception('Usuario o contraseña incorrectos.');
      }
    } catch (e) {
      // Captura errores de red
      throw Exception('Fallo al conectar con el servidor.');
    }
  }

  /// Lee el token JWT guardado en el almacenamiento seguro.
  ///
  /// Usado por 'main.dart' para comprobar si el usuario ya ha iniciado sesión.
  /// Devuelve el token (String) si existe, o 'null' si no existe.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Borra el token JWT del almacenamiento seguro (para Logout).
  ///
  /// Usado por la pantalla de Catálogo o Perfil (RF02).
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