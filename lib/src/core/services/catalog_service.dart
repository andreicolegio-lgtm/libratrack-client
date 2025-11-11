// lib/src/core/services/catalog_service.dart
import 'package:libratrack_client/src/core/utils/api_client.dart'; 
import 'package:libratrack_client/src/model/catalogo_entrada.dart'; 

/// Servicio para gestionar el Catálogo Personal del usuario (RF05-RF08).
/// --- ¡ACTUALIZADO (Sprint 2 / V2)! ---
class CatalogService {
  
  final String _basePath = '/catalogo'; 
  final String _elementosPath = '/elementos';

  /// Obtiene el catálogo completo del usuario (RF08).
  Future<List<CatalogoEntrada>> getMyCatalog() async {
    final List<dynamic> jsonList = await api.get(_basePath) as List<dynamic>;
    
    return jsonList
        .map((json) => CatalogoEntrada.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  /// Añade un elemento al catálogo (RF05).
  Future<CatalogoEntrada> addElementoAlCatalogo(int elementoId) async {
    final dynamic responseData = await api.post('$_basePath$_elementosPath/$elementoId');
    return CatalogoEntrada.fromJson(responseData as Map<String, dynamic>);
  }
  
  /// Quita un elemento del catálogo.
  Future<void> removeElementoDelCatalogo(int elementoId) async {
    await api.delete('$_basePath$_elementosPath/$elementoId');
  }

  /// Actualiza el estado o progreso de un elemento (RF06, RF07).
  ///
  /// --- ¡ACTUALIZADO! (Petición b) ---
  /// Acepta todos los campos de progreso granular.
  Future<CatalogoEntrada> updateElementoDelCatalogo(
    int elementoId, {
    String? estado,
    int? temporadaActual, // Para Series
    int? unidadActual,   // Para Episodios (Serie) / Capítulos (Manga) / Episodios (Anime)
    int? capituloActual, // Para Capítulos (Libro)
    int? paginaActual,   // Para Páginas (Libro)
  }) async {
    
    final Map<String, dynamic> body = {
      'estadoPersonal': estado,
      'temporadaActual': temporadaActual,
      'unidadActual': unidadActual,
      'capituloActual': capituloActual,
      'paginaActual': paginaActual,
    };
    
    // Eliminamos nulos para no sobrescribir datos en la API
    body.removeWhere((key, value) => value == null);

    final dynamic responseData = await api.put(
      '$_basePath$_elementosPath/$elementoId',
      body: body,
    );
    
    return CatalogoEntrada.fromJson(responseData as Map<String, dynamic>);
  }
}