// Archivo: lib/src/core/services/resena_service.dart
// (¡REFACTORIZADO! Acepta 'int' para IDs)

import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';
import 'package:libratrack_client/src/model/resena.dart';

class ResenaService with ChangeNotifier {
  final ApiClient _apiClient;
  ResenaService(this._apiClient);

  /// Obtiene todas las reseñas de un elemento.
  // --- ¡CORREGIDO! Acepta int elementoId ---
  Future<List<Resena>> getResenas(int elementoId) async {
    try {
      // Convierte a String en el último momento
      final List<dynamic> data =
          await _apiClient.get('resenas/elemento/${elementoId.toString()}');
      return data.map((item) => Resena.fromJson(item)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cargar las reseñas: ${e.toString()}');
    }
  }

  /// Crea una nueva reseña.
  // --- ¡CORREGIDO! Acepta int elementoId ---
  Future<Resena> crearResena(
      {required int elementoId,
      required int valoracion,
      String? textoResena}) async {
    try {
      final body = {
        // El ApiClient serializará el 'int' como un número (Long) en JSON
        'elementoId': elementoId, 
        'valoracion': valoracion,
        'textoResena': textoResena,
      };

      final data = await _apiClient.post('resenas', body);
      return Resena.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al publicar la reseña: ${e.toString()}');
    }
  }
}