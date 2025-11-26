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
  Future<PaginatedResponse<Elemento>> searchElementos({
    String? query,
    List<String>? types,
    List<String>? genres,
    int page = 0,
    int size = 20,
  }) async {
    try {
      // Construcción manual de query params para manejar listas (ej. types=Anime,Manga)
      // El backend espera strings separados por comas para listas simples en @RequestParam
      final Map<String, String> params = {
        'page': page.toString(),
        'size': size.toString(),
      };

      if (query != null && query.isNotEmpty) {
        params['search'] = query;
      }

      if (types != null && types.isNotEmpty) {
        params['types'] = types.join(',');
      }

      if (genres != null && genres.isNotEmpty) {
        params['genres'] = genres.join(',');
      }

      final response = await _apiClient.get('elementos', queryParams: params);

      return PaginatedResponse.fromJson(
        response,
        Elemento.fromJson,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error buscando elementos: $e');
    }
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
