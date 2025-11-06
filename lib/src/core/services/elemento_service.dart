// lib/src/core/services/elemento_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // NUEVO: Importación directa
import 'package:libratrack_client/src/model/elemento.dart'; // NUEVO: Importa el modelo de datos

/// Servicio para gestionar todas las llamadas a la API relacionadas con los
/// elementos públicos del catálogo (Búsqueda, Fichas de detalle).
class ElementoService {
  
  // 1. La dirección base de la API (para el emulador)
  final String _baseUrl = 'http://10.0.2.2:8080/api';
  
  // 2. NUEVO: Acceso directo al almacenamiento seguro
  // (Mismo patrón que usamos en AuthService)
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token'; 

  /// NUEVO: Método auxiliar privado para obtener las cabeceras de autenticación.
  /// Esto evita repetir código (principio "DRY" - Don't Repeat Yourself).
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

  /// Obtiene la lista global de elementos o busca por título (RF09).
  ///
  /// REFACTORIZADO: Devuelve un Future<`List<Elemento>`> con seguridad de tipos.
  ///
  /// Lanza una [Exception] si la petición falla.
  Future<List<Elemento>> getElementos({String? searchText}) async {
    // 1. Obtiene las cabeceras de autenticación
    final Map<String, String> headers = await _getAuthHeaders();

    // 2. Lógica para añadir el término de búsqueda a la URL (query parameter)
    // (Tu lógica original era correcta)
    String urlString = '$_baseUrl/elementos';
    if (searchText != null && searchText.isNotEmpty) {
      // La API ya está preparada para esto
      urlString += '?search=$searchText';
    }
    
    final Uri url = Uri.parse(urlString);

    http.Response response;

    // 3. (Buena Práctica) Separar error de red de error de API
    try {
      response = await http.get(url, headers: headers);
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }

    // 4. Procesar la respuesta
    if (response.statusCode == 200) {
      // ÉXITO
      
      // Decodifica el JSON en una Lista de mapas dinámicos
      final List<dynamic> jsonList = jsonDecode(response.body);

      // NUEVO: Usa el factory 'Elemento.fromJson' para convertir
      // cada mapa JSON en un objeto Elemento.
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
  ///
  /// REFACTORIZADO: Devuelve un Future<`Elemento`> con seguridad de tipos.
  ///
  /// Lanza una [Exception] si el elemento no es encontrado (404) o la sesión es inválida.
  Future<Elemento> getElementoById(int elementoId) async {
    // 1. Obtiene las cabeceras de autenticación
    final Map<String, String> headers = await _getAuthHeaders();

    // 2. Define la URL (ej. /api/elementos/1)
    final Uri url = Uri.parse('$_baseUrl/elementos/$elementoId');

    http.Response response;

    // 3. Separar error de red de error de API
    try {
      response = await http.get(url, headers: headers);
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }
    
    // 4. Procesar la respuesta
    if (response.statusCode == 200) { // 200 OK
      // ÉXITO
      
      // Decodifica la respuesta JSON (que será un Mapa/Objeto)
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      
      // NUEVO: Usa el factory 'Elemento.fromJson' para devolver un
      // único objeto Elemento.
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