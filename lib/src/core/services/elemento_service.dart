// lib/src/core/services/elemento_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import 'package:libratrack_client/src/model/elemento.dart'; 

/// Servicio para gestionar todas las llamadas a la API relacionadas con los
/// elementos públicos del catálogo (Búsqueda, Fichas de detalle).
class ElementoService {
  
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

  /// Obtiene la lista global de elementos o busca por los 3 criterios (RF09).
  ///
  /// REFACTORIZADO: Ahora acepta los 3 parámetros de filtro.
  Future<List<Elemento>> getElementos({
    String? searchText,
    String? tipoName,       // NUEVO
    String? generoName,     // NUEVO
  }) async {
    
    final Map<String, String> headers = await _getAuthHeaders();

    // 1. Construir el Mapa de Query Parameters
    final Map<String, String> queryParams = {};
    if (searchText != null && searchText.isNotEmpty) {
      queryParams['search'] = searchText;
    }
    // NUEVO: Añadir los parámetros de Tipo y Género si no son nulos
    if (tipoName != null && tipoName.isNotEmpty) {
      queryParams['tipo'] = tipoName; // Coincide con @RequestParam(value="tipo")
    }
    if (generoName != null && generoName.isNotEmpty) {
      queryParams['genero'] = generoName; // Coincide con @RequestParam(value="genero")
    }

    // 2. Construir la URL completa con los parámetros
    Uri url = Uri.parse('$_baseUrl/elementos');
    if (queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
    }
    
    http.Response response;

    try {
      response = await http.get(url, headers: headers);
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((json) => Elemento.fromJson(json as Map<String, dynamic>))
          .toList();
          
    } else if (response.statusCode == 403) {
      throw Exception('Sesión inválida. Por favor, inicia sesión de nuevo.');
    } else {
      throw Exception('Error al cargar los elementos: ${response.statusCode}');
    }
  }
  
  /// Obtiene la ficha detallada de un elemento por su ID (RF10).
  /// [Preservado]
  Future<Elemento> getElementoById(int elementoId) async {
    // ... (código getElementoById sin cambios)
    final Map<String, String> headers = await _getAuthHeaders();
    final Uri url = Uri.parse('$_baseUrl/elementos/$elementoId');
    http.Response response;

    try {
      response = await http.get(url, headers: headers);
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }
    
    if (response.statusCode == 200) { 
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      return Elemento.fromJson(jsonMap);
    } else if (response.statusCode == 404) {
      throw Exception('Elemento no encontrado.');
    } else if (response.statusCode == 403) {
      throw Exception('Sesión inválida. Por favor, inicia sesión de nuevo.');
    } else {
      throw Exception('Error al cargar la ficha: ${response.statusCode}');
    }
  }
}