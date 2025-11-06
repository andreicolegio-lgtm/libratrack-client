// lib/src/core/services/resena_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libratrack_client/src/model/resena.dart'; // Importa el modelo

/// Servicio para gestionar las llamadas a la API relacionadas con las Reseñas (RF12).
class ResenaService {
  
  final String _baseUrl = 'http://10.0.2.2:8080/api/resenas';
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

  /// Obtiene la lista de reseñas de un elemento (RF12).
  ///
  /// Llama a 'GET /api/resenas/elemento/{elementoId}'.
  Future<List<Resena>> getResenas(int elementoId) async {
    final Map<String, String> headers = await _getAuthHeaders();
    final Uri url = Uri.parse('$_baseUrl/elemento/$elementoId');

    http.Response response;
    try {
      response = await http.get(url, headers: headers);
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }

    if (response.statusCode == 200) { // 200 OK
      final List<dynamic> jsonList = jsonDecode(response.body);
      
      // Mapea la lista de JSON a una lista de objetos Resena
      return jsonList
          .map((json) => Resena.fromJson(json as Map<String, dynamic>))
          .toList();
          
    } else if (response.statusCode == 403) {
      throw Exception('Sesión inválida. Por favor, inicia sesión de nuevo.');
    } else {
      throw Exception('Error al cargar las reseñas: ${response.statusCode}');
    }
  }

  /// Crea una nueva reseña para un elemento (RF12).
  ///
  /// Llama a 'POST /api/resenas'.
  /// Devuelve la reseña creada (que incluye el ID y la fecha).
  Future<Resena> crearResena({
    required int elementoId,
    required int valoracion,
    String? textoResena,
  }) async {
    final Map<String, String> headers = await _getAuthHeaders();
    final Uri url = Uri.parse(_baseUrl);

    // Prepara el body basado en el 'ResenaDTO.java'
    final Map<String, dynamic> body = {
      'elementoId': elementoId,
      'valoracion': valoracion,
      'textoResena': textoResena,
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

    if (response.statusCode == 201) { // 201 Created
      // ÉXITO: La API devuelve la nueva reseña creada
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      return Resena.fromJson(jsonMap);
      
    } else if (response.statusCode == 409) { // 409 Conflict
      // Captura el error "Ya has reseñado este elemento."
      throw Exception(response.body);
    } else {
      throw Exception('Error al enviar la reseña: ${response.body}');
    }
  }
}