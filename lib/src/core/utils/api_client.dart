import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Para MediaType
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../config/environment_config.dart';
import 'api_exceptions.dart';

const String _accessTokenKey = 'jwt_access_token';
const String _refreshTokenKey = 'jwt_refresh_token';

/// Cliente HTTP centralizado que maneja autenticación, refresco de tokens y errores.
class ApiClient {
  final String _baseUrl = EnvironmentConfig.apiUrl;
  final FlutterSecureStorage _storage;

  // Evita bucles infinitos de refresco si varias peticiones fallan a la vez
  bool _isRefreshing = false;

  ApiClient(this._storage);

  /// Obtiene los encabezados estándar incluyendo el token de acceso si existe.
  Future<Map<String, String>> _getHeaders() async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    final String? token = await _storage.read(key: _accessTokenKey);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- Métodos HTTP Públicos ---

  Future<dynamic> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final uri =
        Uri.parse('$_baseUrl/$endpoint').replace(queryParameters: queryParams);
    // Pasamos una función anónima que realiza la petición para poder reintentarla
    return _request(
        () async => http.get(uri, headers: await _getHeadersFuture()));
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body,
      {bool isAuthEndpoint = false}) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');
    return _request(
      () async => http.post(uri,
          headers: await _getHeadersFuture(), body: jsonEncode(body)),
      isAuthEndpoint: isAuthEndpoint,
    );
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');
    return _request(() async => http.put(uri,
        headers: await _getHeadersFuture(), body: jsonEncode(body)));
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');
    return _request(
        () async => http.delete(uri, headers: await _getHeadersFuture()));
  }

  /// Sube un archivo (imagen) al servidor.
  Future<dynamic> upload(String endpoint, XFile file) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');

    // Función envoltorio para el multipart request
    Future<http.Response> uploadRequest() async {
      final request = http.MultipartRequest('POST', uri);
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Detectar mime type básico por extensión
      var mimeType = MediaType('application', 'octet-stream');
      final extension = path.extension(file.path).toLowerCase();
      if (extension == '.jpg' || extension == '.jpeg') {
        mimeType = MediaType('image', 'jpeg');
      }
      if (extension == '.png') {
        mimeType = MediaType('image', 'png');
      }

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mimeType,
      ));

      final streamedResponse = await request.send();
      return http.Response.fromStream(streamedResponse);
    }

    return _request(uploadRequest);
  }

  // --- Lógica Interna ---

  // Helper para obtener headers de forma asíncrona directa (necesario para _request)
  Future<Map<String, String>> _getHeadersFuture() => _getHeaders();

  /// Wrapper genérico para manejar reintentos y excepciones de red/auth.
  /// [requestFn]: Función que ejecuta la petición HTTP original.
  /// [isAuthEndpoint]: Si es true, no intentará refrescar token (evita bucles en login).
  Future<dynamic> _request(Future<http.Response> Function() requestFn,
      {bool isAuthEndpoint = false}) async {
    try {
      final response = await requestFn();
      return _handleResponse(response);
    } on UnauthorizedException {
      // Si es endpoint de auth (login/refresh) o ya estamos refrescando, propagamos el error
      if (isAuthEndpoint || _isRefreshing) {
        rethrow;
      }

      debugPrint('🔄 Token expirado (401). Intentando refrescar...');
      final success = await _refreshToken();

      if (success) {
        debugPrint('🔄 Reintentando petición original...');
        // Reintentar la petición original con el nuevo token
        final retryResponse = await requestFn();
        return _handleResponse(retryResponse);
      } else {
        throw UnauthorizedException('Sesión expirada.');
      }
    } on SocketException {
      throw ConnectionException('Sin conexión a internet.');
    } catch (e) {
      // Si ya es una excepción nuestra, la dejamos pasar
      if (e is ApiException) {
        rethrow;
      }
      // Si es otra cosa, la envolvemos
      debugPrint('Error inesperado en ApiClient: $e');
      throw ApiException('Error de comunicación: $e');
    }
  }

  /// Intenta obtener un nuevo Access Token usando el Refresh Token.
  Future<bool> _refreshToken() async {
    _isRefreshing = true;
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        return false;
      }

      final uri = Uri.parse('$_baseUrl/auth/refresh');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: _accessTokenKey, value: data['accessToken']);
        // El refresh token puede rotar o mantenerse, lo guardamos si viene nuevo
        if (data['refreshToken'] != null) {
          await _storage.write(
              key: _refreshTokenKey, value: data['refreshToken']);
        }
        debugPrint('✅ Token refrescado con éxito.');
        return true;
      } else {
        debugPrint(
            '❌ Fallo al refrescar token. Status: ${response.statusCode}');
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error refrescando token: $e');
      await logout();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Borra tokens locales.
  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Procesa la respuesta HTTP y lanza excepciones personalizadas según el código de estado.
  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      print(
          'HTTP ${response.request?.method} ${response.request?.url} -> ${response.statusCode}');
    }

    final body = response.body.isEmpty
        ? {}
        : jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Extraer mensaje de error del backend (formato estandarizado que definimos en Java)
    String errorMessage = 'Error desconocido';
    String? errorCode;
    Map<String, dynamic>? fieldErrors;

    if (body is Map) {
      // Soporte para el formato de error de Spring Boot que definimos en GlobalExceptionHandler
      errorCode = body['error']?.toString(); // e.g. "VALIDATION_ERROR"

      // Preferimos el mensaje traducido ('message') si el backend lo envió, si no la clave ('error')
      errorMessage =
          body['message']?.toString() ?? errorCode ?? 'Error del servidor';

      if (body['fieldErrors'] != null) {
        fieldErrors = Map<String, dynamic>.from(body['fieldErrors']);
      }
    }

    switch (response.statusCode) {
      case 400:
        throw BadRequestException(errorMessage, fieldErrors);
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
