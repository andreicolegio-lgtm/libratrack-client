import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/perfil_usuario.dart';

class UserService with ChangeNotifier {
  final ApiClient _apiClient;
  UserService(this._apiClient);

  Future<PerfilUsuario> updateFotoPerfil(String fotoUrl) async {
    try {
      final Map<String, String> body = <String, String>{'url': fotoUrl};
      final data = await _apiClient.put('usuarios/me/foto', body);
      return PerfilUsuario.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar la foto: ${e.toString()}');
    }
  }

  Future<void> updatePassword(String actual, String nueva) async {
    try {
      final Map<String, String> body = <String, String>{
        'contraseñaActual': actual,
        'nuevaContraseña': nueva,
      };
      debugPrint(
          '[UserService.updatePassword] Sending request to update password');
      debugPrint('[UserService.updatePassword] Request body: $body');
      final response = await _apiClient.put('usuarios/me/password', body);

      if (response is String) {
        debugPrint(
            '[UserService.updatePassword] Plain text response: $response');
        if (!response
            .toLowerCase()
            .contains('contraseña actualizada con éxito')) {
          throw ApiException('Unexpected response: $response');
        }
      } else if (response is Map<String, dynamic> &&
          response['message'] != null) {
        debugPrint(
            '[UserService.updatePassword] JSON response: ${response['message']}');
      } else {
        throw ApiException('Unexpected response format');
      }
      debugPrint('[UserService.updatePassword] Password updated successfully');
    } on ApiException catch (e) {
      debugPrint('[UserService.updatePassword] ApiException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint(
          '[UserService.updatePassword] Unexpected error: ${e.toString()}');
      throw ApiException('Error al cambiar la contraseña: ${e.toString()}');
    }
  }

  Future<PerfilUsuario> updateUsername(String nuevoUsername) async {
    try {
      final Map<String, String> body = <String, String>{
        'username': nuevoUsername
      };
      debugPrint('[UserService.updateUsername] PUT /usuarios/me body: $body');
      final data = await _apiClient.put('usuarios/me', body);
      debugPrint('[UserService.updateUsername] Response: $data');
      return PerfilUsuario.fromJson(data);
    } on ApiException catch (e) {
      debugPrint('[UserService.updateUsername] ApiException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[UserService.updateUsername] Unexpected error: $e');
      throw ApiException('Error al actualizar el usuario: ${e.toString()}');
    }
  }
}
