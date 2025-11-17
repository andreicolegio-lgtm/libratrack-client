import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_exceptions.dart';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

const String _accessTokenKey = 'jwt_access_token';
const String _refreshTokenKey = 'jwt_refresh_token';

class ApiClient {
  final String _baseUrl = 'http://10.0.2.2:8080/api';

  final FlutterSecureStorage _storage;
  ApiClient(this._storage);

  bool _isRefreshing = false;

  Future<Map<String, String>> _getHeaders() async {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    final String? token = await _storage.read(key: _accessTokenKey);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint,
      {Map<String, String>? queryParams, bool isAuthEndpoint = false}) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/$endpoint')
          .replace(queryParameters: queryParams);
      final http.Response response =
          await http.get(uri, headers: await _getHeaders());
      return _handleResponse(response);
    } on UnauthorizedException {
      if (isAuthEndpoint || _isRefreshing) {
        rethrow;
      }
      await _handleRefresh();
      final Uri uri = Uri.parse('$_baseUrl/$endpoint');
      final http.Response response =
          await http.get(uri, headers: await _getHeaders());
      return _handleResponse(response);
    } on SocketException {
      throw ConnectionException('Error de conexión. Revisa tu red.');
    } on http.ClientException {
      throw ConnectionException('Error al contactar al servidor.');
    } catch (e, stack) {
      debugPrint('ApiClient.get error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Stacktrace: $stack');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body,
      {bool isAuthEndpoint = false}) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/$endpoint');
      final http.Response response = await http.post(
        uri,
        headers: await _getHeaders(),
        body: json.encode(body),
      );
      return _handleResponse(response);
    } on UnauthorizedException {
      if (isAuthEndpoint || _isRefreshing) {
        rethrow;
      }
      await _handleRefresh();
      final Uri uri = Uri.parse('$_baseUrl/$endpoint');
      final http.Response response = await http.post(
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
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body,
      {bool isAuthEndpoint = false}) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/$endpoint');
      final headers = await _getHeaders();
      debugPrint('[ApiClient.put] PUT $uri');
      debugPrint('[ApiClient.put] Headers: $headers');
      debugPrint('[ApiClient.put] Body: $body');
      final http.Response response = await http.put(
        uri,
        headers: headers,
        body: json.encode(body),
      );
      debugPrint('[ApiClient.put] Response status: ${response.statusCode}');
      debugPrint('[ApiClient.put] Response body: ${response.body}');
      return _handleResponse(response);
    } on UnauthorizedException {
      if (isAuthEndpoint || _isRefreshing) {
        rethrow;
      }
      await _handleRefresh();
      final Uri uri = Uri.parse('$_baseUrl/$endpoint');
      final http.Response response = await http.put(
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
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  Future<dynamic> delete(String endpoint, {bool isAuthEndpoint = false}) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/$endpoint');
      final http.Response response =
          await http.delete(uri, headers: await _getHeaders());
      return _handleResponse(response);
    } on UnauthorizedException {
      if (isAuthEndpoint || _isRefreshing) {
        rethrow;
      }
      await _handleRefresh();
      final Uri uri = Uri.parse('$_baseUrl/$endpoint');
      final http.Response response =
          await http.delete(uri, headers: await _getHeaders());
      return _handleResponse(response);
    } on SocketException {
      throw ConnectionException('Error de conexión. Revisa tu red.');
    } on http.ClientException {
      throw ConnectionException('Error al contactar al servidor.');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  Future<dynamic> upload(String endpoint, XFile file,
      {bool isAuthEndpoint = false}) async {
    try {
      final http.Response response = await _uploadAttempt(endpoint, file);
      return _handleResponse(response);
    } on UnauthorizedException {
      if (isAuthEndpoint || _isRefreshing) {
        rethrow;
      }
      await _handleRefresh();
      final http.Response response = await _uploadAttempt(endpoint, file);
      return _handleResponse(response);
    } on SocketException {
      throw ConnectionException('Error de conexión. Revisa tu red.');
    } on http.ClientException {
      throw ConnectionException('Error al contactar al servidor.');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
          'Error inesperado al subir el archivo: ${e.toString()}');
    }
  }

  Future<http.Response> _uploadAttempt(String endpoint, XFile file) async {
    final Uri uri = Uri.parse('$_baseUrl/$endpoint');
    final http.MultipartRequest request = http.MultipartRequest('POST', uri);
    final String? token = await _storage.read(key: _accessTokenKey);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path, filename: file.name),
    );
    final http.StreamedResponse streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) {
      await Future.delayed(const Duration(seconds: 2));
      return;
    }

    _isRefreshing = true;

    try {
      final String? refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        throw UnauthorizedException('No hay sesión de refresco.');
      }

      final Uri uri = Uri.parse('$_baseUrl/auth/refresh');
      final http.Response response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: json.encode(<String, String>{'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        await _storage.write(key: _accessTokenKey, value: data['accessToken']);
        await _storage.write(
            key: _refreshTokenKey, value: data['refreshToken']);
      } else {
        throw UnauthorizedException('La sesión de refresco ha caducado.');
      }
    } catch (e) {
      await logout();
      throw UnauthorizedException('Sesión caducada. Por favor, inicie sesión.');
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> logout() async {
    final String? refreshToken = await _storage.read(key: _refreshTokenKey);

    if (refreshToken != null) {
      try {
        final Uri uri = Uri.parse('$_baseUrl/auth/logout');

        await http.post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8'
          },
          body: json.encode(<String, String>{'refreshToken': refreshToken}),
        );
      } catch (e) {
        // Error silenciado intencionalmente
      }
    }

    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      return json.decode(utf8.decode(response.bodyBytes));
    }

    String errorKey = 'INTERNAL_SERVER_ERROR';
    dynamic errorData;
    try {
      if (response.body.isNotEmpty) {
        errorData = json.decode(utf8.decode(response.bodyBytes));
        if (errorData is Map<String, dynamic>) {
          errorKey = errorData['error']?.toString() ?? 'INTERNAL_SERVER_ERROR';
        }
      }
    } catch (e) {
      // fallback to default error key
    }

    switch (response.statusCode) {
      case 400:
        Map<String, dynamic>? errors;
        if (errorData is Map<String, dynamic> &&
            errorData.containsKey('errors')) {
          errors = errorData['errors'] as Map<String, dynamic>?;
        }
        throw BadRequestException(errorKey, errors);
      case 401:
      case 403:
        throw UnauthorizedException(errorKey);
      case 404:
        throw NotFoundException(errorKey);
      case 409:
        throw ConflictException(errorKey);
      case 500:
      default:
        throw ServerException(errorKey);
    }
  }
}
