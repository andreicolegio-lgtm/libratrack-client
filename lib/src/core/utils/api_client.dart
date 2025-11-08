// Archivo: lib/src/core/utils/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Definición del cliente HTTP centralizado con manejo de errores
class ApiClient {
  // Almacenamiento seguro (para el token)
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token';
  
  // URL base: ¡HECHO PÚBLICO!
  final String baseUrl = 'http://10.0.2.2:8080/api'; 

  // Acceso a esta instancia desde cualquier lugar
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Obtiene las cabeceras de autenticación (JWT)
  Future<Map<String, String>> _getAuthHeaders() async {
    final String? token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception('No estás autenticado. Token JWT no encontrado.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', // Añade el token 'Bearer'
    };
  }

  /// Lógica central para manejar la respuesta HTTP (incluyendo errores 4xx)
  // ¡HECHO PÚBLICO!
  dynamic handleResponse(http.Response response) { 
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 2xx Success. Si el body está vacío (ej. 204 No Content), devolvemos null
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    }

    // --- Mapeo de Errores de la API (4xx, 5xx) ---
    String errorMessage = 'Error desconocido: ${response.statusCode}';
    
    // Intentamos extraer el mensaje de error que el backend (GlobalExceptionHandler) devolvió
    if (response.body.isNotEmpty) {
      try {
        final dynamic errorBody = jsonDecode(response.body);
        
        // Si el body es un JSON con el mensaje (ej. de 400 Validation, o 404/409)
        if (errorBody is Map && errorBody.containsKey('message')) {
           errorMessage = errorBody['message'] as String;
        } else if (errorBody is String) {
           errorMessage = errorBody;
        } else {
          // A veces Spring devuelve un string plano para 400/409, o un mapa simple
          errorMessage = response.body; 
        }
      } on FormatException {
        // El cuerpo no es JSON (ej. Bad Request/Conflict simple)
        errorMessage = response.body;
      } catch (_) {
        // Fallback
      }
    }
    
    // Interpretamos los códigos de estado y lanzamos la excepción con el mensaje limpio
    switch (response.statusCode) {
      case 401:
      case 403:
        throw Exception('Sesión expirada/no autorizada. Por favor, inicia sesión de nuevo.');
      case 404: // ResourceNotFoundException
      case 409: // ConflictException
      case 400: // Validation/Bad Request (aunque este debería ser manejado por @Valid)
        // El mensaje de error ya contiene el texto que el backend lanzó (ej. "Elemento no encontrado" o "Contraseña incorrecta")
        throw Exception(errorMessage); 
      default:
        throw Exception('Error en la API. Código: ${response.statusCode}. $errorMessage');
    }
  }

  // ===================================================================
  // Métodos CRUD simplificados para servicios
  // ===================================================================
  
  Future<dynamic> post(String path, {dynamic body, bool protected = true}) =>
      _sendRequest(path, 'POST', body: body, protected: protected);

  Future<dynamic> get(String path, {Map<String, String>? queryParams, bool protected = true}) =>
      _sendRequest(path, 'GET', queryParams: queryParams, protected: protected);

  Future<dynamic> put(String path, {dynamic body}) =>
      _sendRequest(path, 'PUT', body: body);

  Future<dynamic> delete(String path) =>
      _sendRequest(path, 'DELETE');
      
  /// Única función que realiza la petición y gestiona errores de conexión/API.
  Future<dynamic> _sendRequest(
    String path, 
    String method, 
    {dynamic body, Map<String, String>? queryParams, bool protected = true}) async {
    
    // ¡USAMOS EL NUEVO CAMPO PÚBLICO!
    Uri url = Uri.parse('$baseUrl$path');
    
    // Añadir Query Parameters si existen
    if (queryParams != null && queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }
    
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    
    // Añadir el token si es una ruta protegida
    if (protected) {
      final Map<String, String> authHeaders = await _getAuthHeaders();
      headers.addAll(authHeaders);
    }

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }
      return handleResponse(response); // ¡USAMOS EL NUEVO MÉTODO PÚBLICO!
    } catch (e) {
      // Capturamos errores de red (ej. SocketException)
      if (e is Exception && !e.toString().contains('Exception: Sesión expirada')) {
        throw Exception('Fallo al conectar con el servidor.');
      }
      rethrow;
    }
  }
}

// Exportamos una instancia global para fácil acceso en los servicios
final ApiClient api = ApiClient();