// lib/src/core/services/tipo_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libratrack_client/src/model/tipo.dart';

/// Servicio para obtener la lista de Tipos de contenido (ej. Serie, Libro).
class TipoService {
  
  // Endpoint público que creamos en 110-CCC
  final String _baseUrl = 'http://10.0.2.2:8080/api/tipos'; 
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token'; 

  /// Método auxiliar para obtener las cabeceras de autenticación (isAuthenticated).
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

  /// Obtiene la lista de todos los Tipos (RF09).
  Future<List<Tipo>> getAllTipos() async {
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
      return jsonList
          .map((json) => Tipo.fromJson(json as Map<String, dynamic>))
          .toList();
          
    } else if (response.statusCode == 403) {
      throw Exception('Sesión inválida o permisos insuficientes.');
    } else {
      throw Exception('Error al cargar Tipos: ${response.statusCode}');
    }
  }
}