import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/elemento.dart';
import '../../model/paginated_response.dart';
import '../../model/perfil_usuario.dart';

class AdminService with ChangeNotifier {
  final ApiClient _apiClient;

  AdminService(this._apiClient);

  /// Obtiene una lista paginada de usuarios con filtros opcionales.
  Future<PaginatedResponse<PerfilUsuario>> getUsuarios({
    required int page,
    int size = 20,
    String? search,
    String? roleFilter,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (roleFilter != null && roleFilter.isNotEmpty) 'role': roleFilter,
      };

      final response =
          await _apiClient.get('admin/usuarios', queryParams: queryParams);

      return PaginatedResponse.fromJson(
        response,
        PerfilUsuario.fromJson,
      );
    } catch (e) {
      // Si es una excepción de API conocida, la dejamos pasar
      if (e is ApiException) {
        rethrow;
      }
      // Si no, la envolvemos
      throw ApiException('Error al cargar usuarios: $e');
    }
  }

  /// Actualiza los roles de un usuario (Admin/Moderador).
  Future<PerfilUsuario> updateUserRoles(
    int userId,
    bool esModerador,
    bool esAdministrador,
  ) async {
    try {
      final body = {
        'esModerador': esModerador,
        'esAdministrador': esAdministrador,
      };

      final response = await _apiClient.put(
        'admin/usuarios/$userId/roles',
        body,
      );

      return PerfilUsuario.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al actualizar roles: $e');
    }
  }

  /// Crea un nuevo elemento marcado directamente como OFICIAL.
  Future<Elemento> crearElementoOficial(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.post('admin/elementos', body);
      return Elemento.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al crear el elemento: $e');
    }
  }

  /// Actualiza los datos de un elemento existente.
  Future<Elemento> updateElemento(
    int elementoId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _apiClient.put(
        'admin/elementos/$elementoId',
        body,
      );
      return Elemento.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al actualizar el elemento: $e');
    }
  }

  /// Alterna el estado de un elemento entre OFICIAL y COMUNITARIO.
  Future<Elemento> toggleElementoOficial(
    int elementoId,
    bool hacerOficial,
  ) async {
    try {
      final endpoint = hacerOficial
          ? 'admin/elementos/$elementoId/oficializar'
          : 'admin/elementos/$elementoId/comunitarizar';

      // Enviamos un cuerpo vacío ya que es una acción directa
      final response = await _apiClient.put(endpoint, {});
      return Elemento.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al cambiar el estado del elemento: $e');
    }
  }
}
