import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/perfil_usuario.dart';

/// Servicio para gestionar la información del perfil del usuario autenticado.
class UserService with ChangeNotifier {
  final ApiClient _apiClient;
  UserService(this._apiClient);

  /// Actualiza la foto de perfil del usuario.
  Future<PerfilUsuario> updateFotoPerfil(String? fotoUrl) async {
    try {
      final Map<String, dynamic> body = {'url': fotoUrl};
      final dynamic data = await _apiClient.put('usuarios/me/foto', body);
      return PerfilUsuario.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al actualizar la foto: $e');
    }
  }

  /// Cambia la contraseña del usuario.
  Future<void> updatePassword(String actual, String nueva) async {
    try {
      final Map<String, dynamic> body = {
        'contraseñaActual': actual,
        'nuevaContraseña': nueva,
      };

      debugPrint('[UserService] Updating password...');
      final dynamic response =
          await _apiClient.put('usuarios/me/password', body);

      // El backend puede devolver un mensaje en texto plano o un JSON con mensaje
      String message = '';
      if (response is Map && response.containsKey('message')) {
        message = response['message'] as String;
      } else if (response is String) {
        message = response;
      }

      debugPrint('[UserService] Password update response: $message');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al cambiar la contraseña: $e');
    }
  }

  /// Actualiza el nombre de usuario.
  Future<PerfilUsuario> updateUsername(String nuevoUsername) async {
    try {
      final Map<String, dynamic> body = {'username': nuevoUsername};

      debugPrint('[UserService] Updating username to: $nuevoUsername');
      final dynamic data = await _apiClient.put('usuarios/me', body);

      return PerfilUsuario.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al actualizar el usuario: $e');
    }
  }
}
