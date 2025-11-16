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
      await _apiClient.put('usuarios/me/password', body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cambiar la contraseña: ${e.toString()}');
    }
  }

  Future<PerfilUsuario> updateUsername(String nuevoUsername) async {
    try {
      final Map<String, String> body = <String, String>{
        'username': nuevoUsername
      };
      final data = await _apiClient.put('usuarios/me', body);
      return PerfilUsuario.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar el usuario: ${e.toString()}');
    }
  }
}
