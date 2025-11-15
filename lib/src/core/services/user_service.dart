// Archivo: lib/src/core/services/user_service.dart
// (¡REFACTORIZADO!)

import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';
import 'package:libratrack_client/src/model/perfil_usuario.dart';

class UserService with ChangeNotifier {
  // --- ¡MODIFICADO! ---
  final ApiClient _apiClient;
  UserService(this._apiClient);
  // ---
  
  // (Este servicio actualmente no guarda estado, solo realiza acciones)

  /// Sube la URL de la foto de perfil (obtenida de GCS).
  Future<PerfilUsuario> updateFotoPerfil(String fotoUrl) async {
    try {
      final body = {'url': fotoUrl};
      // ¡Lógica simplificada!
      final data = await _apiClient.put('usuarios/me/foto', body);
      return PerfilUsuario.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar la foto: ${e.toString()}');
    }
  }

  /// Cambia la contraseña del usuario.
  Future<void> updatePassword(String actual, String nueva) async {
    try {
      final body = {
        'contraseñaActual': actual,
        'nuevaContraseña': nueva,
      };
      // ¡Lógica simplificada!
      // Este endpoint (PUT /me/password) devuelve 200 OK con un String,
      // no un JSON. El ApiClient lo manejará como un JSON vacío.
      await _apiClient.put('usuarios/me/password', body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cambiar la contraseña: ${e.toString()}');
    }
  }

  /// Actualiza el nombre de usuario.
  Future<PerfilUsuario> updateUsername(String nuevoUsername) async {
    try {
      final body = {'username': nuevoUsername};
      // ¡Lógica simplificada!
      final data = await _apiClient.put('usuarios/me', body);
      return PerfilUsuario.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar el usuario: ${e.toString()}');
    }
  }
}