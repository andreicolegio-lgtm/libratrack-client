import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:libratrack_client/src/core/services/auth_service.dart'; // Para leer el token

/// Servicio para gestionar todas las llamadas a la API relacionadas con los
/// elementos públicos del catálogo (Búsqueda, Fichas de detalle).
class ElementoService {
  
  // 1. La dirección base de la API (para el emulador)
  final String _baseUrl = 'http://10.0.2.2:8080/api';
  
  // 2. Instancia de AuthService para acceder al token guardado
  final AuthService _authService = AuthService();

  /// Obtiene la lista global de TODOS los elementos (RF09).
  ///
  /// Lanza una [Exception] si la petición falla.
  Future<List<dynamic>> getElementos({String? searchText}) async {
    final String? token = await _authService.getToken();
    if (token == null) {
      throw Exception('No estás autenticado.');
    }

    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    // 1. Lógica para añadir el término de búsqueda a la URL (query parameter)
    String urlString = '$_baseUrl/elementos';
    if (searchText != null && searchText.isNotEmpty) {
      // Si hay texto de búsqueda, lo añade como un query parameter (ej. /elementos?search=fullmetal)
      // Nota: Tu API de Spring Boot DEBE ser actualizada para recibir este parámetro.
      // Por ahora, solo enviamos la URL. (Lo haremos después)
      urlString += '?search=$searchText';
    }
    
    final Uri url = Uri.parse(urlString);

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Sesión inválida. Por favor, inicia sesión de nuevo.');
      } else {
        throw Exception('Error al cargar los elementos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }
  }
  
  /// Obtiene la ficha detallada de un elemento por su ID (RF10).
  ///
  /// Lanza una [Exception] si el elemento no es encontrado (404 Not Found) o si la sesión es inválida.
  Future<Map<String, dynamic>> getElementoById(int elementoId) async {
    final String? token = await _authService.getToken();
    if (token == null) {
      throw Exception('No estás autenticado.');
    }

    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    // 1. Define la URL (ej. /api/elementos/1)
    final Uri url = Uri.parse('$_baseUrl/elementos/$elementoId');

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) { // 200 OK
        // Decodifica la respuesta JSON (que será un Mapa/Objeto)
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('Elemento no encontrado.');
      } else if (response.statusCode == 403) {
        throw Exception('Sesión inválida. Por favor, inicia sesión de nuevo.');
      } else {
        throw Exception('Error al cargar la ficha: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }
  }
}