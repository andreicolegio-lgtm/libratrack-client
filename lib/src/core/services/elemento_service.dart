// Archivo: lib/src/core/services/elemento_service.dart
// (¡CORREGIDO Y ACTUALIZADO POR GEMINI!)

import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/model/elemento.dart';
import 'package:libratrack_client/src/model/paginated_response.dart';
// --- ¡NUEVA IMPORTACIÓN AÑADIDA POR GEMINI! ---
import 'package:libratrack_client/src/model/elemento_relacion.dart';

/// Servicio para interactuar con los endpoints de /api/elementos
class ElementoService with ChangeNotifier {
  // --- ¡CORRECCIÓN 1! ---
  // El ApiClient se inyecta, no se crea aquí.
  final ApiClient _apiClient;
  ElementoService(this._apiClient);
  // ---

  /// Busca elementos de forma paginada y con filtros.
  Future<PaginatedResponse<Elemento>> searchElementos(
      {int page = 0,
      int size = 20,
      String? search,
      String? tipo,
      String? genero}) async {
        
    // --- ¡CORRECCIÓN 2! ---
    // (Este bloque faltaba en tu versión)
    // 1. Construir el URI con los query parameters
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
      if (genero != null && genero.isNotEmpty) 'genero': genero,
    };

    // 2. Realizar la petición GET, pasando los queryParams
    final dynamic jsonResponse = await _apiClient.get('elementos', queryParams: queryParams);
    // ---

    // 3. Mapear usando el constructor de PaginatedResponse
    return PaginatedResponse.fromJson(jsonResponse, Elemento.fromJson);
  }

  /// Obtiene un único elemento por su ID.
  Future<Elemento> getElementoById(int elementoId) async {
    final dynamic jsonResponse = await _apiClient.get('elementos/$elementoId');
    return Elemento.fromJson(jsonResponse);
  }

  // --- ¡NUEVO MÉTODO! (Añadido por Gemini) ---
  /// Obtiene una lista simple (id, titulo, imagen) de TODOS los elementos.
  /// Usado para rellenar el selector de relaciones en el formulario de Admin.
  Future<List<ElementoRelacion>> getSimpleElementoList() async {
    final dynamic jsonResponse = await _apiClient.get('elementos/all-simple');
    
    final List<dynamic> list = jsonResponse is List ? jsonResponse : [jsonResponse];

    // Mapea la lista de JSON a una lista de ElementoRelacion
    return list
        .map((json) => ElementoRelacion.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  // --- FIN DE MÉTODO AÑADIDO ---
}