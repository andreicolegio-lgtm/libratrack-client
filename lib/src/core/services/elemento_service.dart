// Archivo: lib/src/core/services/elemento_service.dart

import 'package:libratrack_client/src/core/utils/api_client.dart'; 
import 'package:libratrack_client/src/model/elemento.dart'; 
// NUEVA IMPORTACIÓN
import 'package:libratrack_client/src/model/paginated_response.dart'; 

/// Servicio para gestionar todas las llamadas a la API relacionadas con los
/// elementos públicos del catálogo (Búsqueda, Fichas de detalle).
/// REFACTORIZADO: Utiliza ApiClient y Paginación.
class ElementoService {
  
  // Ruta base relativa al ApiClient.baseUrl
  final String _basePath = '/elementos';

  /// Obtiene la lista global de elementos o busca por los 3 criterios (RF09).
  ///
  /// REFACTORIZADO: Ahora acepta paginación y devuelve un PaginatedResponse.
  Future<PaginatedResponse<Elemento>> getElementos({
    String? searchText,
    String? tipoName,
    String? generoName,
    int page = 0,
    int size = 20,
  }) async {
    
    // 1. Construir el Mapa de Query Parameters (incluyendo paginación)
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };
    if (searchText != null && searchText.isNotEmpty) {
      queryParams['search'] = searchText;
    }
    if (tipoName != null && tipoName.isNotEmpty) {
      queryParams['tipo'] = tipoName; 
    }
    if (generoName != null && generoName.isNotEmpty) {
      queryParams['genero'] = generoName; 
    }

    // 2. Llamar al ApiClient.get
    // La respuesta ya no es una Lista, es un Mapa (el objeto Page)
    final dynamic responseData = await api.get(
      _basePath, 
      queryParams: queryParams,
    );

    // 3. Mapear la respuesta paginada
    return PaginatedResponse.fromJson(
      responseData as Map<String, dynamic>,
      // Le decimos CÓMO construir cada Elemento individual
      (json) => Elemento.fromJson(json),
    );
  }
  
  /// Obtiene la ficha detallada de un elemento por su ID (RF10).
  /// REFACTORIZADO: Utiliza ApiClient.
  Future<Elemento> getElementoById(int elementoId) async {
    
    // 1. Llamar al ApiClient.get
    final dynamic responseData = await api.get('$_basePath/$elementoId');
    
    // 2. Mapear la respuesta
    return Elemento.fromJson(responseData as Map<String, dynamic>);
  }
}