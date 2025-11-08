// lib/src/core/services/catalog_service.dart
import 'package:libratrack_client/src/core/utils/api_client.dart'; 
import 'package:libratrack_client/src/model/catalogo_entrada.dart'; 

/// Servicio para gestionar todas las llamadas a la API relacionadas con el
/// catálogo personal del usuario (RF05, RF06, RF07, RF08).
/// REFACTORIZADO: Utiliza ApiClient.
class CatalogService {
  
  final String _basePath = '/catalogo'; 

  /// Obtiene el catálogo personal del usuario autenticado (RF08).
  Future<List<CatalogoEntrada>> getMyCatalog() async {
    // 1. Usar el ApiClient (GET protegido)
    final List<dynamic> jsonList = await api.get(_basePath) as List<dynamic>;
    
    // 2. Mapear la lista de JSON a una lista de objetos CatalogoEntrada
    return jsonList
        .map((json) => CatalogoEntrada.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  /// Añade un elemento al catálogo personal del usuario (RF05).
  Future<CatalogoEntrada> addElementoAlCatalogo(int elementoId) async {
    
    // 1. Usar el ApiClient (POST protegido).
    final dynamic responseData = await api.post('$_basePath/elementos/$elementoId');

    // 2. Mapear el JSON de respuesta
    return CatalogoEntrada.fromJson(responseData as Map<String, dynamic>);
  }

  /// Actualiza el estado y/o el progreso de un elemento en el catálogo (RF06, RF07).
  Future<CatalogoEntrada> updateElementoDelCatalogo(
    int elementoId, {
    required String estado,
    required String? progreso,
  }) async {
    
    // NOTA: El backend espera `temporadaActual` y `unidadActual`, pero el frontend
    // aquí usa `progresoEspecifico` por simplicidad. Lo mapeamos al DTO que espera la API.
    final Map<String, String?> body = {
      'estadoPersonal': estado,
      // Mantenemos el campo que el backend original espera, si no se usa la nueva convención
      'progresoEspecifico': progreso, 
    };
    
    final dynamic responseData = await api.put(
      '$_basePath/elementos/$elementoId',
      body: body,
    );

    return CatalogoEntrada.fromJson(responseData as Map<String, dynamic>);
  }
  
  /// Elimina un elemento del catálogo personal del usuario.
  Future<void> removeElementoDelCatalogo(int elementoId) async {
    await api.delete('$_basePath/elementos/$elementoId');
  }
}