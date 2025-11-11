// Archivo: lib/src/core/utils/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// --- ¡NUEVAS IMPORTACIONES! ---
import 'package:flutter/material.dart'; // Para MaterialPageRoute
import 'package:libratrack_client/main.dart'; // Para el navigatorKey
import 'package:libratrack_client/src/core/services/auth_service.dart'; // Para .logout()
import 'package:libratrack_client/src/features/auth/login_screen.dart'; // Para la navegación

// Definición del cliente HTTP centralizado con manejo de errores
class ApiClient {
  // ... (propiedades _storage, _tokenKey, baseUrl, _instance, _getAuthHeaders sin cambios) ...
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token';
  final String baseUrl = 'http://10.0.2.2:8080/api'; 
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<Map<String, String>> _getAuthHeaders() async {
    final String? token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception('No estás autenticado. Token JWT no encontrado.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', 
    };
  }
  
  // --- ¡NUEVO MÉTODO AUXILIAR! ---
  /// Maneja globalmente un 401/403, borrando el token
  /// y navegando a la pantalla de Login.
  Future<void> _handleGlobalLogout() async {
    // 1. Borra el token inválido del almacenamiento
    await AuthService().logout();
    
    // 2. Navega al Login usando el GlobalKey de main.dart
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
      );
    }
  }


  /// Lógica central para manejar la respuesta HTTP (incluyendo errores 4xx)
  dynamic handleResponse(http.Response response) { 
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 2xx Success
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    }

    // --- ¡LÓGICA 401/403 MODIFICADA! ---
    if (response.statusCode == 401 || response.statusCode == 403) {
      // ¡Llama al manejador global!
      _handleGlobalLogout(); 
      // Lanza la excepción para que la UI sepa que algo falló
      throw Exception('Sesión expirada/no autorizada. Por favor, inicia sesión de nuevo.');
    }
    // --- FIN DE LA MODIFICACIÓN ---

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
    
    // Interpretamos los códigos de estado y lanzamos la excepción con el mensaje limpio
    switch (response.statusCode) {
      // Ya no necesitamos los casos 401/403 aquí
      case 404: 
      case 409: 
      case 400: 
        throw Exception(errorMessage); 
      default:
        throw Exception('Error en la API. Código: ${response.statusCode}. $errorMessage');
    }
  }

  // ===================================================================
  // Métodos CRUD (sin cambios)
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
      // El TRY solo envuelve la llamada de RED
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
      // Error de CONEXIÓN
      throw Exception('Fallo al conectar con el servidor.');
    }

    // Dejamos que handleResponse maneje los códigos 4xx/5xx
    return handleResponse(response);
  }
}

// Exportamos una instancia global
final ApiClient api = ApiClient();