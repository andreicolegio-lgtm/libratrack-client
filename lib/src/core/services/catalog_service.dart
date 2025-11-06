import 'dart:convert'; // <-- SOLUCIÓN AL ERROR 1 Y 3
import 'package:http/http.dart' as http; // <-- SOLUCIÓN AL ERROR 2
import 'package:libratrack_client/src/core/services/auth_service.dart'; // Importa AuthService para leer el token

/// Servicio para gestionar todas las llamadas a la API relacionadas con el catálogo.
///
/// Implementa la "mejor práctica" de centralizar las llamadas a la API
/// y de incluir el token JWT en las cabeceras.
class CatalogService {
  
  // 1. La dirección base de la API (para el emulador)
  // (Usamos /api, no /api/auth, como base para este servicio)
  final String _baseUrl = 'http://10.0.2.2:8080/api';
  
  // 2. Instancia de AuthService para acceder al token guardado
  final AuthService _authService = AuthService();

  /// Obtiene el catálogo personal del usuario autenticado (RF08).
  ///
  /// Lanza una [Exception] si la petición falla.
  Future<List<dynamic>> getMyCatalog() async {
    // 3. (Mejor Práctica) Obtener el token guardado
    final String? token = await _authService.getToken();
    if (token == null) {
      throw Exception('No estás autenticado.');
    }

    // 4. (Mejor Práctica) Crear la cabecera (Header) de autenticación
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', // <-- ¡Aquí se usa el token JWT!
    };

    // 5. Definir la URL (endpoint protegido)
    // Esta es la ruta segura que creamos en Spring Boot (CatalogoPersonalController)
    final Uri url = Uri.parse('$_baseUrl/catalogo');

    try {
      // 6. Hacer la petición GET autenticada
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) { // 200 OK
        // Decodifica la respuesta JSON (que será una Lista)
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 403) {
        // El token es inválido o ha caducado
        throw Exception('Sesión inválida. Por favor, inicia sesión de nuevo.');
      } else {
        // Otro error del servidor
        throw Exception('Error al cargar el catálogo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }
  }
  
  /// Añade un elemento al catálogo personal del usuario autenticado (RF05).
  ///
  /// @param elementoId El ID del elemento que se va a añadir.
  Future<void> addElementoAlCatalogo(int elementoId) async {
    final String? token = await _authService.getToken();
    if (token == null) {
      throw Exception('No estás autenticado.');
    }

    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    // La ruta para añadir un elemento: POST /api/catalogo/elementos/{elementoId}
    final Uri url = Uri.parse('$_baseUrl/catalogo/elementos/$elementoId');

    try {
      // Petición POST sin body (todo va en la URL/token)
      final response = await http.post(url, headers: headers);

      if (response.statusCode == 201) { // 201 Created (Éxito)
        return; 
      } else if (response.statusCode == 409) {
        throw Exception('Este elemento ya está en tu catálogo.');
      } else if (response.statusCode == 403) {
        throw Exception('Sesión inválida.');
      } else {
        throw Exception('Error al añadir al catálogo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }
  }
}