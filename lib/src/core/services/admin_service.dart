import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/elemento.dart';
import '../../model/paginated_response.dart';
import '../../model/perfil_usuario.dart';

class AdminService with ChangeNotifier {
  final ApiClient _apiClient;
  AdminService(this._apiClient);

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
      final Map<String, dynamic> responseRaw = await _apiClient.get(endpoint);
      return PaginatedResponse.fromJson(responseRaw, PerfilUsuario.fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cargar usuarios: ${e.toString()}');
    }
  }

  Future<PerfilUsuario> updateUserRoles(
      int userId, bool esModerador, bool esAdministrador) async {
    try {
      final Map<String, bool> body = <String, bool>{
        'esModerador': esModerador,
        'esAdministrador': esAdministrador,
      };
      final dynamic data = await _apiClient.put(
          'admin/usuarios/${userId.toString()}/roles', body);
      return PerfilUsuario.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar roles: ${e.toString()}');
    }
  }

  Future<Elemento> crearElementoOficial(Map<String, dynamic> body) async {
    try {
      final dynamic data = await _apiClient.post('admin/elementos', body);
      return Elemento.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al crear el elemento: ${e.toString()}');
    }
  }

  Future<Elemento> updateElemento(
      int elementoId, Map<String, dynamic> body) async {
    try {
      final dynamic data = await _apiClient.put(
          'admin/elementos/${elementoId.toString()}', body);
      return Elemento.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar el elemento: ${e.toString()}');
    }
  }

  Future<Elemento> toggleElementoOficial(
      int elementoId, bool oficializar) async {
    try {
      final String endpoint = oficializar
          ? 'admin/elementos/${elementoId.toString()}/oficializar'
          : 'admin/elementos/${elementoId.toString()}/comunitarizar';

      final dynamic data = await _apiClient.put(endpoint, <String, dynamic>{});
      return Elemento.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Error al cambiar el estado del elemento: ${e.toString()}');
    }
  }
}
