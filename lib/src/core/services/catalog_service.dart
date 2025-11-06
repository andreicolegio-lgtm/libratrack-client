// lib/src/core/services/catalog_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // NUEVO: Importa storage
import 'package:libratrack_client/src/model/catalogo_entrada.dart'; // NUEVO: Importa el modelo

/// Servicio para gestionar todas las llamadas a la API relacionadas con el
/// catálogo personal del usuario (RF05, RF06, RF07, RF08).
class CatalogService {
  
  // 1. La dirección base de la API
  final String _baseUrl = 'http://10.0.2.2:8080/api/catalogo';
  
  // 2. REFACTORIZADO: Acceso directo al almacenamiento seguro
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token'; 

  /// NUEVO: Método auxiliar privado para obtener las cabeceras de autenticación.
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

  /// Obtiene el catálogo personal del usuario autenticado (RF08).
  ///
  /// REFACTORIZADO: Devuelve una lista de 'CatalogoEntrada' con tipo seguro.
  Future<List<CatalogoEntrada>> getMyCatalog() async {
    final Map<String, String> headers = await _getAuthHeaders();
    final Uri url = Uri.parse(_baseUrl); // Llama a GET /api/catalogo

    http.Response response;
    try {
      response = await http.get(url, headers: headers);
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }

    if (response.statusCode == 200) { // 200 OK
      final List<dynamic> jsonList = jsonDecode(response.body);
      
      // Mapea la lista de JSON a una lista de objetos CatalogoEntrada
      return jsonList
          .map((json) => CatalogoEntrada.fromJson(json as Map<String, dynamic>))
          .toList();
          
    } else if (response.statusCode == 403) {
      throw Exception('Sesión inválida. Por favor, inicia sesión de nuevo.');
    } else {
      throw Exception('Error al cargar el catálogo: ${response.statusCode}');
    }
  }
  
  /// Añade un elemento al catálogo personal del usuario (RF05).
  ///
  /// REFACTORIZADO: Devuelve la 'CatalogoEntrada' creada.
  /// @param elementoId El ID del elemento que se va a añadir.
  Future<CatalogoEntrada> addElementoAlCatalogo(int elementoId) async {
    final Map<String, String> headers = await _getAuthHeaders();

    // Llama a: POST /api/catalogo/elementos/{elementoId}
    final Uri url = Uri.parse('$_baseUrl/elementos/$elementoId');

    http.Response response;
    try {
      response = await http.post(url, headers: headers);
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }

    if (response.statusCode == 201) { // 201 Created
      // ÉXITO: La API devuelve la nueva entrada, la decodificamos
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      return CatalogoEntrada.fromJson(jsonMap);
    } else if (response.statusCode == 409) { // 409 Conflict
      throw Exception('Este elemento ya está en tu catálogo.');
    } else if (response.statusCode == 403) {
      throw Exception('Sesión inválida.');
    } else {
      throw Exception('Error al añadir al catálogo: ${response.statusCode}');
    }
  }

  /// --- MÉTODO NUEVO AÑADIDO (RF06, RF07) ---
  
  /// Actualiza el estado y/o el progreso de un elemento en el catálogo.
  ///
  /// @param elementoId El ID del elemento a actualizar.
  /// @param estado El nuevo EstadoPersonal (ej. "EN_PROGRESO").
  /// @param progreso El nuevo texto de progreso (ej. "T2:E5").
  Future<CatalogoEntrada> updateElementoDelCatalogo(
    int elementoId, {
    String? estado,
    String? progreso,
  }) async {
    final Map<String, String> headers = await _getAuthHeaders();
    
    // Llama a: PUT /api/catalogo/elementos/{elementoId}
    final Uri url = Uri.parse('$_baseUrl/elementos/$elementoId');

    // Prepara el body basado en el CatalogoUpdateDTO.java
    final Map<String, String?> body = {
      'estadoPersonal': estado,
      'progresoEspecifico': progreso,
    };

    http.Response response;
    try {
      response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body), // Envía el JSON con los cambios
      );
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }

    if (response.statusCode == 200) { // 200 OK
      // ÉXITO: La API devuelve la entrada actualizada
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      return CatalogoEntrada.fromJson(jsonMap);
    } else if (response.statusCode == 404) { // 404 Not Found
      throw Exception('Este elemento no está en tu catálogo.');
    } else {
      throw Exception('Error al actualizar el elemento: ${response.statusCode}');
    }
  }
  
  /// --- MÉTODO NUEVO AÑADIDO ---
  
  /// Elimina un elemento del catálogo personal del usuario.
  ///
  /// @param elementoId El ID del elemento a eliminar.
  Future<void> removeElementoDelCatalogo(int elementoId) async {
    final Map<String, String> headers = await _getAuthHeaders();
    
    // Llama a: DELETE /api/catalogo/elementos/{elementoId}
    final Uri url = Uri.parse('$_baseUrl/elementos/$elementoId');

    http.Response response;
    try {
      response = await http.delete(url, headers: headers);
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }

    // 204 No Content es la 
    // respuesta estándar de éxito para un DELETE
    if (response.statusCode == 204) {
      return; // Éxito
    } else if (response.statusCode == 404) { // 404 Not Found
      throw Exception('Este elemento no está en tu catálogo.');
    } else {
      throw Exception('Error al eliminar el elemento: ${response.statusCode}');
    }
  }
}