import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/elemento.dart';
import '../../model/elemento_relacion.dart';
import '../../model/paginated_response.dart';

class ElementoService with ChangeNotifier {
  final ApiClient _apiClient;

  ElementoService(this._apiClient);

  /// Busca elementos con filtros y paginación.
  // En ElementoService.dart

  Future<PaginatedResponse<Elemento>> searchElementos({
    String? query,
    List<String>? types,
    List<String>? genres,
    int page = 0,
    int size = 20,
    // NUEVOS PARÁMETROS
    String? sortMode,
    bool? isAscending,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };

    if (query != null && query.isNotEmpty) {
      queryParams['search'] = query;
    }

    // Enviar listas separadas por comas
    if (types != null && types.isNotEmpty) {
      queryParams['types'] = types.join(',');
    }
    if (genres != null && genres.isNotEmpty) {
      queryParams['genres'] = genres.join(',');
    }

    // NUEVOS PARÁMETROS A LA URL
    if (sortMode != null) {
      queryParams['sort'] = sortMode; // 'DATE' o 'ALPHA'
      queryParams['asc'] = (isAscending ?? false).toString();
    }

    // Coincide con @GetMapping("/public/search") del Controller
    final response = await _apiClient.get('elementos/public/search',
        queryParams: queryParams);

    return PaginatedResponse.fromJson(
      response,
      (json) => Elemento.fromJson(json),
    );
  }

  /// Obtiene el detalle completo de un elemento por ID.
  Future<Elemento> getElementoById(int id) async {
    try {
      final response = await _apiClient.get('elementos/$id');
      return Elemento.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error cargando elemento: $e');
    }
  }

  /// Obtiene una lista ligera de todos los elementos (ID, Título, Foto).
  /// Útil para selectores de secuelas/precuelas en formularios admin.
  Future<List<ElementoRelacion>> getSimpleList() async {
    try {
      final List<dynamic> response =
          await _apiClient.get('elementos/all-simple');
      return response.map((json) => ElementoRelacion.fromJson(json)).toList();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error cargando lista simple: $e');
    }
  }
}
