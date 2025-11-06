// lib/src/core/services/propuesta_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio para gestionar las llamadas a la API relacionadas con la
/// proposición de nuevo contenido (RF13).
class PropuestaService {
  
  // 1. La dirección base de la API (para el emulador)
  final String _baseUrl = 'http://10.0.2.2:8080/api';
  
  // 2. Acceso al almacenamiento seguro para leer el token
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token'; 

  /// Método auxiliar privado para obtener las cabeceras de autenticación.
  Future<Map<String, String>> _getAuthHeaders() async {
    final String? token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception('No estás autenticado.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// Envía una nueva propuesta de elemento a la cola de moderación (RF13).
  ///
  /// Llama al endpoint 'POST /api/propuestas'.
  ///
  /// @param titulo El título sugerido.
  /// @param descripcion La descripción sugerida.
  /// @param tipo El tipo sugerido (ej. "Serie", "Libro").
  /// @param generos Los géneros sugeridos (ej. "Fantasía, Drama").
  /// @throws Exception Si la API devuelve un error 400 (ej. validación)
  /// o si falla la conexión.
  Future<void> proponerElemento({
    required String titulo,
    required String descripcion,
    required String tipo,
    required String generos,
  }) async {
    
    // 1. Obtiene las cabeceras de autenticación (JWT)
    final Map<String, String> headers = await _getAuthHeaders();

    // 2. Define la URL del endpoint
    final Uri url = Uri.parse('$_baseUrl/propuestas');

    // 3. Prepara el CUERPO (Body) de la petición
    // Las claves DEBEN coincidir con el 'PropuestaRequestDTO' de la API
    // (que sabemos gracias a PropuestaElementoService.java)
    final Map<String, String> body = {
      'tituloSugerido': titulo,
      'descripcionSugerida': descripcion,
      'tipoSugerido': tipo,
      'generosSugeridos': generos,
    };

    http.Response response;

    // 4. (Buena Práctica) Envolver la llamada de red en try...catch
    try {
      response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body), // Enviar el JSON
      );
    } catch (e) {
      // Error de conexión (servidor apagado, etc.)
      throw Exception('Fallo al conectar con el servidor.');
    }

    // 5. Procesar la respuesta de la API
    if (response.statusCode == 201) { // 201 Created
      // ÉXITO
      return; 
      
    } else if (response.statusCode == 400) { // 400 Bad Request
      // Error de Validación (ej. "El título no puede estar vacío")
      // o error del servicio (ej. "Usuario no encontrado")
      throw Exception(response.body); // response.body ya es el string del error
    } else {
      // Otro error (403 Forbidden, 500, etc.)
      throw Exception('Error al enviar la propuesta: ${response.statusCode}');
    }
  }
}