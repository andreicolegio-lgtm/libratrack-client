import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/resena.dart';

/// Servicio para gestionar las reseñas y valoraciones de contenido.
class ResenaService with ChangeNotifier {
  final ApiClient _apiClient;
  ResenaService(this._apiClient);

  /// Obtiene todas las reseñas de un elemento específico.
  Future<List<Resena>> getResenas(int elementoId) async {
    try {
      final dynamic response =
          await _apiClient.get('resenas/elemento/${elementoId.toString()}');

      final List<dynamic> data = response is List ? response : [];

      return data
          .map((item) => Resena.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al cargar las reseñas: $e');
    }
  }

  /// Publica una nueva reseña.
  Future<Resena> crearResena({
    required int elementoId,
    required int valoracion,
    String? textoResena,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'elementoId': elementoId,
        'valoracion': valoracion,
        'textoResena': textoResena,
      };

      // Eliminamos nulos para limpiar el payload
      body.removeWhere((key, value) => value == null);

      final dynamic data = await _apiClient.post('resenas', body);
      return Resena.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al publicar la reseña: $e');
    }
  }

  /// Elimina una reseña existente.
  Future<void> eliminarResena(int resenaId) async {
    try {
      final url = 'resenas/$resenaId';
      await _apiClient.delete(url);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al eliminar la reseña: $e');
    }
  }

  /// Actualiza una reseña existente.
  Future<Resena> actualizarResena(
    int resenaId,
    int elementoId, // <--- NUEVO PARAMETRO REQUERIDO
    int valoracion,
    String? textoResena,
  ) async {
    try {
      final url = 'resenas/$resenaId';
      final body = {
        'elementoId': elementoId, // <--- AHORA LO ENVIAMOS
        'valoracion': valoracion,
        'textoResena': textoResena,
      };
      // El cliente devuelve el JSON parseado directamente
      final dynamic responseData = await _apiClient.put(url, body);
      return Resena.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al actualizar la reseña: $e');
    }
  }
}
