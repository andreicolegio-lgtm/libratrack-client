// lib/src/core/services/moderacion_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libratrack_client/src/model/propuesta.dart'; // Importa el modelo

/// Servicio para gestionar las llamadas a la API de Moderación (RF14, RF15).
///
/// Llama a los endpoints protegidos que requieren 'ROLE_MODERADOR'.
class ModeracionService {
  
  final String _baseUrl = 'http://10.0.2.2:8080/api/moderacion';
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token'; 

  /// Método auxiliar privado para obtener las cabeceras de autenticación.
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

  /// Obtiene la lista de propuestas pendientes (RF14).
  ///
  /// Llama a 'GET /api/moderacion/pendientes'.
  Future<List<Propuesta>> getPropuestasPendientes() async {
    final Map<String, String> headers = await _getAuthHeaders();
    final Uri url = Uri.parse('$_baseUrl/pendientes');

    http.Response response;
    try {
      response = await http.get(url, headers: headers);
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }

    if (response.statusCode == 200) { // 200 OK
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((json) => Propuesta.fromJson(json as Map<String, dynamic>))
          .toList();
          
    } else if (response.statusCode == 403) {
      // 403 Forbidden: El usuario no es 'ROLE_MODERADOR'
      throw Exception('No tienes permisos de moderador.');
    } else {
      throw Exception('Error al cargar la cola de moderación: ${response.statusCode}');
    }
  }

  /// Aprueba una propuesta (RF15).
  ///
  /// Llama a 'POST /api/moderacion/aprobar/{propuestaId}'.
  /// No devuelve nada en caso de éxito (solo un 200 OK).
  Future<void> aprobarPropuesta(int propuestaId) async {
    final Map<String, String> headers = await _getAuthHeaders();
    final Uri url = Uri.parse('$_baseUrl/aprobar/$propuestaId');

    http.Response response;
    try {
      // Es un POST, pero no necesita 'body'
      response = await http.post(url, headers: headers);
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor.');
    }

    if (response.statusCode == 200) { // 200 OK
      return; // Éxito
    } else if (response.statusCode == 400) { // 400 Bad Request
      // ej. "Esta propuesta ya ha sido gestionada."
      throw Exception(response.body);
    } else if (response.statusCode == 403) {
      // El usuario no es 'ROLE_MODERADOR'
      throw Exception('No tienes permisos de moderador.');
    } else {
      throw Exception('Error al aprobar la propuesta: ${response.statusCode}');
    }
  }
  
  // (Aquí iría la lógica futura para 'rechazarPropuesta')
}