// Archivo: lib/src/core/utils/api_client.dart
// (¡ACTUALIZADO - SPRINT 10: REFRESH TOKENS!)

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';
import 'package:image_picker/image_picker.dart';

const String _accessTokenKey = 'jwt_access_token';
const String _refreshTokenKey = 'jwt_refresh_token';

class ApiClient {
  final String _baseUrl = 'http://10.0.2.2:8080/api';
  
  final FlutterSecureStorage _storage;
  ApiClient(this._storage);

  bool _isRefreshing = false;

  /// Construye las cabeceras para cada petición.
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      // --- ¡CORREGIDO (ID: QA-079)! ---
      // Era 'UTF-F', se ha corregido a 'UTF-8'
      'Content-Type': 'application/json; charset=UTF-8',
      // ---
    };
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- MÉTODOS PÚBLICOS DE PETICIÓN (AHORA CON LÓGICA DE 'RETRY') ---

  // --- ¡CORREGIDO (ID: QA-078)! Añadido 'isAuthEndpoint' ---
  Future<dynamic> get(String endpoint, {bool isAuthEndpoint = false}) async {
    try {
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final response = await http.get(uri, headers: await _getHeaders());
      return _handleResponse(response);
    } on UnauthorizedException {
      if (isAuthEndpoint || _isRefreshing) rethrow; 
      await _handleRefresh(); // Intenta refrescar
      // Reintenta
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final response = await http.get(uri, headers: await _getHeaders());
      return _handleResponse(response);
    } on SocketException {
      throw ConnectionException('Error de conexión. Revisa tu red.');
    } on http.ClientException {
      throw ConnectionException('Error al contactar al servidor.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body, {bool isAuthEndpoint = false}) async {
    try {
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final response = await http.post(
        uri,
        headers: await _getHeaders(),
        body: json.encode(body),
      );
      return _handleResponse(response);
    } on UnauthorizedException {
      if (isAuthEndpoint || _isRefreshing) rethrow;
      await _handleRefresh(); // Intenta refrescar
      // Reintenta
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final response = await http.post(
        uri,
        headers: await _getHeaders(),
        body: json.encode(body),
      );
      return _handleResponse(response);
    } on SocketException {
      throw ConnectionException('Error de conexión. Revisa tu red.');
    } on http.ClientException {
      throw ConnectionException('Error al contactar al servidor.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body, {bool isAuthEndpoint = false}) async {
     try {
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final response = await http.put(
        uri,
        headers: await _getHeaders(),
        body: json.encode(body),
      );
      return _handleResponse(response);
    } on UnauthorizedException {
      if (isAuthEndpoint || _isRefreshing) rethrow;
      await _handleRefresh(); // Intenta refrescar
      // Reintenta
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final response = await http.put(
        uri,
        headers: await _getHeaders(),
        body: json.encode(body),
      );
      return _handleResponse(response);
    } on SocketException {
      throw ConnectionException('Error de conexión. Revisa tu red.');
    } on http.ClientException {
      throw ConnectionException('Error al contactar al servidor.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  Future<dynamic> delete(String endpoint, {bool isAuthEndpoint = false}) async {
    try {
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final response = await http.delete(uri, headers: await _getHeaders());
      return _handleResponse(response);
    } on UnauthorizedException {
      if (isAuthEndpoint || _isRefreshing) rethrow;
      await _handleRefresh(); // Intenta refrescar
      // Reintenta
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final response = await http.delete(uri, headers: await _getHeaders());
      return _handleResponse(response);
    } on SocketException {
      throw ConnectionException('Error de conexión. Revisa tu red.');
    } on http.ClientException {
      throw ConnectionException('Error al contactar al servidor.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  Future<dynamic> upload(String endpoint, XFile file, {bool isAuthEndpoint = false}) async {
    try {
      final response = await _uploadAttempt(endpoint, file);
      return _handleResponse(response);
    } on UnauthorizedException {
      if (isAuthEndpoint || _isRefreshing) rethrow;
      await _handleRefresh(); // Intenta refrescar
      // Reintenta
      final response = await _uploadAttempt(endpoint, file);
      return _handleResponse(response);
    } on SocketException {
      throw ConnectionException('Error de conexión. Revisa tu red.');
    } on http.ClientException {
      throw ConnectionException('Error al contactar al servidor.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado al subir el archivo: ${e.toString()}');
    }
  }

  Future<http.Response> _uploadAttempt(String endpoint, XFile file) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');
    final request = http.MultipartRequest('POST', uri);
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path, filename: file.name),
    );
    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  // --- ¡NUEVA LÓGICA DE REFRESH Y LOGOUT! ---

  /// Llama al endpoint /refresh para obtener un nuevo Access Token.
  Future<void> _handleRefresh() async {
    if (_isRefreshing) {
      await Future.delayed(const Duration(seconds: 2));
      return;
    }
    
    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        throw UnauthorizedException('No hay sesión de refresco.');
      }

      final uri = Uri.parse('$_baseUrl/auth/refresh');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      // --- ¡CORREGIDO (ID: QA-080)! ---
      // No usamos _handleResponse. Parseamos manualmente.
      if (response.statusCode == 200) {
        // Éxito en el refresco
        final data = json.decode(utf8.decode(response.bodyBytes));
        await _storage.write(key: _accessTokenKey, value: data['accessToken']);
        await _storage.write(key: _refreshTokenKey, value: data['refreshToken']);
      } else {
        // El refresco falló (ej. 403, el refresh token caducó)
        // Lanzamos el error para que el 'catch' de abajo llame a logout()
        throw UnauthorizedException('La sesión de refresco ha caducado.');
      }
      // ---

    } catch (e) {
      // Si el refresco falla, cerramos sesión
      await logout();
      // Relanzamos una UnauthorizedException limpia para que la UI llame a logout()
      throw UnauthorizedException('Sesión caducada. Por favor, inicie sesión.');
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    
    if (refreshToken != null) {
      try {
        final uri = Uri.parse('$_baseUrl/auth/logout');
        
        // --- ¡CORREGIDO (ID: QA-081)! ---
        // No usamos _getHeaders() (que usa el Access Token caducado).
        // El RefreshToken en el body es la única autenticación necesaria
        // y el endpoint /logout es 'permitAll'.
        await http.post(
          uri,
          // Usamos una cabecera simple en lugar de _getHeaders()
          headers: {'Content-Type': 'application/json; charset=UTF-8'}, 
          body: json.encode({'refreshToken': refreshToken}),
        );
        // ---
        
      } catch (e) {
        // Ignoramos el error, lo importante es borrar localmente
      }
    }
    
    // Borramos todos los tokens del storage local
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // --- MANEJADOR DE RESPUESTAS INTERNO ---

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      return json.decode(utf8.decode(response.bodyBytes));
    }

    String errorMessage;
    dynamic errorData;
    try {
      if (response.body.isNotEmpty) {
        errorData = json.decode(utf8.decode(response.bodyBytes));
        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['message']?.toString() ?? 'Error desconocido.';
        } else {
          errorMessage = errorData.toString();
        }
      } else {
        errorMessage = 'Error ${response.statusCode}: Sin detalles.';
      }
    } catch (e) {
      errorMessage = utf8.decode(response.bodyBytes);
    }

    switch (response.statusCode) {
      case 400:
        Map<String, dynamic>? errors;
        if (errorData is Map<String, dynamic> && errorData.containsKey('errors')) {
          errors = errorData['errors'] as Map<String, dynamic>?;
        }
        throw BadRequestException(errorMessage, errors);
      case 401:
      case 403:
        throw UnauthorizedException(errorMessage);
      case 404:
        throw NotFoundException(errorMessage);
      case 409:
        throw ConflictException(errorMessage);
      case 500:
      default:
        throw ServerException(errorMessage);
    }
  }
}