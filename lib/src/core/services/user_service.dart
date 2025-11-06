// lib/src/core/services/user_service.dart
import 'dart:convert'; // Para codificar/decodificar JSON
import 'dart:async'; // Para operaciones asíncronas
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libratrack_client/src/model/perfil_usuario.dart'; // Importa nuestro modelo

/// Servicio de Usuario (UserService).
class UserService {
  
  // --- Almacenamiento Seguro ---
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token'; 

  // --- Configuración de la API ---
  final String _baseUrl = 'http://10.0.2.2:8080/api/usuarios';

  /// Obtiene los datos del perfil del usuario (RF04).
  /// [Tu método existente, 100% preservado]
  Future<PerfilUsuario> getMiPerfil() async {
    // ... (código existente de getMiPerfil)
    final String? token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception('Usuario no autenticado. Inicie sesión de nuevo.');
    }
    final Uri url = Uri.parse('$_baseUrl/me');
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
    http.Response response;
    try {
      response = await http.get(url, headers: headers);
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return PerfilUsuario.fromJson(responseData);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sesión inválida o expirada. Por favor, inicie sesión de nuevo.');
    } else {
      throw Exception('Error al obtener el perfil: ${response.body}');
    }
  }

  /// Actualiza el 'username' del usuario (RF04).
  /// [Tu método existente, 100% preservado]
  Future<PerfilUsuario> updateMiPerfil(String nuevoUsername) async {
    // ... (código existente de updateMiPerfil)
    final String? token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception('Usuario no autenticado.');
    }
    final Uri url = Uri.parse('$_baseUrl/me');
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
    final Map<String, String> body = {
      'username': nuevoUsername,
    };
    http.Response response;
    try {
      response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return PerfilUsuario.fromJson(responseData);
    } else if (response.statusCode == 400) {
      throw Exception(response.body);
    } else {
      throw Exception('Error al actualizar el perfil: ${response.body}');
    }
  }

  /// --- MÉTODO NUEVO AÑADIDO (RF04 - Cambio de Contraseña) --- ///
  
  /// Cambia la contraseña del usuario.
  ///
  /// Llama al endpoint 'PUT /api/usuarios/me/password'.
  /// @param contraseñaActual La contraseña actual del usuario (para verificación).
  /// @param nuevaContraseña La nueva contraseña a establecer.
  /// @throws Exception Si la contraseña actual es incorrecta (Error 400) o falla la conexión.
  Future<void> changePassword(String contrasenaActual, String nuevaContrasena) async {
    
    // 1. Leer el token (necesario para la autorización)
    final String? token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception('Usuario no autenticado.');
    }

    // 2. Preparar la URL y las cabeceras
    // ¡NUEVO ENDPOINT!
    final Uri url = Uri.parse('$_baseUrl/me/password'); 
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    // 3. Preparar el CUERPO (Body) de la petición
    // Corresponde a nuestro 'PasswordChangeDTO.java'
    final Map<String, String> body = {
      'contraseñaActual': contrasenaActual,
      'nuevaContraseña': nuevaContrasena,
    };

    http.Response response;

    // 4. (Buena Práctica) Envolver la llamada de red en try...catch
    try {
      response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      // Error de conexión (servidor apagado, etc.)
      throw Exception('Fallo al conectar con el servidor.');
    }

    // 5. Procesar la respuesta de la API
    if (response.statusCode == 200) {
      // Éxito (200 OK)
      // No necesitamos devolver nada, solo saber que funcionó.
      return; 
      
    } else if (response.statusCode == 400) {
      // Error de Validación (400 Bad Request)
      // Esto captura el error "La contraseña actual es incorrecta."
      // que programamos en 'UsuarioService.java'
      throw Exception(response.body); // response.body ya es el string del error
    } else {
      // Otro error (401, 500, etc.)
      throw Exception('Error al cambiar la contraseña: ${response.body}');
    }
  }
}