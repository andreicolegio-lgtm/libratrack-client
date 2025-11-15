// Archivo: lib/src/core/services/elemento_service.dart
// (¡REFACTORIZADO! Acepta 'int' para IDs)

import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';
import 'package:libratrack_client/src/model/elemento.dart';
import 'package:libratrack_client/src/model/paginated_response.dart';

class ElementoService with ChangeNotifier {
  final ApiClient _apiClient;
  ElementoService(this._apiClient);

  /// Busca elementos en la API con paginación y filtros.
  Future<PaginatedResponse<Elemento>> searchElementos({
    required int page,
    int size = 20,
    String? search,
    String? tipo,
    String? genero,
  }) async {
    try {
      String endpoint = 'elementos?page=$page&size=$size';
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=$search';
      }
      if (tipo != null && tipo.isNotEmpty) {
        endpoint += '&tipo=$tipo';
      }
      if (genero != null && genero.isNotEmpty) {
        endpoint += '&genero=$genero';
      }
      final data = await _apiClient.get(endpoint);
      return PaginatedResponse.fromJson(data, Elemento.fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al buscar elementos: ${e.toString()}');
    }
  }

  /// Obtiene los detalles de un solo elemento por su ID.
  // --- ¡CORREGIDO! Acepta int elementoId ---
  Future<Elemento> getElementoById(int elementoId) async {
    try {
      // Convierte a String en el último momento
      final data = await _apiClient.get('elementos/${elementoId.toString()}');
      return Elemento.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cargar el elemento: ${e.toString()}');
    }
  }
}