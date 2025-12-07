import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/elemento.dart';
import '../../model/propuesta.dart';
import '../../model/paginated_response.dart';

/// Servicio utilizado por el panel de moderación para gestionar solicitudes de contenido.
class ModeracionService with ChangeNotifier {
  final ApiClient _apiClient;
  ModeracionService(this._apiClient);

  /// Obtiene una lista de propuestas filtradas por su estado, texto, tipos y géneros.
  Future<List<Propuesta>> fetchPropuestasPorEstado(
    String estado, {
    String? search,
    List<String>? types,
    List<String>? genres,
    String? sortMode, // Nuevo
    bool? isAscending, // Nuevo
  }) async {
    try {
      final Map<String, String> params = {'estado': estado};

      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      if (types != null && types.isNotEmpty) {
        params['types'] = types.join(',');
      }
      if (genres != null && genres.isNotEmpty) {
        params['genres'] = genres.join(',');
      }
      if (sortMode != null) {
        params['sort'] = sortMode;
      }
      if (isAscending != null) {
        params['asc'] = isAscending.toString();
      }

      final response = await _apiClient.get('moderacion', queryParams: params);

      // Validación de tipo segura
      final List<dynamic> data = response is List ? response : [];

      return data
          .map((item) => Propuesta.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al cargar las propuestas: $e');
    }
  }

  /// Aprueba una propuesta y crea el elemento correspondiente.
  Future<Elemento> aprobarPropuesta(
      int propuestaId, Map<String, dynamic> body) async {
    try {
      final dynamic data =
          await _apiClient.post('moderacion/aprobar/$propuestaId', body);
      return Elemento.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al aprobar la propuesta: $e');
    }
  }

  /// Rechaza una propuesta por su ID con un motivo.
  Future<void> rechazarPropuesta(int id, String motivo) async {
    try {
      await _apiClient.post('moderacion/rechazar/$id', {'motivo': motivo});
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al rechazar la propuesta: $e');
    }
  }

  /// Obtiene elementos creados con paginación, búsqueda y filtros opcionales.
  Future<PaginatedResponse<Elemento>> getElementosCreados({
    int page = 0,
    String? search,
    List<String>? types,
    List<String>? genres,
    String sort = 'DATE',
    bool asc = false,
  }) async {
    try {
      final Map<String, String> params = {
        'page': page.toString(),
        'sort': sort,
        'asc': asc.toString(),
      };

      if (search != null) {
        params['search'] = search;
      }

      if (types != null && types.isNotEmpty) {
        params['types'] = types.join(',');
      }

      if (genres != null && genres.isNotEmpty) {
        params['genres'] = genres.join(',');
      }

      final response = await _apiClient.get(
        'moderacion/elementos-creados',
        queryParams: params,
      );

      return PaginatedResponse.fromJson(response, Elemento.fromJson);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error cargando historial: $e');
    }
  }
}
