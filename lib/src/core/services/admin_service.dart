// lib/src/core/services/admin_service.dart
import 'package:libratrack_client/src/core/utils/api_client.dart'; 
import 'package:libratrack_client/src/model/perfil_usuario.dart'; 
import 'package:libratrack_client/src/model/elemento.dart'; 
// --- ¡NUEVAS IMPORTACIONES! ---
import 'package:libratrack_client/src/model/paginated_response.dart'; 

/// Servicio para gestionar las llamadas a la API de Administración (ROLE_ADMIN).
/// --- ¡ACTUALIZADO (Sprint 7)! ---
class AdminService {
  
  final String _basePath = '/admin'; 

  // --- Métodos de Gestión de Usuarios (Petición 14) ---

  /// --- ¡REFACTORIZADO (Sprint 7)! ---
  /// (Petición B, C, G) Obtiene la lista de TODOS los usuarios
  /// con paginación, búsqueda y filtros.
  Future<PaginatedResponse<PerfilUsuario>> getAllUsuarios({
    int page = 0,
    int size = 20,
    String? search,
    String? roleFilter,
  }) async {
    
    // 1. Construir el Mapa de Query Parameters
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (roleFilter != null && roleFilter.isNotEmpty) {
      queryParams['role'] = roleFilter; 
    }

    // 2. Llamar al ApiClient.get
    final dynamic responseData = await api.get(
      '$_basePath/usuarios', 
      queryParams: queryParams
    );

    // 3. Mapear la respuesta paginada
    return PaginatedResponse.fromJson(
      responseData as Map<String, dynamic>,
      // Le decimos CÓMO construir cada PerfilUsuario individual
      (json) => PerfilUsuario.fromJson(json),
    );
  }
  
  /// (Petición 14) Actualiza los roles de un usuario específico.
  Future<PerfilUsuario> updateUserRoles(
    int userId, {
    required bool esModerador,
    required bool esAdministrador,
  }) async {
    // ... (código sin cambios)
    final Map<String, dynamic> body = {
      'esModerador': esModerador,
      'esAdministrador': esAdministrador,
    };
    final dynamic responseData = await api.put(
      '$_basePath/usuarios/$userId/roles',
      body: body,
    );
    return PerfilUsuario.fromJson(responseData as Map<String, dynamic>);
  }
  
  // --- Métodos de Gestión de Contenido ---

  Future<Elemento> crearElementoOficial(Map<String, dynamic> body) async {
    // ... (código sin cambios)
    final dynamic responseData = await api.post(
      '$_basePath/elementos',
      body: body,
    );
    return Elemento.fromJson(responseData as Map<String, dynamic>);
  }
  
  Future<Elemento> updateElemento(int elementoId, Map<String, dynamic> body) async {
    // ... (código sin cambios)
    final dynamic responseData = await api.put(
      '$_basePath/elementos/$elementoId',
      body: body,
    );
    return Elemento.fromJson(responseData as Map<String, dynamic>);
  }
  
  Future<Elemento> oficializarElemento(int elementoId) async {
    // ... (código sin cambios)
    final dynamic responseData = await api.put(
      '$_basePath/elementos/$elementoId/oficializar',
    );
    return Elemento.fromJson(responseData as Map<String, dynamic>);
  }

  Future<Elemento> comunitarizarElemento(int elementoId) async {
    // ... (código sin cambios)
    final dynamic responseData = await api.put(
      '$_basePath/elementos/$elementoId/comunitarizar',
    );
    return Elemento.fromJson(responseData as Map<String, dynamic>);
  }
}