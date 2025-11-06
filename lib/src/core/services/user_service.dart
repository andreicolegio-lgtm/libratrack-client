// lib/src/core/services/user_service.dart
import 'dart:convert'; // Para codificar/decodificar JSON
import 'dart:async'; // Para operaciones asíncronas
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libratrack_client/src/model/perfil_usuario.dart'; // Importa nuestro nuevo modelo

/// Servicio de Usuario (UserService).
///
/// Responsable de gestionar las interacciones con los endpoints
/// de la API relacionados con los datos del usuario (ej. /api/usuarios/...).
class UserService {
  
  // --- Almacenamiento Seguro ---
  // Usamos la misma instancia y clave que el AuthService
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token'; 

  // --- Configuración de la API ---
  final String _baseUrl = 'http://10.0.2.2:8080/api/usuarios';

  /// Obtiene los datos del perfil del usuario actualmente autenticado (RF04).
  ///
  /// Llama al endpoint 'GET /api/usuarios/me' enviando el token JWT.
  /// Devuelve un objeto [PerfilUsuario] si tiene éxito.
  /// Lanza una [Exception] si falla (ej. token inválido, error de red).
  Future<PerfilUsuario> getMiPerfil() async {
    
    // 1. Leer el token JWT del almacenamiento seguro
    final String? token = await _storage.read(key: _tokenKey);

    if (token == null) {
      // Si no hay token, no podemos hacer la llamada.
      throw Exception('Usuario no autenticado. Inicie sesión de nuevo.');
    }

    // 2. Preparar la llamada a la API
    final Uri url = Uri.parse('$_baseUrl/me');
    
    // ¡Crucial! Preparamos las cabeceras (headers) con el token JWT.
    // Así es como Spring Security sabe quiénes somos.
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', // Añadimos el token Bearer
    };

    http.Response response;

    // 3. (Buena Práctica) El 'try...catch' solo envuelve la llamada de red
    // (Aprendido en 110-N)
    try {
      response = await http.get(
        url,
        headers: headers,
      );
    } catch (e) {
      // Error de conexión (servidor apagado, sin internet)
      throw Exception('Fallo al conectar con el servidor.');
    }

    // 4. Procesar la respuesta de la API
    if (response.statusCode == 200) {
      // Éxito (200 OK)
      
      // Decodifica el cuerpo de la respuesta (el JSON)
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      // Usa nuestro 'factory constructor' para convertir el JSON en un objeto
      return PerfilUsuario.fromJson(responseData);
      
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // Error de autenticación (Token inválido o expirado)
      // (En el futuro, podríamos forzar un logout aquí)
      throw Exception('Sesión inválida o expirada. Por favor, inicie sesión de nuevo.');
    } else {
      // Otro error del servidor (ej. 500 Internal Server Error)
      throw Exception('Error al obtener el perfil: ${response.body}');
    }
  }

  // (En el futuro, aquí irían otros métodos, como:
  // Future<PerfilUsuario> actualizarPerfil(String nuevoUsername) async {...}
  // )
}