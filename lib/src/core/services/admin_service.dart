// Archivo: lib/src/core/services/admin_service.dart
// (¡REFACTORIZADO! Acepta 'int' para IDs)

import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';
import 'package:libratrack_client/src/model/elemento.dart';
import 'package:libratrack_client/src/model/paginated_response.dart';
import 'package:libratrack_client/src/model/perfil_usuario.dart';

class AdminService with ChangeNotifier {
  final ApiClient _apiClient;
  AdminService(this._apiClient);

  /// (B, C, G) Obtiene usuarios con paginación, búsqueda y filtros.
  Future<PaginatedResponse<PerfilUsuario>> getUsuarios({
    required int page,
    int size = 20,
    String? search,
    String? roleFilter,
  }) async {
    try {
      String endpoint = 'admin/usuarios?page=$page&size=$size';
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=$search';
      }
      if (roleFilter != null && roleFilter.isNotEmpty) {
        endpoint += '&role=$roleFilter';
      }
      final data = await _apiClient.get(endpoint);
      return PaginatedResponse.fromJson(data, PerfilUsuario.fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cargar usuarios: ${e.toString()}');
    }
  }

  /// (14) Actualiza los roles de un usuario.
  // --- ¡CORREGIDO! Acepta int userId ---
  Future<PerfilUsuario> updateUserRoles(
      int userId, bool esModerador, bool esAdministrador) async {
    try {
      final body = {
        'esModerador': esModerador,
        'esAdministrador': esAdministrador,
      };
      // Convierte a String en el último momento
      final data = await _apiClient.put('admin/usuarios/${userId.toString()}/roles', body);
      return PerfilUsuario.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar roles: ${e.toString()}');
    }
  }

  /// (15) Crea un elemento OFICIAL.
  Future<Elemento> crearElementoOficial(Map<String, dynamic> body) async {
    try {
      final data = await _apiClient.post('admin/elementos', body);
      return Elemento.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al crear el elemento: ${e.toString()}');
    }
  }

  /// (8) Actualiza un elemento existente (Mod/Admin).
  // --- ¡CORREGIDO! Acepta int elementoId ---
  Future<Elemento> updateElemento(
      int elementoId, Map<String, dynamic> body) async {
    try {
      // Convierte a String en el último momento
      final data = await _apiClient.put('admin/elementos/${elementoId.toString()}', body);
      return Elemento.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar el elemento: ${e.toString()}');
    }
  }

  /// (17, F) Cambia el estado de un elemento (Oficial/Comunitario).
  // --- ¡CORREGIDO! Acepta int elementoId ---
  Future<Elemento> toggleElementoOficial(
      int elementoId, bool oficializar) async {
    try {
      final String endpoint = oficializar
          ? 'admin/elementos/${elementoId.toString()}/oficializar'
          : 'admin/elementos/${elementoId.toString()}/comunitarizar';
      
      final data = await _apiClient.put(endpoint, {});
      return Elemento.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cambiar el estado del elemento: ${e.toString()}');
    }
  }
}