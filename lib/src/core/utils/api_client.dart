// Archivo: lib/src/core/utils/api_client.dart
import 'dart:convert';
import 'dart:io'; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:http_parser/http_parser.dart'; // <-- ¡NUEVA IMPORTACIÓN!
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart'; 
import 'package:libratrack_client/main.dart'; 
import 'package:libratrack_client/src/core/services/auth_service.dart'; 
import 'package:libratrack_client/src/features/auth/login_screen.dart'; 

// Definición del cliente HTTP centralizado con manejo de errores
class ApiClient {
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token';
  final String baseUrl = 'http://10.0.2.2:8080/api'; 
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Obtiene las cabeceras de autenticación (JWT)
  Future<Map<String, String>> _getAuthHeaders() async {
    final String? token = await _storage.read(key: _tokenKey);
    if (token == null) {
      // Si el token no se encuentra, manejamos el logout global
      await _handleGlobalLogout();
      throw Exception('No estás autenticado. Token JWT no encontrado.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', 
    };
  }
  
  /// Maneja globalmente un 401/403
  Future<void> _handleGlobalLogout() async {
    await AuthService().logout();
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false, 
      );
    }
  }

  /// Lógica central para manejar la respuesta HTTP (incluyendo errores 4xx)
  dynamic handleResponse(http.Response response) { 
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      _handleGlobalLogout(); 
      throw Exception('Sesión expirada/no autorizada. Por favor, inicia sesión de nuevo.');
    }

    String errorMessage = 'Error desconocido: ${response.statusCode}';
    if (response.body.isNotEmpty) {
      try {
        final dynamic errorBody = jsonDecode(response.body);
        if (errorBody is Map && errorBody.containsKey('message')) {
           errorMessage = errorBody['message'] as String;
        } else if (errorBody is String) {
           errorMessage = errorBody;
        } else {
          errorMessage = response.body; 
        }
      } on FormatException {
        errorMessage = response.body;
      } catch (_) {
        // Fallback
      }
    }
    
    switch (response.statusCode) {
      case 404: 
      case 409: 
      case 400: 
        throw Exception(errorMessage); 
      default:
        throw Exception('Error en la API. Código: ${response.statusCode}. $errorMessage');
    }
  }

  // ===================================================================
  // --- ¡NUEVO MÉTODO DE SUBIDA DE ARCHIVOS! (Sprint 3) ---
  // ===================================================================

  /// Sube un archivo (ej. imagen) al endpoint de 'uploads'.
  /// @param file El archivo a subir.
  /// @return La URL pública devuelta por el servidor.
  Future<String> upload(File file) async {
    final Uri url = Uri.parse('$baseUrl/uploads');
    
    // 1. Obtener el token (¡las subidas están protegidas!)
    final String? token = await _storage.read(key: _tokenKey);
    if (token == null) {
      _handleGlobalLogout();
      throw Exception('No estás autenticado.');
    }
    final Map<String, String> headers = {
      'Authorization': 'Bearer $token',
    };

    // 2. Crear la petición Multipart
    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);

    // 3. Adjuntar el archivo
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Este 'file' DEBE coincidir con @RequestParam("file") en el controlador
        file.path,
        filename: p.basename(file.path), // Envía el nombre del archivo
        contentType: MediaType('image', p.extension(file.path).substring(1)), // Ej. image/jpeg
      ),
    );

    try {
      // 4. Enviar la petición
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // 5. Reutilizar nuestro manejador de respuestas
      final dynamic responseData = handleResponse(response);
      
      // 6. Devolver la URL
      if (responseData is Map && responseData.containsKey('url')) {
        return responseData['url'] as String;
      } else {
        throw Exception("La API no devolvió una URL válida.");
      }
      
    } catch (e) {
      // Capturamos errores de red o de handleResponse
      throw Exception('Fallo al subir el archivo: ${e.toString()}');
    }
  }
  
  // ===================================================================
  // Métodos CRUD (JSON)
  // ===================================================================
  
  Future<dynamic> post(String path, {dynamic body, bool protected = true}) =>
      _sendRequest(path, 'POST', body: body, protected: protected);

  Future<dynamic> get(String path, {Map<String, String>? queryParams, bool protected = true}) =>
      _sendRequest(path, 'GET', queryParams: queryParams, protected: protected);

  Future<dynamic> put(String path, {dynamic body}) =>
      _sendRequest(path, 'PUT', body: body);

  Future<dynamic> delete(String path) =>
      _sendRequest(path, 'DELETE');
      
  /// Función de envío para JSON
  Future<dynamic> _sendRequest(
    String path, 
    String method, 
    {dynamic body, Map<String, String>? queryParams, bool protected = true}) async {
    
    Uri url = Uri.parse('$baseUrl$path');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }
    
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    
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
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }

    return handleResponse(response);
  }
}

// Exportamos una instancia global
final ApiClient api = ApiClient();