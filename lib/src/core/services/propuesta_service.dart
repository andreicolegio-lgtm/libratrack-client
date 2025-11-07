// lib/src/core/services/propuesta_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio para gestionar las llamadas a la API relacionadas con la
/// proposición de nuevo contenido (RF13).
class PropuestaService {
  
  final String _baseUrl = 'http://10.0.2.2:8080/api';
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token'; 

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
  /// @param imagenUrl (NUEVO) La URL de la imagen de portada.
  Future<void> proponerElemento({
    required String titulo,
    required String descripcion,
    required String tipo,
    required String generos,
    String? imagenUrl, // <--- ¡PARÁMETRO AÑADIDO!
  }) async {
    
    final Map<String, String> headers = await _getAuthHeaders();
    final Uri url = Uri.parse('$_baseUrl/propuestas');

    // Las claves DEBEN coincidir con el 'PropuestaRequestDTO' de la API
    final Map<String, String?> body = {
      'tituloSugerido': titulo,
      'descripcionSugerida': descripcion,
      'tipoSugerido': tipo,
      'generosSugeridos': generos,
      'imagenPortadaUrl': imagenUrl, // <--- ¡AÑADIDO AL CUERPO!
    };

    http.Response response;

    try {
      response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }

    if (response.statusCode == 201) {
      return; 
    } else if (response.statusCode == 400) {
      throw Exception(response.body);
    } else {
      throw Exception('Error al enviar la propuesta: ${response.body}');
    }
  }
}