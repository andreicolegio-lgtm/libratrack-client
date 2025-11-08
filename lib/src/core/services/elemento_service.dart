// Archivo: lib/src/core/services/elemento_service.dart

// Se eliminan imports innecesarios: dart:convert, http, flutter_secure_storage
import 'package:libratrack_client/src/core/utils/api_client.dart'; // Importar el nuevo ApiClient
import 'package:libratrack_client/src/model/elemento.dart'; 

/// Servicio para gestionar todas las llamadas a la API relacionadas con los
/// elementos públicos del catálogo (Búsqueda, Fichas de detalle).
/// REFACTORIZADO: Utiliza ApiClient.
class ElementoService {
  
  // Ruta base relativa al ApiClient.baseUrl
  final String _basePath = '/elementos';

  /// Obtiene la lista global de elementos o busca por los 3 criterios (RF09).
  ///
  /// REFACTORIZADO: Ahora acepta los 3 parámetros de filtro.
  Future<List<Elemento>> getElementos({
    String? searchText,
    String? tipoName,
    String? generoName,
  }) async {
    
    // 1. Construir el Mapa de Query Parameters
    final Map<String, String> queryParams = {};
    if (searchText != null && searchText.isNotEmpty) {
      queryParams['search'] = searchText;
    }
    if (tipoName != null && tipoName.isNotEmpty) {
      queryParams['tipo'] = tipoName; // Coincide con @RequestParam(value="tipo")
    }
    if (generoName != null && generoName.isNotEmpty) {
      queryParams['genero'] = generoName; // Coincide con @RequestParam(value="genero")
    }

    // 2. Llamar al ApiClient.get
    // (ApiClient se encarga de las cabeceras, try-catch, y errores 403/404)
    final List<dynamic> jsonList = await api.get(
      _basePath, 
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    ) as List<dynamic>;

    // 3. Mapear la respuesta
    return jsonList
        .map((json) => Elemento.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  /// Obtiene la ficha detallada de un elemento por su ID (RF10).
  /// REFACTORIZADO: Utiliza ApiClient.
  Future<Elemento> getElementoById(int elementoId) async {
    
    // 1. Llamar al ApiClient.get
    // (ApiClient se encarga de las cabeceras, try-catch, y error 404)
    final dynamic responseData = await api.get('$_basePath/$elementoId');
    
    // 2. Mapear la respuesta
    return Elemento.fromJson(responseData as Map<String, dynamic>);
  }
}