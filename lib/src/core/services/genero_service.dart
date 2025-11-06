// lib/src/core/services/genero_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libratrack_client/src/model/genero.dart';

/// Servicio para obtener la lista de Géneros de contenido (ej. Fantasía, Drama).
class GeneroService {
  
  final String _baseUrl = 'http://10.0.2.2:8080/api/generos'; 
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

  /// Obtiene la lista de todos los Géneros (RF09).
  Future<List<Genero>> getAllGeneros() async {
    final Map<String, String> headers = await _getAuthHeaders();
    final Uri url = Uri.parse(_baseUrl);

    http.Response response;
    try {
      response = await http.get(url, headers: headers);
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      // El JSON ahora viene del GeneroResponseDTO
      return jsonList
          .map((json) => Genero.fromJson(json as Map<String, dynamic>))
          .toList();
          
    } else if (response.statusCode == 403) {
      throw Exception('Sesión inválida o permisos insuficientes.');
    } else {
      throw Exception('Error al cargar Géneros: ${response.statusCode}');
    }
  }
}